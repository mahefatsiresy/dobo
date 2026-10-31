-- Synced tables (SPEC §4, §7). Each mirrors the Drift table of the same
-- name, minus the phone-only sync_state and sync_error. No foreign keys
-- between synced tables: rows from different phones arrive in any order and
-- sync must never refuse a row for that.

create table associations (
  id uuid primary key,
  name text not null,
  created_at timestamptz not null default now()
);

create table groups (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  name text not null
);

create table members (
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
  group_id uuid,
  person_id uuid,
  role text not null,
  is_admin boolean not null default false,
  is_sales boolean not null default false,
  active boolean not null default true,
  locale text not null,
  login text,
  user_id uuid unique references auth.users (id) on delete set null,
  check (role in ('worker', 'member'))
);

create table sites (
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
  location_note text
);

create table people (
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
  phone text,
  note text,
  active boolean not null
);

create table ponds (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  site_id uuid not null,
  code text not null,
  colour text not null,
  structure text not null,
  role text not null,
  water_supply text,
  length_m double precision,
  width_m double precision,
  surface_m2_override double precision,
  depth_inlet_m double precision,
  depth_outlet_m double precision,
  status text not null,
  archived boolean not null
);

create table batches (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  site_id uuid not null,
  code text not null,
  strain text,
  hatchery text,
  certificate_no text,
  monosex boolean,
  planned_harvest_on timestamptz,
  status text not null
);

create table visits (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  site_id uuid not null,
  started_at timestamptz not null,
  ended_at timestamptz,
  summary text
);

create table setting_overrides (
  id uuid primary key,
  association_id uuid not null references associations (id),
  entered_by uuid not null,
  observed_by uuid,
  created_at_device timestamptz not null,
  device_id uuid not null,
  server_received_at timestamptz,
  server_seq bigint,
  updated_at_device timestamptz not null,
  site_id uuid not null,
  key text not null,
  value double precision
);

create table stockings (
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
  avg_weight_mg integer not null,
  acclimatised boolean
);

create table transfers (
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
  from_pond_id uuid not null,
  to_pond_id uuid not null,
  count integer not null,
  avg_weight_mg integer
);

create table daily_logs (
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
  visit_id uuid,
  pond_id uuid not null,
  feed_given_g integer not null,
  feed_lot_id uuid,
  feedings integer,
  leftover text,
  ate_fast boolean not null,
  deaths integer not null,
  death_signs text not null,
  warning_signs text not null,
  water_colour text,
  note text
);

create table water_readings (
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
  visit_id uuid,
  pond_id uuid not null,
  temperature_c double precision,
  ph double precision,
  oxygen_mg_l double precision,
  colour text,
  renewed_pct integer
);

create table samples (
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
  visit_id uuid,
  batch_id uuid not null,
  pond_id uuid not null,
  fish_count integer not null,
  total_weight_g integer not null
);

create table observations (
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
  visit_id uuid,
  site_id uuid not null,
  pond_id uuid,
  category text not null,
  ok boolean,
  note text
);

create table health_events (
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
  visit_id uuid,
  pond_id uuid not null,
  signs text not null,
  suspected_issue text,
  actions text not null
);

create table treatments (
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
  visit_id uuid,
  pond_id uuid not null,
  batch_id uuid,
  product text not null,
  dose text not null,
  advised_by text
);

-- Server order. Every write in an association takes that association's
-- advisory lock before drawing its seq and holds it until commit, so seq
-- order is commit order and a pull cursor never skips a row that commits
-- late with a lower seq.
create sequence sync_seq;

create function stamp_sync() returns trigger
language plpgsql as $$
begin
  perform pg_advisory_xact_lock(hashtext(new.association_id::text));
  new.server_seq := nextval('sync_seq');
  new.server_received_at := now();
  return new;
end
$$;

-- Last-write-wins keeps every overwritten version of a reference row.
-- Server only: never synced, no client access.
create table reference_history (
  id bigserial primary key,
  table_name text not null,
  row_id uuid not null,
  row jsonb not null,
  replaced_at timestamptz not null default now()
);
create index reference_history_row on reference_history (table_name, row_id);

create function keep_history() returns trigger
language plpgsql as $$
begin
  insert into reference_history (table_name, row_id, row)
  values (tg_table_name, old.id, to_jsonb(old));
  return new;
end
$$;

-- Corrections are new rows (supersedes_id), never updates.
create function refuse_event_update() returns trigger
language plpgsql as $$
begin
  raise exception 'event rows are immutable';
end
$$;

do $$
declare
  t text;
begin
  foreach t in array array['groups', 'members', 'sites', 'people', 'ponds',
    'batches', 'visits', 'setting_overrides']
  loop
    execute format('create trigger stamp_sync before insert or update on %I
      for each row execute function stamp_sync()', t);
    execute format('create trigger keep_history before update on %I
      for each row execute function keep_history()', t);
    execute format('create index on %I (server_seq)', t);
  end loop;
  foreach t in array array['stockings', 'transfers', 'daily_logs',
    'water_readings', 'samples', 'observations', 'health_events', 'treatments']
  loop
    execute format('create trigger stamp_sync before insert on %I
      for each row execute function stamp_sync()', t);
    execute format('create trigger refuse_event_update before update on %I
      for each row execute function refuse_event_update()', t);
    execute format('create index on %I (server_seq)', t);
  end loop;
end
$$;
