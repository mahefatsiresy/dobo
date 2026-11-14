-- Founding an association on the server (SPEC F16; M9 plan Task 1), and
-- renaming it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000b1', 'founder@a.mg'),
  ('00000000-0000-0000-0000-0000000000b2', 'late@b.mg'),
  ('00000000-0000-0000-0000-0000000000b3', 'member@a.mg');

-- found_association(code hash, user, email, association, group, site,
-- member, person, ...) as the edge function calls it.
set local role service_role;
select lives_ok($$
  select found_association('hash-1', '00000000-0000-0000-0000-0000000000b1',
    'founder@a.mg',
    '00000000-0000-0000-0000-0000000000a1', 'Famille A',
    '00000000-0000-0000-0000-0000000000f1', 'Branche 1',
    '00000000-0000-0000-0000-0000000000c1', 'Ambohidratrimo', 'Près du lac',
    '00000000-0000-0000-0000-0000000000e1',
    '00000000-0000-0000-0000-000000000aa1'::uuid, 'Founder', 'fr',
    '00000000-0000-0000-0000-0000000000d1')
$$, 'the service role founds an association');
reset role;

select is((select count(*)::int from associations
           where id = '00000000-0000-0000-0000-0000000000a1'), 1, 'one association');
select is((select name from groups
           where id = '00000000-0000-0000-0000-0000000000f1'), 'Branche 1', 'its first group');
select is((select location_note from sites
           where id = '00000000-0000-0000-0000-0000000000c1'), 'Près du lac', 'its site');
select is((select name from people
           where id = '00000000-0000-0000-0000-000000000aa1'::uuid), 'Founder',
  'the founder''s person');
select ok((select is_admin and active from members
           where id = '00000000-0000-0000-0000-0000000000e1'), 'the founder is an active admin');
select is((select person_id from members
           where id = '00000000-0000-0000-0000-0000000000e1'),
  '00000000-0000-0000-0000-000000000aa1'::uuid, 'linked to their person');
select is((select user_id from members
           where id = '00000000-0000-0000-0000-0000000000e1'),
  '00000000-0000-0000-0000-0000000000b1'::uuid, 'linked to their login');
select is((select login from members
           where id = '00000000-0000-0000-0000-0000000000e1'), 'founder@a.mg', 'with their email');
select ok((select bool_and(server_seq is not null) from (
    select server_seq from groups where association_id = '00000000-0000-0000-0000-0000000000a1'
    union all select server_seq from sites where association_id = '00000000-0000-0000-0000-0000000000a1'
    union all select server_seq from people where association_id = '00000000-0000-0000-0000-0000000000a1'
    union all select server_seq from members where association_id = '00000000-0000-0000-0000-0000000000a1'
  ) s), 'every synced row has a server_seq, so phones pull it');

set local role service_role;
select throws_ok($$
  select found_association('hash-1', '00000000-0000-0000-0000-0000000000b2',
    'late@b.mg',
    '00000000-0000-0000-0000-0000000000a2', 'Famille B',
    '00000000-0000-0000-0000-0000000000f2', 'Branche 1',
    '00000000-0000-0000-0000-0000000000c2', 'Site B', null,
    '00000000-0000-0000-0000-0000000000e2',
    '00000000-0000-0000-0000-000000000aa2'::uuid, 'Late', 'fr',
    '00000000-0000-0000-0000-0000000000d2')
$$, 'P0001', 'code_spent', 'a spent code founds nothing');
reset role;
select is((select count(*)::int from associations
           where id = '00000000-0000-0000-0000-0000000000a2'), 0, 'no second association');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2"}', true);
select throws_ok($$
  select found_association('hash-2', '00000000-0000-0000-0000-0000000000b2',
    'late@b.mg',
    '00000000-0000-0000-0000-0000000000a2', 'Famille B',
    '00000000-0000-0000-0000-0000000000f2', 'Branche 1',
    '00000000-0000-0000-0000-0000000000c2', 'Site B', null,
    '00000000-0000-0000-0000-0000000000e2',
    '00000000-0000-0000-0000-000000000aa2'::uuid, 'Late', 'fr',
    '00000000-0000-0000-0000-0000000000d2')
$$, '42501', null, 'a signed-in account cannot found');
reset role;
set local role anon;
select throws_ok($$
  select found_association('hash-2', '00000000-0000-0000-0000-0000000000b2',
    'late@b.mg',
    '00000000-0000-0000-0000-0000000000a2', 'Famille B',
    '00000000-0000-0000-0000-0000000000f2', 'Branche 1',
    '00000000-0000-0000-0000-0000000000c2', 'Site B', null,
    '00000000-0000-0000-0000-0000000000e2',
    '00000000-0000-0000-0000-000000000aa2'::uuid, 'Late', 'fr',
    '00000000-0000-0000-0000-0000000000d2')
$$, '42501', null, 'nobody signed in cannot found');
reset role;

-- Renaming ---------------------------------------------------------------
insert into members (id, association_id, entered_by, created_at_device,
  device_id, updated_at_device, name, role, is_admin, locale, user_id)
values ('00000000-0000-0000-0000-0000000000e3', '00000000-0000-0000-0000-0000000000a1',
  '00000000-0000-0000-0000-0000000000e1', now(), '00000000-0000-0000-0000-0000000000d1',
  now(), 'Member', 'member', false, 'fr', '00000000-0000-0000-0000-0000000000b3');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b1"}', true);
update associations set name = 'Famille Rabe'
  where id = '00000000-0000-0000-0000-0000000000a1';
select is((select name from associations
           where id = '00000000-0000-0000-0000-0000000000a1'), 'Famille Rabe',
  'an admin renames the association');
select throws_ok($$
  update associations set id = '00000000-0000-0000-0000-0000000000a9'
    where id = '00000000-0000-0000-0000-0000000000a1'
$$, '42501', null, 'an admin cannot change anything but the name');

select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b3"}', true);
update associations set name = 'Pas moi'
  where id = '00000000-0000-0000-0000-0000000000a1';
select is((select name from associations
           where id = '00000000-0000-0000-0000-0000000000a1'), 'Famille Rabe',
  'a plain member''s rename changes nothing');
reset role;

select hasnt_function('public', 'create_association',
  'phones no longer found associations');
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b1"}', true);
select is((select count(*)::int from founding_codes_spent), 0,
  'spent codes are server only, even for the admin');
reset role;

select * from finish();
rollback;
