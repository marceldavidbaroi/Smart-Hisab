-- Daily Transaction (POS): create/edit RPCs, editable window, kiosk ledger reads

-- 1. Immutability: allow POS UPDATE only when GUC app.ledger_pos_edit = 'on'
create or replace function public.block_ledger_modifications()
returns trigger
language plpgsql
as $$
begin
  if TG_OP = 'DELETE' then
    raise exception
      'Immutable Ledger Rule: updates and deletions of ledger transactions are prohibited.'
      using errcode = 'P0001';
  end if;

  if TG_OP = 'UPDATE'
     and coalesce(current_setting('app.ledger_pos_edit', true), '') = 'on'
     and OLD.category = 'POS'
     and NEW.category = 'POS'
  then
    return NEW;
  end if;

  raise exception
    'Immutable Ledger Rule: updates and deletions of ledger transactions are prohibited.'
    using errcode = 'P0001';
end;
$$;

-- 2. Resolve tenant POS edit window as an interval (default 24 hours)
create or replace function public.pos_edit_window_interval(p_tenant_id uuid)
returns interval
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_pref jsonb;
  v_value numeric;
  v_unit text;
begin
  select preferences->'pos_edit_window'
  into v_pref
  from public.tenant_settings
  where tenant_id = p_tenant_id;

  if v_pref is null or jsonb_typeof(v_pref) <> 'object' then
    return interval '24 hours';
  end if;

  v_value := nullif(v_pref->>'value', '')::numeric;
  v_unit := lower(coalesce(v_pref->>'unit', 'hours'));

  if v_value is null or v_value <= 0 then
    return interval '24 hours';
  end if;

  if v_unit = 'minutes' then
    return make_interval(mins => ceil(v_value)::int);
  elsif v_unit = 'days' then
    return make_interval(days => ceil(v_value)::int);
  elsif v_unit = 'hours' then
    return make_interval(hours => ceil(v_value)::int);
  end if;

  return interval '24 hours';
end;
$$;

-- 3. Shared kiosk device + staff guard
create or replace function public.assert_kiosk_staff(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid
)
returns void
security definer
set search_path = public
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.paired_devices
    where device_token = p_device_token
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.staff_members
    where id = p_staff_id
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid staff member for tenant.' using errcode = '42501';
  end if;
end;
$$;

-- 4. log_pos_sale
create or replace function public.log_pos_sale(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_session_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
  v_id uuid;
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'kiosk', 'log_pos') then
    raise exception 'Permission denied: log_pos.' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero.' using errcode = '22023';
  end if;

  if p_payment_method not in ('cash', 'mobile_wallet') then
    raise exception 'POS payment method must be cash or mobile_wallet (online).'
      using errcode = '22023';
  end if;

  if p_session_id is null then
    raise exception 'Session ID is required for POS sales.' using errcode = '22023';
  end if;

  select status into v_session_status
  from public.sessions
  where id = p_session_id and tenant_id = p_tenant_id;

  if v_session_status is null then
    raise exception 'Session not found.' using errcode = 'P0002';
  elsif v_session_status = 'closed' then
    raise exception 'Cannot log POS during a closed operational session.' using errcode = 'P0001';
  end if;

  v_id := public.post_ledger_entry(
    p_tenant_id := p_tenant_id,
    p_session_id := p_session_id,
    p_type := 'inflow',
    p_category := 'POS',
    p_amount := p_amount,
    p_payment_method := p_payment_method,
    p_operator_user_id := null,
    p_operator_staff_id := p_staff_id,
    p_notes := p_notes
  );

  return v_id;
end;
$$;

-- 5. edit_pos_sale
create or replace function public.edit_pos_sale(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_ledger_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_row public.transaction_ledger%rowtype;
  v_session_status text;
  v_window interval;
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'kiosk', 'log_pos') then
    raise exception 'Permission denied: log_pos.' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero.' using errcode = '22023';
  end if;

  if p_payment_method not in ('cash', 'mobile_wallet') then
    raise exception 'POS payment method must be cash or mobile_wallet (online).'
      using errcode = '22023';
  end if;

  select * into v_row
  from public.transaction_ledger
  where id = p_ledger_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'Ledger entry not found.' using errcode = 'P0002';
  end if;

  if v_row.category <> 'POS' then
    raise exception 'Only POS transactions can be edited.' using errcode = '22023';
  end if;

  if v_row.session_id is null then
    raise exception 'POS entry has no session.' using errcode = '22023';
  end if;

  select status into v_session_status
  from public.sessions
  where id = v_row.session_id and tenant_id = p_tenant_id;

  if v_session_status is null or v_session_status = 'closed' then
    raise exception 'Cannot edit POS after the operational session is closed.'
      using errcode = 'P0001';
  end if;

  v_window := public.pos_edit_window_interval(p_tenant_id);
  if now() >= v_row.created_at + v_window then
    raise exception 'POS edit period has expired.' using errcode = 'P0001';
  end if;

  perform set_config('app.ledger_pos_edit', 'on', true);

  update public.transaction_ledger
  set
    amount = p_amount,
    payment_method = p_payment_method,
    notes = p_notes,
    updated_at = now()
  where id = p_ledger_id
    and tenant_id = p_tenant_id;

  perform set_config('app.ledger_pos_edit', '', true);

  return p_ledger_id;
exception
  when others then
    perform set_config('app.ledger_pos_edit', '', true);
    raise;
end;
$$;

-- 6. list_session_ledger_entries (kiosk)
create or replace function public.list_session_ledger_entries(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_session_id uuid
)
returns setof public.transaction_ledger
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'financial_ledger', 'session_ledger_read') then
    raise exception 'Permission denied: session_ledger_read.' using errcode = '42501';
  end if;

  return query
  select tl.*
  from public.transaction_ledger tl
  where tl.tenant_id = p_tenant_id
    and tl.session_id = p_session_id
  order by tl.created_at desc;
end;
$$;

-- 7. get_cash_register_running_balance_kiosk
create or replace function public.get_cash_register_running_balance_kiosk(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_session_id uuid
)
returns numeric(12, 2)
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'financial_ledger', 'cash_balance_read') then
    raise exception 'Permission denied: cash_balance_read.' using errcode = '42501';
  end if;

  return public.get_cash_register_running_balance(p_tenant_id, p_session_id);
end;
$$;

-- 8. get_pos_edit_window (kiosk + workspace-friendly)
create or replace function public.get_pos_edit_window(
  p_tenant_id uuid,
  p_device_token text default null
)
returns jsonb
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_pref jsonb;
  v_value numeric;
  v_unit text;
begin
  if p_device_token is not null then
    if not exists (
      select 1 from public.paired_devices
      where device_token = p_device_token
        and tenant_id = p_tenant_id
        and is_active = true
    ) then
      raise exception 'Invalid or inactive device.' using errcode = '42501';
    end if;
  elsif auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  elsif not exists (
    select 1 from public.tenant_members
    where tenant_id = p_tenant_id and user_id = auth.uid()
  ) and not exists (
    select 1 from public.user_profiles
    where id = auth.uid() and is_superadmin = true
  ) then
    raise exception 'Permission denied.' using errcode = '42501';
  end if;

  select preferences->'pos_edit_window'
  into v_pref
  from public.tenant_settings
  where tenant_id = p_tenant_id;

  v_value := coalesce(nullif(v_pref->>'value', '')::numeric, 24);
  v_unit := lower(coalesce(v_pref->>'unit', 'hours'));

  if v_value <= 0 then
    v_value := 24;
  end if;
  if v_unit not in ('minutes', 'hours', 'days') then
    v_unit := 'hours';
  end if;

  return jsonb_build_object(
    'value', v_value,
    'unit', v_unit,
    'interval_seconds', extract(epoch from public.pos_edit_window_interval(p_tenant_id))::bigint
  );
end;
$$;

grant execute on function public.pos_edit_window_interval(uuid) to authenticated;
grant execute on function public.assert_kiosk_staff(uuid, text, uuid) to authenticated;
grant execute on function public.log_pos_sale(uuid, text, uuid, uuid, numeric, text, text)
  to anon, authenticated;
grant execute on function public.edit_pos_sale(uuid, text, uuid, uuid, numeric, text, text)
  to anon, authenticated;
grant execute on function public.list_session_ledger_entries(uuid, text, uuid, uuid)
  to anon, authenticated;
grant execute on function public.get_cash_register_running_balance_kiosk(uuid, text, uuid, uuid)
  to anon, authenticated;
grant execute on function public.get_pos_edit_window(uuid, text)
  to anon, authenticated;
