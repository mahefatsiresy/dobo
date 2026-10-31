-- sync_push: per-row results, idempotent retries, last-write-wins without
-- a retried old version winning (Task 3; plan Decision 9).
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into associations (id, name)
values ('00000000-0000-0000-0000-0000000000a1', 'A');
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000b1', 'admin@a.mg'),
  ('00000000-0000-0000-0000-0000000000b2', 'member@a.mg'),
  ('00000000-0000-0000-0000-0000000000b3', 'rakoto@ouvriers.dobo.invalid');
insert into members (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, name, role, is_admin, locale, user_id)
values
  ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e1', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Admin', 'member', true, 'fr', '00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e1', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Member', 'member', false, 'fr', '00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0000-0000000000e3', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e1', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Rakoto', 'worker', false, 'mg', '00000000-0000-0000-0000-0000000000b3');

-- Rows as a phone sends them (no sync_state, sync_error).
create function pg_temp.log_row(p_id text) returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', p_id, 'association_id', '00000000-0000-0000-0000-0000000000a1',
    'entered_by', '00000000-0000-0000-0000-0000000000e3',
    'observed_by', null, 'created_at_device', '2026-03-01T06:00:00.000Z',
    'device_id', '00000000-0000-0000-0000-0000000000d3',
    'server_received_at', null, 'server_seq', 999999,
    'recorded_at', '2026-03-01T09:00:00.000Z', 'supersedes_id', null,
    'is_tombstone', false, 'visit_id', null,
    'pond_id', '00000000-0000-0000-0000-000000000001', 'feed_given_g', 600,
    'feed_lot_id', null, 'feedings', 3, 'leftover', 'some', 'ate_fast', false,
    'deaths', 3, 'death_signs', '', 'warning_signs', 'rubbing',
    'water_colour', null, 'note', null)
$$;
create function pg_temp.reading_row(p_id text) returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', p_id, 'association_id', '00000000-0000-0000-0000-0000000000a1',
    'entered_by', '00000000-0000-0000-0000-0000000000e3',
    'created_at_device', '2026-03-01T06:00:00.000Z',
    'device_id', '00000000-0000-0000-0000-0000000000d3',
    'recorded_at', '2026-03-01T09:00:00.000Z', 'is_tombstone', false,
    'pond_id', '00000000-0000-0000-0000-000000000001', 'ph', 7.2)
$$;
create function pg_temp.pond_row(p_id text, p_device text, p_at text,
  p_code text, p_status text) returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', p_id, 'association_id', '00000000-0000-0000-0000-0000000000a1',
    'entered_by', '00000000-0000-0000-0000-0000000000e1',
    'created_at_device', '2026-03-01T06:00:00.000Z', 'device_id', p_device,
    'updated_at_device', p_at,
    'site_id', '00000000-0000-0000-0000-0000000000c1', 'code', p_code,
    'colour', 'blue', 'structure', 'earth', 'role', 'growout',
    'status', p_status, 'archived', false)
$$;
create temp table first_push (id uuid, server_seq bigint);
grant all on first_push to authenticated;
grant execute on all functions in schema pg_temp to authenticated;

-- The worker: events are accepted once, refused rows don't sink the batch.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);

insert into first_push
select id, server_seq from sync_push('daily_logs', jsonb_build_array(
  pg_temp.log_row('00000000-0000-0000-0000-0000000000f1'),
  pg_temp.log_row('00000000-0000-0000-0000-0000000000f2')))
where error_code is null and server_seq is not null;
select is((select count(*)::int from first_push), 2,
  'two daily logs pushed, two accepted with a seq');
select is(
  array(select server_seq from sync_push('daily_logs', jsonb_build_array(
    pg_temp.log_row('00000000-0000-0000-0000-0000000000f1'),
    pg_temp.log_row('00000000-0000-0000-0000-0000000000f2'))) order by id),
  array(select server_seq from first_push order by id),
  'a retry gets the stored seqs back');
select is((select count(*)::int from daily_logs), 2, 'a retry adds no row');

create temp table mixed as
select * from sync_push('daily_logs',
  jsonb_build_array(pg_temp.log_row('00000000-0000-0000-0000-0000000000f3')))
union all
select * from sync_push('water_readings',
  jsonb_build_array(pg_temp.reading_row('00000000-0000-0000-0000-0000000000f4')));
select is((select error_code from mixed
           where id = '00000000-0000-0000-0000-0000000000f3'), null,
  'the worker''s daily log is accepted');
select is((select error_code from mixed
           where id = '00000000-0000-0000-0000-0000000000f4'), '42501',
  'the worker''s water reading is refused with its code');
select is((select count(*)::int from daily_logs), 3, 'the accepted log is stored');

-- The admin: last write wins, a retried old version doesn't.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b1"}', true);
select is((select error_code from sync_push('ponds', jsonb_build_array(
  pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000da', '2026-03-01T07:00:00.000Z',
    'E1', 'empty')))), null, 'device A adds the pond');
select is((select error_code from sync_push('ponds', jsonb_build_array(
  pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000db', '2026-03-01T08:00:00.000Z',
    'E1b', 'empty')))), null, 'device B renames it');
create temp table seq_b as select server_seq from ponds;
select is(
  (select server_seq from sync_push('ponds', jsonb_build_array(
    pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000da', '2026-03-01T07:00:00.000Z',
      'E1', 'empty')))),
  (select server_seq from seq_b),
  'device A''s retry is acknowledged with the current seq');
select is((select code from ponds), 'E1b', 'the retried old version does not win');
select is(
  (select server_seq from sync_push('ponds', jsonb_build_array(
    pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-0000000000db', '2026-03-01T08:00:00.000Z',
      'E1b', 'empty')))),
  (select server_seq from seq_b),
  'a retry of the current version changes nothing');

-- A member changes a pond they may not add; a worker may do neither.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
select is((select error_code from sync_push('ponds', jsonb_build_array(
  pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000dc', '2026-03-02T08:00:00.000Z',
    'E1b', 'isolated')))), null, 'a member''s pond change is accepted');
select is((select status from ponds), 'isolated', 'the change is stored');
select is((select error_code from sync_push('ponds', jsonb_build_array(
  pg_temp.pond_row('00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-0000000000dc', '2026-03-02T08:00:00.000Z',
    'E2', 'empty')))), '42501', 'a member''s new pond is refused');

select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);
select is((select error_code from sync_push('ponds', jsonb_build_array(
  pg_temp.pond_row('00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-0000000000d3', '2026-03-03T08:00:00.000Z',
    'E1b', 'empty')))), '42501', 'a worker''s pond change is refused');
select is((select status from ponds), 'isolated', 'the refused change is not stored');

select throws_ok($$select * from sync_push('auth.users', '[]')$$,
  'P0001', 'unknown_table', 'only synced tables can be pushed');

reset role;
select * from finish();
rollback;
