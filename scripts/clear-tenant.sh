#!/usr/bin/env bash
# Wipe all operational data for a tenant; keep the tenant shell
# (tenants, settings, billing, members, workspace roles).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f "web/.env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' web/.env | xargs)
fi

if [ -n "${SUPABASE_PROJECT_REF:-}" ]; then
  npx supabase link --project-ref "$SUPABASE_PROJECT_REF" >/dev/null
fi

UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

read -r -p "Enter tenant id: " TENANT_ID
TENANT_ID="$(echo "$TENANT_ID" | xargs)"

if [[ ! "$TENANT_ID" =~ $UUID_RE ]]; then
  echo "Invalid tenant id (expected UUID)." >&2
  exit 1
fi

echo ""
echo "This will DELETE all operational data for tenant:"
echo "  $TENANT_ID"
echo ""
echo "Kept: tenants, tenant_settings, tenant_billing, tenant_members, tenant_roles"
echo "Wiped: customers, attendance, baki, collections, ledger, sessions, shifts,"
echo "       staff, staff_roles (tenant), devices, pairings, invitations"
echo ""
read -r -p "Type the tenant id again to confirm: " CONFIRM
CONFIRM="$(echo "$CONFIRM" | xargs)"

if [ "$CONFIRM" != "$TENANT_ID" ]; then
  echo "Confirmation mismatch. Aborted." >&2
  exit 1
fi

SQL_FILE="$(mktemp -t clear-tenant.XXXXXX.sql)"
trap 'rm -f "$SQL_FILE"' EXIT

cat > "$SQL_FILE" <<EOF
begin;

do \$\$
declare
  v_name text;
begin
  select name into v_name from public.tenants where id = '${TENANT_ID}'::uuid;
  if v_name is null then
    raise exception 'Tenant % not found', '${TENANT_ID}';
  end if;
  raise notice 'Clearing tenant: % (%)', v_name, '${TENANT_ID}';
end
\$\$;

-- Bypass ledger immutability + session-lock triggers for this wipe only.
set local session_replication_role = replica;

delete from public.customer_daily_attendance where tenant_id = '${TENANT_ID}'::uuid;
delete from public.baki_transactions where tenant_id = '${TENANT_ID}'::uuid;
delete from public.customer_collections where tenant_id = '${TENANT_ID}'::uuid;
delete from public.transaction_ledger where tenant_id = '${TENANT_ID}'::uuid;
delete from public.customers where tenant_id = '${TENANT_ID}'::uuid;
delete from public.sessions where tenant_id = '${TENANT_ID}'::uuid;
delete from public.shifts where tenant_id = '${TENANT_ID}'::uuid;
delete from public.staff_members where tenant_id = '${TENANT_ID}'::uuid;
delete from public.staff_roles where tenant_id = '${TENANT_ID}'::uuid;
delete from public.paired_devices where tenant_id = '${TENANT_ID}'::uuid;
delete from public.device_pairings where tenant_id = '${TENANT_ID}'::uuid;
delete from public.tenant_invitations where tenant_id = '${TENANT_ID}'::uuid;

commit;
EOF

echo ""
echo "Running against linked Supabase project..."
npx supabase db query --linked -f "$SQL_FILE"

echo ""
echo "Done. Tenant $TENANT_ID is fresh (shell kept)."
