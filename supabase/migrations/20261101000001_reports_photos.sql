-- M6: visit reports and photos (plan Task 3). Both are append-only event
-- tables; members write them, everyone in the association reads them.
-- Photo files go to the private `photos` bucket at
-- <association_id>/<photo_key>.jpg, up to a per-association count.

create table visit_reports (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  recorded_at timestamptz not null,
  supersedes_id uuid,
  is_tombstone boolean not null,
  visit_id uuid not null,
  site_id uuid not null,
  period_from timestamptz not null,
  period_to timestamptz not null,
  content text not null
);

create table photos (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  recorded_at timestamptz not null,
  supersedes_id uuid,
  is_tombstone boolean not null,
  owner_kind text not null,
  owner_id uuid not null,
  photo_key uuid not null,
  upload boolean not null,
  bytes integer not null
);

do $$
declare
  t text;
begin
  foreach t in array array['visit_reports', 'photos'] loop
    execute format('create trigger stamp_sync before insert on %I
      for each row execute function stamp_sync()', t);
    execute format('create trigger refuse_event_update before update on %I
      for each row execute function refuse_event_update()', t);
    execute format('create index on %I (server_seq)', t);
    execute format('alter table %I enable row level security', t);
    execute format('create policy read_own on %I for select
      using (association_id = my_association())', t);
    execute format('create policy write_own on %I for insert
      with check (association_id = my_association() and is_member())', t);
  end loop;
end
$$;

create or replace function sync_push(p_table text, p_rows jsonb)
returns table (id uuid, server_seq bigint, server_received_at timestamptz,
               error_code text, error_message text)
language plpgsql security invoker set search_path = public as $$
#variable_conflict use_column
declare
  reference_tables constant text[] := array['groups', 'members', 'sites',
    'people', 'ponds', 'batches', 'visits', 'setting_overrides'];
  event_tables constant text[] := array['stockings', 'transfers',
    'daily_logs', 'water_readings', 'samples', 'observations',
    'health_events', 'treatments', 'visit_reports', 'photos'];
  is_event boolean;
  columns text;
  r jsonb;
  v_id uuid;
  v_seq bigint;
  v_at timestamptz;
  v_exists boolean;
  n integer;
begin
  if p_table = any (event_tables) then
    is_event := true;
  elsif p_table = any (reference_tables) then
    is_event := false;
  else
    raise exception 'unknown_table';
  end if;

  -- Columns a phone may set: never the id, never the server-only user_id.
  select string_agg(quote_ident(c.column_name), ', ')
  into columns
  from information_schema.columns c
  where c.table_schema = 'public' and c.table_name = p_table
    and c.column_name not in ('id', 'user_id');

  for r in select * from jsonb_array_elements(p_rows) loop
    v_id := (r ->> 'id')::uuid;
    begin
      if is_event then
        execute format('insert into %I select * from
          jsonb_populate_record(null::%I, $1) on conflict (id) do nothing',
          p_table, p_table) using r;
      elsif not reference_version_seen(p_table, v_id,
          (r ->> 'device_id')::uuid, (r ->> 'updated_at_device')::timestamptz)
      then
        execute format('select exists (select 1 from %I where id = $1)',
          p_table) into v_exists using v_id;
        if v_exists then
          -- UPDATE, not an upsert: RLS checks the INSERT policy even on
          -- the ON CONFLICT path, which would refuse a member's pond change.
          execute format('update %I t set (%s) = (select %s from
            jsonb_populate_record(null::%I, $1)) where t.id = $2',
            p_table, columns, columns, p_table) using r, v_id;
          get diagnostics n = row_count;
          if n = 0 then
            raise exception 'not_allowed' using errcode = '42501';
          end if;
        else
          execute format('insert into %I select * from
            jsonb_populate_record(null::%I, $1)', p_table, p_table) using r;
        end if;
      end if;

      execute format('select server_seq, server_received_at from %I
        where id = $1', p_table) into v_seq, v_at using v_id;
      if v_seq is null then
        raise exception 'not_visible' using errcode = '42501';
      end if;
      return query select v_id, v_seq, v_at, null::text, null::text;
    exception when others then
      return query select v_id, null::bigint, null::timestamptz,
        sqlstate::text, sqlerrm;
    end;
  end loop;
end
$$;


-- Photo files ------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

-- How many photos an association may store: an admin's `photoUploadCap`
-- setting, else 300 (plan Decision 11).
create function photo_cap_left() returns boolean
language sql stable security definer set search_path = public as $$
  select (select count(*) from storage.objects
          where bucket_id = 'photos'
            and name like my_association()::text || '/%')
       < coalesce((select max(value) from setting_overrides
                   where association_id = my_association()
                     and key = 'photoUploadCap'), 300)
$$;

create policy photos_read on storage.objects for select to authenticated
  using (bucket_id = 'photos'
         and name like my_association()::text || '/%');

create policy photos_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'photos'
              and name like my_association()::text || '/%'
              and is_member()
              and photo_cap_left());
