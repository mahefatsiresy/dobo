-- Synced tables: server sequence, history of overwritten reference rows,
-- immutable events, and every column the phones send (Task 1).
begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

create function pg_temp.missing_columns(t text, wanted text[]) returns text[]
language sql as $$
  select coalesce(array_agg(c order by c), '{}')
  from unnest(wanted) c
  where c not in (
    select column_name from information_schema.columns
    where table_schema = 'public' and table_name = t)
$$;

insert into associations (id, name)
values ('00000000-0000-0000-0000-0000000000a1', 'Famille');

insert into ponds (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, site_id, code, colour, structure, role,
  status, archived)
values
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000b1', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), '00000000-0000-0000-0000-0000000000c1', 'E1', 'blue', 'earth', 'growout',
   'empty', false),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000b1', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), '00000000-0000-0000-0000-0000000000c1', 'E2', 'green', 'earth', 'growout',
   'empty', false);

select ok(
  (select server_seq from ponds where code = 'E2')
    > (select server_seq from ponds where code = 'E1'),
  'later insert gets a higher server_seq');
select isnt(
  (select server_received_at from ponds where code = 'E1'), null,
  'server_received_at is stamped');
select ok(
  exists(select 1 from pg_locks
         where locktype = 'advisory' and pid = pg_backend_pid()),
  'a write holds the association''s advisory lock until commit');

create temp table seq_before as
  select server_seq from ponds where code = 'E1';
update ponds set code = 'E9' where code = 'E1';
select ok(
  (select server_seq from ponds where code = 'E9')
    > (select server_seq from seq_before),
  'an update gets a new server_seq');
select is(
  (select row ->> 'code' from reference_history
   where table_name = 'ponds'
     and row_id = '00000000-0000-0000-0000-000000000001'),
  'E1',
  'the overwritten version is kept in reference_history');

insert into daily_logs (id, association_id, entered_by, created_at_device,
  device_id, recorded_at, is_tombstone, pond_id, feed_given_g, ate_fast,
  deaths, death_signs, warning_signs)
values ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000b1', now(), '00000000-0000-0000-0000-0000000000d1',
  now(), false, '00000000-0000-0000-0000-000000000001', 600, false, 3, '', '');
select throws_ok(
  $$update daily_logs set deaths = 9$$,
  'P0001', 'event rows are immutable',
  'event rows cannot be updated');

select is(pg_temp.missing_columns('sites', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'name', 'location_note']), '{}'::text[], 'sites has every column');
select is(pg_temp.missing_columns('people', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'name', 'phone', 'note', 'active']), '{}'::text[], 'people has every column');
select is(pg_temp.missing_columns('ponds', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'site_id', 'code', 'colour', 'structure', 'role', 'water_supply', 'length_m', 'width_m', 'surface_m2_override', 'depth_inlet_m', 'depth_outlet_m', 'status', 'archived']), '{}'::text[], 'ponds has every column');
select is(pg_temp.missing_columns('batches', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'site_id', 'code', 'strain', 'hatchery', 'certificate_no', 'monosex', 'planned_harvest_on', 'status']), '{}'::text[], 'batches has every column');
select is(pg_temp.missing_columns('stockings', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'batch_id', 'pond_id', 'count', 'avg_weight_mg', 'acclimatised']), '{}'::text[], 'stockings has every column');
select is(pg_temp.missing_columns('transfers', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'batch_id', 'from_pond_id', 'to_pond_id', 'count', 'avg_weight_mg']), '{}'::text[], 'transfers has every column');
select is(pg_temp.missing_columns('daily_logs', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'pond_id', 'feed_given_g', 'feed_lot_id', 'feedings', 'leftover', 'ate_fast', 'deaths', 'death_signs', 'warning_signs', 'water_colour', 'note']), '{}'::text[], 'daily_logs has every column');
select is(pg_temp.missing_columns('water_readings', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'pond_id', 'temperature_c', 'ph', 'oxygen_mg_l', 'colour', 'renewed_pct']), '{}'::text[], 'water_readings has every column');
select is(pg_temp.missing_columns('samples', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'batch_id', 'pond_id', 'fish_count', 'total_weight_g']), '{}'::text[], 'samples has every column');
select is(pg_temp.missing_columns('observations', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'site_id', 'pond_id', 'category', 'ok', 'note']), '{}'::text[], 'observations has every column');
select is(pg_temp.missing_columns('health_events', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'pond_id', 'signs', 'suspected_issue', 'actions']), '{}'::text[], 'health_events has every column');
select is(pg_temp.missing_columns('treatments', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'recorded_at', 'supersedes_id', 'is_tombstone', 'visit_id', 'pond_id', 'batch_id', 'product', 'dose', 'advised_by']), '{}'::text[], 'treatments has every column');
select is(pg_temp.missing_columns('visits', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'site_id', 'started_at', 'ended_at', 'summary']), '{}'::text[], 'visits has every column');
select is(pg_temp.missing_columns('groups', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'name']), '{}'::text[], 'groups has every column');
select is(pg_temp.missing_columns('members', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'name', 'group_id', 'person_id', 'role', 'is_admin', 'is_sales', 'active', 'locale', 'login', 'user_id']), '{}'::text[], 'members has every column');
select is(pg_temp.missing_columns('setting_overrides', array['id', 'association_id', 'entered_by', 'observed_by', 'created_at_device', 'device_id', 'server_received_at', 'server_seq', 'updated_at_device', 'site_id', 'key', 'value']), '{}'::text[], 'setting_overrides has every column');

select * from finish();
rollback;
