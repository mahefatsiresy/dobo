-- Visit reports and photos (M6 plan Task 3): who may write them, and the
-- per-association photo cap in Storage.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into associations (id, name) values
  ('00000000-0000-0000-0000-0000000000a1', 'A'),
  ('00000000-0000-0000-0000-0000000000a2', 'B');
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000b2', 'member@a.mg'),
  ('00000000-0000-0000-0000-0000000000b3', 'rakoto@ouvriers.dobo.invalid'),
  ('00000000-0000-0000-0000-0000000000b4', 'other@b.mg');
insert into members (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, name, role, is_admin, locale, user_id)
values
  ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e2', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Member', 'member', true, 'fr', '00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0000-0000000000e3', '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000e2', now(), '00000000-0000-0000-0000-0000000000d1',
   now(), 'Rakoto', 'worker', false, 'mg', '00000000-0000-0000-0000-0000000000b3'),
  ('00000000-0000-0000-0000-0000000000e4', '00000000-0000-0000-0000-0000000000a2',
   '00000000-0000-0000-0000-0000000000e4', now(), '00000000-0000-0000-0000-0000000000d4',
   now(), 'Other', 'member', true, 'fr', '00000000-0000-0000-0000-0000000000b4');
-- A cap of 2 photos for association A.
insert into setting_overrides (id, association_id, entered_by,
  created_at_device, device_id, updated_at_device, site_id, key, value)
values ('00000000-0000-0000-0000-000000000051',
  '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e2',
  now(), '00000000-0000-0000-0000-0000000000d1', now(),
  '00000000-0000-0000-0000-0000000000c1', 'photoUploadCap', 2);

create function pg_temp.report(p_id uuid, p_by uuid) returns void
language sql as $$
  insert into visit_reports (id, association_id, entered_by,
    created_at_device, device_id, recorded_at, is_tombstone, visit_id,
    site_id, period_from, period_to, content)
  values (p_id, '00000000-0000-0000-0000-0000000000a1', p_by, now(),
    '00000000-0000-0000-0000-0000000000d1', now(), false,
    '00000000-0000-0000-0000-000000000061',
    '00000000-0000-0000-0000-0000000000c1', now(), now(), '{"format":1}')
$$;
grant execute on function pg_temp.report(uuid, uuid) to authenticated;

create function pg_temp.object(p_name text) returns void
language sql as $$
  insert into storage.objects (bucket_id, name, owner_id)
  values ('photos', p_name, auth.uid()::text)
$$;
grant execute on function pg_temp.object(text) to authenticated;

select is((select public from storage.buckets where id = 'photos'), false,
  'the photos bucket is private');

-- The member -------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
select lives_ok($$
  select pg_temp.report('00000000-0000-0000-0000-000000000071',
    '00000000-0000-0000-0000-0000000000e2')
$$, 'a member publishes a report');
select lives_ok($$
  insert into photos (id, association_id, entered_by, created_at_device,
    device_id, recorded_at, is_tombstone, owner_kind, owner_id, photo_key,
    upload, bytes)
  values ('00000000-0000-0000-0000-000000000081',
    '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000e2',
    now(), '00000000-0000-0000-0000-0000000000d1', now(), false, 'visit',
    '00000000-0000-0000-0000-000000000061', '00000000-0000-0000-0000-000000000081',
    true, 120000)
$$, 'a member adds a photo row');
select lives_ok($$ select pg_temp.object(
  '00000000-0000-0000-0000-0000000000a1/k1.jpg') $$, 'first photo stored');
select lives_ok($$ select pg_temp.object(
  '00000000-0000-0000-0000-0000000000a1/k2.jpg') $$, 'second photo stored');
select throws_ok($$ select pg_temp.object(
  '00000000-0000-0000-0000-0000000000a1/k3.jpg') $$, '42501', null,
  'a third photo is past the cap of 2');
select throws_ok($$ select pg_temp.object(
  '00000000-0000-0000-0000-0000000000a2/k4.jpg') $$, '42501', null,
  'a photo cannot go in another association''s folder');

-- The worker -------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);
select throws_ok($$
  select pg_temp.report('00000000-0000-0000-0000-000000000072',
    '00000000-0000-0000-0000-0000000000e3')
$$, '42501', null, 'a worker cannot publish a report');

-- Another association ----------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b4"}', true);
select is((select count(*)::int from storage.objects
  where bucket_id = 'photos'), 0, 'another association sees no photo');

select * from finish();
rollback;
