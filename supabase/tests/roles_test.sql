-- Roles and row-level security (SPEC §3, plan Decision 6). Founding is
-- tested in founding_test.sql.
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

-- Association A: admin (b1), member (b2), worker (b3). Association B: b4.
insert into associations (id, name) values
  ('00000000-0000-0000-0000-0000000000a1', 'A'),
  ('00000000-0000-0000-0000-0000000000a2', 'B');
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000b1', 'admin@a.mg'),
  ('00000000-0000-0000-0000-0000000000b2', 'member@a.mg'),
  ('00000000-0000-0000-0000-0000000000b3', 'rakoto@ouvriers.dobo.invalid'),
  ('00000000-0000-0000-0000-0000000000b4', 'other@b.mg');
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
   now(), 'Rakoto', 'worker', false, 'mg', '00000000-0000-0000-0000-0000000000b3'),
  ('00000000-0000-0000-0000-0000000000e4', '00000000-0000-0000-0000-0000000000a2',
   '00000000-0000-0000-0000-0000000000e4', now(), '00000000-0000-0000-0000-0000000000d4',
   now(), 'Other', 'member', true, 'fr', '00000000-0000-0000-0000-0000000000b4');
insert into ponds (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, site_id, code, colour, structure, role,
  status, archived)
values ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000e1', now(), '00000000-0000-0000-0000-0000000000d1',
  now(), '00000000-0000-0000-0000-0000000000c1', 'E1', 'blue', 'earth', 'growout',
  'empty', false);

-- A new pond, as sync_push inserts it. (Changes go through UPDATE: RLS
-- checks the INSERT policy even on the ON CONFLICT DO UPDATE path.)
create function pg_temp.insert_pond(p_id uuid, p_status text) returns text
language sql as $$
  select format($q$
    insert into ponds (id, association_id, entered_by, created_at_device,
      device_id, updated_at_device, site_id, code, colour, structure, role,
      status, archived)
    values (%L, '00000000-0000-0000-0000-0000000000a1',
      '00000000-0000-0000-0000-0000000000e1', now(),
      '00000000-0000-0000-0000-0000000000d1', now(),
      '00000000-0000-0000-0000-0000000000c1', 'E2', 'green', 'earth',
      'growout', %L, false)
  $q$, p_id, p_status)
$$;
grant execute on function pg_temp.insert_pond(uuid, text) to authenticated;

-- The worker -------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);

select lives_ok($$
  insert into daily_logs (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, pond_id, feed_given_g, ate_fast,
    deaths, death_signs, warning_signs)
  values ('00000000-0000-0000-0000-0000000000f1',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e3',
    now(), '00000000-0000-0000-0000-0000000000d3', now(), false,
    '00000000-0000-0000-0000-000000000001', 600, false, 3, '', '')
$$, 'the worker can log a day');
select throws_ok($$
  insert into water_readings (id, association_id, entered_by,
    created_at_device, device_id, recorded_at, is_tombstone, pond_id, ph)
  values ('00000000-0000-0000-0000-0000000000f2',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e3',
    now(), '00000000-0000-0000-0000-0000000000d3', now(), false,
    '00000000-0000-0000-0000-000000000001', 7.2)
$$, '42501', null, 'the worker cannot record a water reading');
update ponds set status = 'isolated'
where id = '00000000-0000-0000-0000-000000000001';
select is((select status from ponds
           where id = '00000000-0000-0000-0000-000000000001'),
  'empty', 'the worker cannot change a pond');

-- The member -------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);

select lives_ok($$
  insert into samples (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, batch_id, pond_id, fish_count,
    total_weight_g)
  values ('00000000-0000-0000-0000-0000000000f3',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e2',
    now(), '00000000-0000-0000-0000-0000000000d2', now(), false,
    '00000000-0000-0000-0000-0000000000f9', '00000000-0000-0000-0000-000000000001',
    30, 600)
$$, 'a member can record a sample');
select lives_ok($$
  update ponds set status = 'isolated'
  where id = '00000000-0000-0000-0000-000000000001'
$$, 'a member can change a pond''s status');
select is((select status from ponds
           where id = '00000000-0000-0000-0000-000000000001'),
  'isolated', 'the status change is stored');
select throws_ok(
  pg_temp.insert_pond('00000000-0000-0000-0000-000000000002', 'empty'),
  '42501', null, 'a member cannot add a pond');
select throws_ok($$
  insert into people (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, active)
  values ('00000000-0000-0000-0000-0000000000f4',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e2',
    now(), '00000000-0000-0000-0000-0000000000d2', now(), 'Rabe', true)
$$, '42501', null, 'a member cannot add a person');

-- The member's own row: language yes, flags no.
select lives_ok($$
  update members set locale = 'mg'
  where id = '00000000-0000-0000-0000-0000000000e2'
$$, 'a member can change their own language');
select is((select locale from members
           where id = '00000000-0000-0000-0000-0000000000e2'),
  'mg', 'the language change is stored');
-- Anything else a member sends for their own row is ignored, not refused:
-- a refused row would stay stuck on their phone.
update members set is_admin = true
where id = '00000000-0000-0000-0000-0000000000e2';
select is((select is_admin from members
           where id = '00000000-0000-0000-0000-0000000000e2'),
  false, 'a member cannot make themselves admin');

-- The admin --------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b1"}', true);

select lives_ok(
  pg_temp.insert_pond('00000000-0000-0000-0000-000000000002', 'empty'),
  'the admin can add a pond');
select lives_ok($$
  insert into groups (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name)
  values ('00000000-0000-0000-0000-0000000000f5',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e1',
    now(), '00000000-0000-0000-0000-0000000000d1', now(), 'Branche Rabe')
$$, 'the admin can add a group');
select lives_ok($$
  insert into setting_overrides (id, association_id, entered_by,
    created_at_device, device_id, updated_at_device, site_id, key, value)
  values ('00000000-0000-0000-0000-0000000000f6',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e1',
    now(), '00000000-0000-0000-0000-0000000000d1', now(),
    '00000000-0000-0000-0000-0000000000c1', 'minOxygenMgL', 4)
$$, 'the admin can override a setting');
delete from ponds;
select is((select count(*)::int from ponds), 2, 'nobody can delete, not even the admin');
select throws_ok($$
  update members set is_admin = false
  where id = '00000000-0000-0000-0000-0000000000e1'
$$, 'P0001', 'last_admin', 'the last admin cannot step down');
select throws_ok($$
  update members set role = 'worker'
  where id = '00000000-0000-0000-0000-0000000000e1'
$$, 'P0001', 'last_admin', 'the last admin cannot become a worker');

-- The admin moves the member to sales; the member's phone, not yet
-- synced, then sends its language change with the old flags.
update members set is_sales = true
where id = '00000000-0000-0000-0000-0000000000e2';
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
update members set locale = 'fr', is_sales = false
where id = '00000000-0000-0000-0000-0000000000e2';
select is((select (locale, is_sales)::text from members
           where id = '00000000-0000-0000-0000-0000000000e2'),
  '(fr,t)', 'a stale language change keeps the admin''s edit');
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b1"}', true);
select is((select count(*)::int from members
           where id = '00000000-0000-0000-0000-0000000000e2'), 1,
  'the admin still sees the member');
select lives_ok($$
  update members set active = false
  where id = '00000000-0000-0000-0000-0000000000e2'
$$, 'the admin can deactivate a member');

-- A deactivated member sees nothing.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
select is((select count(*)::int from ponds), 0, 'a deactivated member sees no pond');

-- Another association sees nothing of A.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b4"}', true);
select is((select count(*)::int from ponds), 0, 'another association sees no pond of A');
select is((select count(*)::int from daily_logs), 0, 'another association sees no log of A');

reset role;
select * from finish();
rollback;
