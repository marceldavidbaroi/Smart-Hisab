-- ==============================================================================
-- DYNAMIC CLEAN DATA SCRIPT FOR SMART-HISAB DATABASE
-- ==============================================================================
-- Description: Automatically finds and truncates all tables in the `public` schema
-- that actually exist, plus clears `auth.users` authentication data.
-- Safe to run on any environment regardless of which migrations have been applied.
-- ==============================================================================

DO $$
DECLARE
    r RECORD;
    table_list text;
BEGIN
    -- 1. Gather all existing tables in public schema
    SELECT string_agg(quote_ident(table_schema) || '.' || quote_ident(table_name), ', ')
    INTO table_list
    FROM information_schema.tables
    WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE';

    -- 2. Truncate all existing public tables if any exist
    IF table_list IS NOT NULL THEN
        EXECUTE 'TRUNCATE TABLE ' || table_list || ' RESTART IDENTITY CASCADE;';
        RAISE NOTICE 'Truncated tables: %', table_list;
    ELSE
        RAISE NOTICE 'No tables found in public schema.';
    END IF;

    -- 3. Clear auth users (cascade deletes sessions, identities, mfa, etc.)
    DELETE FROM auth.users;

    -- 4. Re-seed default system tenant roles (if public.tenant_roles table exists)
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'tenant_roles'
    ) THEN
        INSERT INTO public.tenant_roles (id, tenant_id, name, description, permissions, is_system_role)
        VALUES
          ('00000000-0000-0000-0000-000000000001', NULL, 'Owner', 'Full organization control with billing permissions.', '{"all": true}'::jsonb, true),
          ('00000000-0000-0000-0000-000000000002', NULL, 'Admin', 'Organization management excluding billing.', '{"manage_members": true, "manage_settings": true}'::jsonb, true),
          ('00000000-0000-0000-0000-000000000003', NULL, 'Member', 'Standard user permissions.', '{"read": true, "write": true}'::jsonb, true),
          ('00000000-0000-0000-0000-000000000004', NULL, 'Manager', 'Store manager permissions.', '{"manage_store": true}'::jsonb, true),
          ('00000000-0000-0000-0000-000000000005', NULL, 'Staff', 'Pos/Kiosk operational staff permissions.', '{"operate_pos": true}'::jsonb, true)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          description = EXCLUDED.description,
          permissions = EXCLUDED.permissions,
          is_system_role = EXCLUDED.is_system_role;
    END IF;

    RAISE NOTICE 'Database clean completed successfully. All user & transaction data cleared.';
END $$;
