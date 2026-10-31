-- Roles and row-level security (SPEC §3; plan Decision 6). The app hides
-- what a role can't do; these policies refuse it.

-- The signed-in account's active member row. Security definer so policies
-- on members can call it without recursing into themselves.
create function current_member() returns members
language sql stable security definer set search_path = public as $$
  select * from members where user_id = auth.uid() and active
$$;

create function my_association() returns uuid
language sql stable security definer set search_path = public as $$
  select association_id from members where user_id = auth.uid() and active
$$;

create function my_member_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from members where user_id = auth.uid() and active
$$;

create function is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members
                 where user_id = auth.uid() and active and role = 'member')
$$;

create function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members
                 where user_id = auth.uid() and active and is_admin)
$$;

-- The sync triggers write where clients may not (reference_history, the
-- sequence): they run as their owner.
alter function stamp_sync() security definer set search_path = public;
alter function keep_history() security definer set search_path = public;

alter table associations enable row level security;
alter table reference_history enable row level security;

create policy read_own on associations for select
  using (id = my_association());

do $$
declare
  t text;
begin
  foreach t in array array['groups', 'members', 'sites', 'people', 'ponds',
    'batches', 'visits', 'setting_overrides', 'stockings', 'transfers',
    'daily_logs', 'water_readings', 'samples', 'observations',
    'health_events', 'treatments']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy read_own on %I for select
      using (association_id = my_association())', t);
  end loop;

  -- Events: workers log days; everything else is a member's.
  execute 'create policy write_own on daily_logs for insert
    with check (association_id = my_association())';
  foreach t in array array['stockings', 'transfers', 'water_readings',
    'samples', 'observations', 'health_events', 'treatments']
  loop
    execute format('create policy write_own on %I for insert
      with check (association_id = my_association() and is_member())', t);
  end loop;

  -- Reference rows only admins manage.
  foreach t in array array['sites', 'people', 'groups', 'setting_overrides']
  loop
    execute format('create policy admin_insert on %I for insert
      with check (association_id = my_association() and is_admin())', t);
    execute format('create policy admin_update on %I for update
      using (association_id = my_association() and is_admin())
      with check (association_id = my_association() and is_admin())', t);
  end loop;
end
$$;

-- Ponds: admins add them; members change them (status follows health
-- events and preparation).
create policy admin_insert on ponds for insert
  with check (association_id = my_association() and is_admin());
create policy member_update on ponds for update
  using (association_id = my_association() and is_member())
  with check (association_id = my_association() and is_member());

create policy member_insert on batches for insert
  with check (association_id = my_association() and is_member());
create policy member_update on batches for update
  using (association_id = my_association() and is_member())
  with check (association_id = my_association() and is_member());

-- A visit belongs to the member who made it.
create policy member_insert on visits for insert
  with check (association_id = my_association() and is_member());
create policy own_update on visits for update
  using (association_id = my_association() and is_member()
         and entered_by = my_member_id())
  with check (association_id = my_association() and is_member()
              and entered_by = my_member_id());

-- Members are created by the create-account edge function (service role).
-- Admins edit anyone in their association; a member edits their own row,
-- and the trigger below limits that to the language.
create policy edit on members for update
  using (association_id = my_association()
         and (is_admin() or id = my_member_id()))
  with check (association_id = my_association()
              and (is_admin() or id = my_member_id()));

create function guard_member_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  free constant text[] := array['locale', 'updated_at_device', 'device_id',
    'server_seq', 'server_received_at'];
begin
  -- Signed-in non-admins may change only their language. The service
  -- role and the database owner have no auth.uid() and pass.
  if auth.uid() is not null and not is_admin()
     and (to_jsonb(new) - free) is distinct from (to_jsonb(old) - free) then
    raise exception 'only_locale' using errcode = '42501';
  end if;
  if old.is_admin and old.active and not (new.is_admin and new.active)
     and not exists (select 1 from members
                     where association_id = old.association_id
                       and id <> old.id and is_admin and active) then
    raise exception 'last_admin';
  end if;
  return new;
end
$$;

create trigger guard_member_update before update on members
  for each row execute function guard_member_update();

-- The founder's first step: the association, its first group, and the
-- founder as its admin. Ids come from the phone, so a phone that recorded
-- before it had an account keeps its association, site and user ids.
create function create_association(
  p_association_id uuid,
  p_association_name text,
  p_group_id uuid,
  p_group_name text,
  p_member_id uuid,
  p_member_name text,
  p_locale text,
  p_device_id uuid
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'not_signed_in';
  end if;
  if exists (select 1 from members where user_id = auth.uid()) then
    raise exception 'already_member';
  end if;
  if exists (select 1 from associations where id = p_association_id) then
    raise exception 'association_exists';
  end if;
  insert into associations (id, name)
  values (p_association_id, p_association_name);
  insert into groups (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name)
  values (p_group_id, p_association_id, p_member_id, now(), p_device_id,
    now(), p_group_name);
  insert into members (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, group_id, role, is_admin, locale,
    login, user_id)
  values (p_member_id, p_association_id, p_member_id, now(), p_device_id,
    now(), p_member_name, p_group_id, 'member', true, p_locale,
    (select email from auth.users where id = auth.uid()), auth.uid());
end
$$;

revoke execute on function create_association from public, anon;
grant execute on function create_association to authenticated;
