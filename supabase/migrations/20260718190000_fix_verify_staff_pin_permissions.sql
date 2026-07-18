-- Fix: verify_staff_pin must return staff_roles.permissions so kiosk can gate Open Session etc.

create or replace function public.verify_staff_pin(
  p_tenant_id uuid,
  p_pin text
)
returns jsonb
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_staff record;
begin
  p_pin := trim(p_pin);

  for v_staff in
    select sm.id, sm.full_name, sr.name as role, sr.permissions, sm.hashed_pin, sm.temp_pin
    from public.staff_members sm
    join public.staff_roles sr on sm.staff_role_id = sr.id
    where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  loop
    if v_staff.temp_pin is not null and v_staff.temp_pin = p_pin then
      return jsonb_build_object(
        'success', true,
        'setup_required', true,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
      );
    end if;

    if v_staff.hashed_pin is not null and v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin) then
      return jsonb_build_object(
        'success', true,
        'setup_required', false,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
      );
    end if;
  end loop;

  return jsonb_build_object(
    'success', false,
    'message', 'Invalid PIN code.'
  );
end;
$$;

create or replace function public.verify_staff_pin(
  p_device_token text,
  p_tenant_id uuid,
  p_pin text
)
returns jsonb
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_device record;
  v_staff record;
begin
  select id, is_active, failed_attempts, locked_until
  into v_device
  from public.paired_devices
  where tenant_id = p_tenant_id and device_token = p_device_token;

  if not found or v_device.is_active = false then
    return jsonb_build_object(
      'success', false,
      'code', 'DEVICE_BLOCKED',
      'message', 'Device is disabled or unauthorized.'
    );
  end if;

  if v_device.locked_until is not null and v_device.locked_until > now() then
    return jsonb_build_object(
      'success', false,
      'code', 'DEVICE_LOCKED',
      'message', 'Device temporarily locked. Try again in ' ||
                  ceil(extract(epoch from (v_device.locked_until - now())) / 60) || ' mins.'
    );
  end if;

  p_pin := trim(p_pin);

  for v_staff in
    select sm.id, sm.full_name, sr.name as role, sr.permissions, sm.hashed_pin, sm.temp_pin
    from public.staff_members sm
    join public.staff_roles sr on sm.staff_role_id = sr.id
    where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  loop
    if v_staff.temp_pin is not null and v_staff.temp_pin = p_pin then
      update public.paired_devices
      set failed_attempts = 0, locked_until = null, last_active_at = now()
      where id = v_device.id;

      return jsonb_build_object(
        'success', true,
        'setup_required', true,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
      );
    end if;

    if v_staff.hashed_pin is not null and v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin) then
      update public.paired_devices
      set failed_attempts = 0, locked_until = null, last_active_at = now()
      where id = v_device.id;

      return jsonb_build_object(
        'success', true,
        'setup_required', false,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
      );
    end if;
  end loop;

  if v_device.failed_attempts + 1 >= 5 then
    update public.paired_devices
    set failed_attempts = failed_attempts + 1,
        locked_until = now() + interval '15 minutes',
        last_active_at = now()
    where id = v_device.id;
    return jsonb_build_object(
      'success', false,
      'code', 'DEVICE_LOCKED',
      'message', 'Too many invalid attempts. Device locked for 15 minutes.'
    );
  else
    update public.paired_devices
    set failed_attempts = failed_attempts + 1,
        last_active_at = now()
    where id = v_device.id;
    return jsonb_build_object(
      'success', false,
      'code', 'INVALID_PIN',
      'message', 'Invalid PIN. Attempts remaining: ' || (5 - (v_device.failed_attempts + 1))
    );
  end if;
end;
$$;

grant execute on function public.verify_staff_pin(uuid, text) to anon, authenticated;
grant execute on function public.verify_staff_pin(text, uuid, text) to anon, authenticated;
