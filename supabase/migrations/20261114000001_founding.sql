-- M9: the association is founded in the web console (SPEC F16), never on
-- a phone. The found-association edge function checks the founding code,
-- creates the founder's login with the admin API, then calls
-- found_association, which records the code as spent and creates
-- everything else in one transaction.

-- The SHA-256 of each code already used. Server only: RLS on, no policy.
create table founding_codes_spent (
  code_hash text primary key,
  association_id uuid not null references associations (id),
  spent_at timestamptz not null default now()
);
alter table founding_codes_spent enable row level security;

create function found_association(
  p_code_hash text,
  p_user_id uuid,
  p_email text,
  p_association_id uuid,
  p_association_name text,
  p_group_id uuid,
  p_group_name text,
  p_site_id uuid,
  p_site_name text,
  p_location_note text,
  p_member_id uuid,
  p_person_id uuid,
  p_member_name text,
  p_locale text,
  p_device_id uuid
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from founding_codes_spent where code_hash = p_code_hash)
  then
    raise exception 'code_spent';
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
  insert into sites (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, location_note)
  values (p_site_id, p_association_id, p_member_id, now(), p_device_id,
    now(), p_site_name, p_location_note);
  insert into people (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, active)
  values (p_person_id, p_association_id, p_member_id, now(), p_device_id,
    now(), p_member_name, true);
  insert into members (id, association_id, entered_by, created_at_device,
    device_id, updated_at_device, name, group_id, person_id, role, is_admin,
    locale, login, user_id)
  values (p_member_id, p_association_id, p_member_id, now(), p_device_id,
    now(), p_member_name, p_group_id, p_person_id, 'member', true, p_locale,
    p_email, p_user_id);
  -- Last, so two foundings racing on one code collide on the primary key
  -- and the loser's whole transaction rolls back.
  insert into founding_codes_spent (code_hash, association_id)
  values (p_code_hash, p_association_id);
end
$$;

revoke execute on function found_association from public, anon, authenticated;
grant execute on function found_association to service_role;

drop function create_association(uuid, text, uuid, text, uuid, text, text,
  uuid);

-- Admins rename their association; nothing else of it changes.
create policy admin_rename on associations for update
  using (id = my_association() and is_admin())
  with check (id = my_association() and is_admin());
revoke update on associations from anon, authenticated;
grant update (name) on associations to authenticated;
