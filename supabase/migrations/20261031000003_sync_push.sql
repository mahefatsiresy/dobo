-- The one write path for phones (SPEC §7; plan Decisions 9 and 10). Each
-- row is written on its own: a refused row comes back with its code and
-- message and the others still commit. Security invoker, so RLS decides.

-- True when this exact version of a reference row (same phone, same edit
-- time) was applied before: it is the current row or one kept in
-- reference_history. Security definer because clients can't read the
-- history.
create function reference_version_seen(
  p_table text, p_id uuid, p_device_id uuid, p_updated_at timestamptz
) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  seen boolean;
begin
  if p_table <> all (array['groups', 'members', 'sites', 'people', 'ponds',
      'batches', 'visits', 'setting_overrides']) then
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

create function sync_push(p_table text, p_rows jsonb)
returns table (id uuid, server_seq bigint, server_received_at timestamptz,
               error_code text, error_message text)
language plpgsql security invoker set search_path = public as $$
#variable_conflict use_column
declare
  reference_tables constant text[] := array['groups', 'members', 'sites',
    'people', 'ponds', 'batches', 'visits', 'setting_overrides'];
  event_tables constant text[] := array['stockings', 'transfers',
    'daily_logs', 'water_readings', 'samples', 'observations',
    'health_events', 'treatments'];
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

revoke execute on function sync_push from public, anon;
grant execute on function sync_push to authenticated;
revoke execute on function reference_version_seen from public, anon;
grant execute on function reference_version_seen to authenticated;
