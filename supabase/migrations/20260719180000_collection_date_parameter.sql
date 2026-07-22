-- Drop the old record_customer_collection function signature
drop function if exists public.record_customer_collection(uuid, uuid, uuid, numeric, text, text, text, uuid);

-- Recreate record_customer_collection with p_collected_at parameter
create or replace function public.record_customer_collection(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null,
  p_device_token text default null,
  p_staff_id uuid default null,
  p_collected_at timestamptz default null
)
returns numeric
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
  v_updated_balance numeric;
  v_collection_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = '22023';
  end if;
  if p_payment_method not in ('cash', 'mobile_wallet', 'bank_transfer') then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  -- Validate permission
  if p_staff_id is not null then
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

    if not public.has_staff_permission(p_staff_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  -- Validate session status if cash
  if p_payment_method = 'cash' then
    if p_session_id is null then
      raise exception 'Session ID is required for cash collections.' using errcode = '22023';
    end if;
    select status into v_session_status
    from public.sessions
    where id = p_session_id and tenant_id = p_tenant_id;
    if v_session_status is null then
      raise exception 'Session not found.' using errcode = 'P0002';
    elsif v_session_status = 'closed' then
      raise exception 'Cannot collect cash during a closed operational session.' using errcode = 'P0001';
    end if;
  end if;

  insert into public.customer_collections (
    tenant_id, customer_id, session_id, amount, payment_method,
    collected_by_user_id, collected_by_staff_id, collected_at, notes
  ) values (
    p_tenant_id, p_customer_id, p_session_id, p_amount, p_payment_method,
    case when p_staff_id is null then auth.uid() else null end,
    p_staff_id, coalesce(p_collected_at, now()), p_notes
  )
  returning id into v_collection_id;

  perform public.post_ledger_entry(
    p_tenant_id := p_tenant_id,
    p_session_id := p_session_id,
    p_type := 'inflow',
    p_category := 'Debt Collection',
    p_amount := p_amount,
    p_payment_method := p_payment_method,
    p_operator_user_id := case when p_staff_id is null then auth.uid() else null end,
    p_operator_staff_id := p_staff_id,
    p_notes := coalesce(p_notes, 'Customer collection ' || v_collection_id::text)
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- Grant execution permissions
grant execute on function public.record_customer_collection(uuid, uuid, uuid, numeric, text, text, text, uuid, timestamptz) to anon, authenticated;
