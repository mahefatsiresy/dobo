-- M7: pond preparation, feed lots, harvests, sales and customers (plan
-- Task 1). Members record preparation and feed; harvests, sales and
-- customers need the sales flag (plan Decision 12).

create table prep_steps (
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
  pond_id uuid not null,
  step text not null,
  product text,
  dose_g integer
);

-- A delivery is a feed lot; daily_logs.feed_lot_id points here.
create table feed_deliveries (
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
  site_id uuid not null,
  phase text not null,
  pellet_mm double precision,
  protein_pct double precision,
  weight_g integer not null,
  manufactured_on timestamptz not null,
  supplier text,
  label text
);

create table feed_discards (
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
  lot_id uuid not null,
  weight_g integer not null,
  reason text not null
);

create table harvests (
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
  batch_id uuid not null,
  pond_id uuid not null,
  count integer not null,
  weight_g integer not null,
  is_final boolean not null
);

-- No price in v1 (CLAUDE.md §6).
create table sales (
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
  harvest_id uuid not null,
  batch_id uuid not null,
  customer_id uuid not null,
  weight_g integer not null,
  form text not null,
  delivery_note text
);

create table customers (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  name text not null,
  type text not null,
  contact text,
  archived boolean not null default false
);

create function is_sales() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members
                 where user_id = auth.uid() and active and role = 'member'
                   and is_sales)
$$;

do $$
declare
  t text;
begin
  foreach t in array array['prep_steps', 'feed_deliveries', 'feed_discards',
    'harvests', 'sales'] loop
    execute format('create trigger stamp_sync before insert on %I
      for each row execute function stamp_sync()', t);
    execute format('create trigger refuse_event_update before update on %I
      for each row execute function refuse_event_update()', t);
  end loop;
  execute 'create trigger stamp_sync before insert or update on customers
    for each row execute function stamp_sync()';
  execute 'create trigger keep_history before update on customers
    for each row execute function keep_history()';

  foreach t in array array['prep_steps', 'feed_deliveries', 'feed_discards',
    'harvests', 'sales', 'customers'] loop
    execute format('create index on %I (server_seq)', t);
    execute format('alter table %I enable row level security', t);
    execute format('create policy read_own on %I for select
      using (association_id = my_association())', t);
  end loop;

  foreach t in array array['prep_steps', 'feed_deliveries', 'feed_discards']
  loop
    execute format('create policy write_own on %I for insert
      with check (association_id = my_association() and is_member())', t);
  end loop;

  foreach t in array array['harvests', 'sales', 'customers'] loop
    execute format('create policy sales_insert on %I for insert
      with check (association_id = my_association() and is_sales())', t);
  end loop;
  execute 'create policy sales_update on customers for update
    using (association_id = my_association() and is_sales())
    with check (association_id = my_association() and is_sales())';
end
$$;

-- reference_version_seen keeps its own list of reference tables.
create or replace function reference_version_seen(
  p_table text, p_id uuid, p_device_id uuid, p_updated_at timestamptz
) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  seen boolean;
begin
  if p_table <> all (array['groups', 'members', 'sites', 'people', 'ponds',
      'batches', 'visits', 'setting_overrides', 'customers']) then
    raise exception 'unknown_table';
  end if;
  execute format('select exists (select 1 from %I where id = $1
    and device_id = $2 and updated_at_device = $3)', p_table)
    into seen using p_id, p_device_id, p_updated_at;
  return seen or exists (
    select 1 from reference_history
    where table_name = p_table and row_id = p_id
      and (row ->> 'device_id')::uuid = p_device_id
      and (row ->> 'updated_at_device')::timestamptz = p_updated_at);
end
$$;

create or replace function sync_push(p_table text, p_rows jsonb)
returns table (id uuid, server_seq bigint, server_received_at timestamptz,
               error_code text, error_message text)
language plpgsql security invoker set search_path = public as $$
#variable_conflict use_column
declare
  reference_tables constant text[] := array['groups', 'members', 'sites',
    'people', 'ponds', 'batches', 'visits', 'setting_overrides', 'customers'];
  event_tables constant text[] := array['stockings', 'transfers',
    'daily_logs', 'water_readings', 'samples', 'observations',
    'health_events', 'treatments', 'visit_reports', 'photos', 'prep_steps',
    'feed_deliveries', 'feed_discards', 'harvests', 'sales'];
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
