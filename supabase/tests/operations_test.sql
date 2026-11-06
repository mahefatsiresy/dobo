-- Prep, feed, harvests, sales and customers (M7 plan Task 1): members write
-- prep and feed; only the sales flag writes harvests, sales and customers;
-- a worker writes none of them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into associations (id, name) values
  ('00000000-0000-0000-0000-0000000000a1', 'A');
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000b2', 'member@a.mg'),
  ('00000000-0000-0000-0000-0000000000b3', 'rakoto@ouvriers.dobo.invalid'),
  ('00000000-0000-0000-0000-0000000000b5', 'sales@a.mg');
insert into members (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, name, role, is_admin, is_sales, locale,
  user_id)
values
  ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e2', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Member', 'member', true, false, 'fr', '00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0000-0000000000e3', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e2', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Rakoto', 'worker', false, false, 'mg', '00000000-0000-0000-0000-0000000000b3'),
  ('00000000-0000-0000-0000-0000000000e5', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e2', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Seller', 'member', false, true, 'fr', '00000000-0000-0000-0000-0000000000b5');

-- One row of each table, with a fresh id, written by p_by.
create function pg_temp.prep(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into prep_steps (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, pond_id, step)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), false,
    '00000000-0000-0000-0000-000000000031', 'drain')
$$;
create function pg_temp.delivery(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into feed_deliveries (id, association_id, entered_by,
    created_at_device, device_id, recorded_at, is_tombstone, site_id, phase,
    weight_g, manufactured_on)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), false,
    '00000000-0000-0000-0000-0000000000c1', 'growout', 50000, now())
$$;
create function pg_temp.harvest(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into harvests (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, batch_id, pond_id, count, weight_g,
    is_final)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), false,
    '00000000-0000-0000-0000-000000000041',
    '00000000-0000-0000-0000-000000000031', 950, 240000, true)
$$;
create function pg_temp.sale(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into sales (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, harvest_id, batch_id, customer_id,
    weight_g, form)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), false,
    '00000000-0000-0000-0000-000000000091',
    '00000000-0000-0000-0000-000000000041',
    '00000000-0000-0000-0000-000000000095', 200000, 'fresh')
$$;
create function pg_temp.customer(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into customers (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, type)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), 'Marché', 'market')
$$;
grant execute on function pg_temp.prep(uuid, uuid), pg_temp.delivery(uuid, uuid),
  pg_temp.harvest(uuid, uuid), pg_temp.sale(uuid, uuid),
  pg_temp.customer(uuid, uuid) to authenticated;

set local role authenticated;

-- A member without the sales flag ---------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
select lives_ok($$ select pg_temp.prep('00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-0000000000e2') $$, 'a member records a prep step');
select lives_ok($$ select pg_temp.delivery(
  '00000000-0000-0000-0000-000000000102',
  '00000000-0000-0000-0000-0000000000e2') $$, 'a member records a delivery');
select throws_ok($$ select pg_temp.harvest(
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-0000000000e2') $$, '42501', null,
  'a member without the sales flag cannot harvest');
select throws_ok($$ select pg_temp.sale('00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-0000000000e2') $$, '42501', null,
  'a member without the sales flag cannot sell');
select throws_ok($$ select pg_temp.customer(
  '00000000-0000-0000-0000-000000000105',
  '00000000-0000-0000-0000-0000000000e2') $$, '42501', null,
  'a member without the sales flag cannot add a customer');

-- A sales member ---------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b5"}', true);
select lives_ok($$ select pg_temp.harvest(
  '00000000-0000-0000-0000-000000000091',
  '00000000-0000-0000-0000-0000000000e5') $$, 'a sales member harvests');
select lives_ok($$ select pg_temp.customer(
  '00000000-0000-0000-0000-000000000095',
  '00000000-0000-0000-0000-0000000000e5') $$, 'a sales member adds a customer');
select lives_ok($$ select pg_temp.sale('00000000-0000-0000-0000-000000000106',
  '00000000-0000-0000-0000-0000000000e5') $$, 'a sales member sells');

-- The worker -------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);
select throws_ok($$ select pg_temp.prep('00000000-0000-0000-0000-000000000111',
  '00000000-0000-0000-0000-0000000000e3') $$, '42501', null,
  'a worker cannot record a prep step');
select throws_ok($$ select pg_temp.delivery(
  '00000000-0000-0000-0000-000000000112',
  '00000000-0000-0000-0000-0000000000e3') $$, '42501', null,
  'a worker cannot record a delivery');
select throws_ok($$ select pg_temp.harvest(
  '00000000-0000-0000-0000-000000000113',
  '00000000-0000-0000-0000-0000000000e3') $$, '42501', null,
  'a worker cannot harvest');
select throws_ok($$ select pg_temp.customer(
  '00000000-0000-0000-0000-000000000114',
  '00000000-0000-0000-0000-0000000000e3') $$, '42501', null,
  'a worker cannot add a customer');
select is((select count(*)::int from harvests), 1,
  'the worker still reads the association''s harvest');

select * from finish();
rollback;
