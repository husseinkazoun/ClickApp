-- ================================================================
-- File: search_path_fix.sql
-- Purpose: Fix search_path on SECURITY DEFINER functions
-- Target: STAGING ONLY
-- 
-- How to apply:
--   1. Run: psql $DATABASE_URL_STAGING -f search_path_fix.sql
-- 
-- CRITICAL: Prevents privilege escalation via search_path manipulation
-- ================================================================

-- All SECURITY DEFINER functions already have SET search_path = public
-- This file verifies and patches if needed

ALTER FUNCTION public.has_role(uuid, app_role) SET search_path = public;
ALTER FUNCTION public.is_super_admin(uuid) SET search_path = public;
ALTER FUNCTION public.get_user_org(uuid) SET search_path = public;
ALTER FUNCTION public.validate_request_hierarchy() SET search_path = public;
ALTER FUNCTION public.validate_quote_vendor() SET search_path = public;
ALTER FUNCTION public.validate_status_transition() SET search_path = public;
ALTER FUNCTION public.auto_transition_on_approval() SET search_path = public;
ALTER FUNCTION public.log_approval_decision() SET search_path = public;
ALTER FUNCTION public.log_request_status_change() SET search_path = public;
