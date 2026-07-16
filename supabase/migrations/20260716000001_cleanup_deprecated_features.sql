-- Migration: Clean up deprecated features (crm, chat, invoicing) from tenant_settings
-- Remove the deprecated keys from existing tenant settings jsonb records

-- Disable features protection trigger since migrations run under system/postgres role
alter table public.tenant_settings disable trigger protect_tenant_settings_features;

update public.tenant_settings
set enabled_features = (enabled_features - 'crm' - 'chat' - 'invoicing');

-- Re-enable the features protection trigger
alter table public.tenant_settings enable trigger protect_tenant_settings_features;

