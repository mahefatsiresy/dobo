-- Fixes from the M4 review.

-- A member's own row: only the language changes. Anything else a phone
-- sends (a stale copy after an admin's edit) is ignored rather than
-- refused, since a refused row would stay stuck on the member's phone.
-- An admin is an active member with the admin flag and the member role:
-- the last one can't be removed, deactivated or turned into a worker.
create or replace function guard_member_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not is_admin() then
    new := jsonb_populate_record(old, jsonb_build_object(
      'locale', new.locale,
      'updated_at_device', new.updated_at_device,
      'device_id', new.device_id));
  end if;
  if old.is_admin and old.active and old.role = 'member'
     and not (new.is_admin and new.active and new.role = 'member')
     and not exists (select 1 from members
                     where association_id = old.association_id
                       and id <> old.id and is_admin and active
                       and role = 'member') then
    raise exception 'last_admin';
  end if;
  return new;
end
$$;

-- The founder may call it again after a lost answer: the same ids are
-- already theirs, so there is nothing to do.
create or replace function create_association(
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
    if exists (select 1 from members
               where user_id = auth.uid() and id = p_member_id
                 and association_id = p_association_id) then
      return;
    end if;
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
