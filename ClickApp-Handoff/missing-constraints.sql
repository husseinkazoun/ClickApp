-- ================================================================
-- File: missing-constraints.sql
-- Purpose: Add missing foreign key constraints and hierarchy validation
-- Target: STAGING ONLY
-- 
-- How to apply:
--   1. Run: psql $DATABASE_URL_STAGING -f missing-constraints.sql
--   2. Test with invalid data to ensure constraints work
-- 
-- Constraints Added:
--   - FK: requests.created_by -> profiles.id
--   - Trigger: validate_request_hierarchy (org/dept/project consistency)
-- ================================================================

-- ================================================================
-- FOREIGN KEY CONSTRAINTS
-- ================================================================

-- Ensure request creator exists in profiles (not just auth.users)
-- Note: This was missing in original schema
ALTER TABLE public.requests
DROP CONSTRAINT IF EXISTS requests_created_by_fkey,
ADD CONSTRAINT requests_created_by_profiles_fkey 
  FOREIGN KEY (created_by) 
  REFERENCES public.profiles(id) 
  ON DELETE RESTRICT;

-- Ensure approver exists in profiles
ALTER TABLE public.approvals
DROP CONSTRAINT IF EXISTS approvals_approver_id_fkey,
ADD CONSTRAINT approvals_approver_id_profiles_fkey
  FOREIGN KEY (approver_id)
  REFERENCES public.profiles(id)
  ON DELETE RESTRICT;

-- ================================================================
-- HIERARCHY VALIDATION TRIGGER
-- ================================================================

-- Function to validate request hierarchy consistency
CREATE OR REPLACE FUNCTION public.validate_request_hierarchy()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate: project.org_id must match request.org_id
  IF NEW.project_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = NEW.project_id
        AND p.org_id = NEW.org_id
    ) THEN
      RAISE EXCEPTION 'Project does not belong to the request organization';
    END IF;
  END IF;

  -- Validate: dept.org_id must match request.org_id
  IF NEW.dept_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.departments d
      WHERE d.id = NEW.dept_id
        AND d.org_id = NEW.org_id
    ) THEN
      RAISE EXCEPTION 'Department does not belong to the request organization';
    END IF;
  END IF;

  -- Validate: creator belongs to request.org_id
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = NEW.created_by
      AND (p.org_id = NEW.org_id OR p.org_id IS NULL) -- Allow super admins (org_id = NULL)
  ) THEN
    RAISE EXCEPTION 'Request creator does not belong to the request organization';
  END IF;

  RETURN NEW;
END;
$$;

-- Attach trigger to requests table
DROP TRIGGER IF EXISTS trigger_validate_request_hierarchy ON public.requests;
CREATE TRIGGER trigger_validate_request_hierarchy
  BEFORE INSERT OR UPDATE ON public.requests
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_request_hierarchy();

-- ================================================================
-- VENDOR ORG CONSISTENCY (defensive check)
-- ================================================================

-- Ensure quotes reference vendors from correct org
CREATE OR REPLACE FUNCTION public.validate_quote_vendor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate: vendor.org_id matches request.org_id
  IF NOT EXISTS (
    SELECT 1 FROM public.vendors v
    JOIN public.requests r ON r.id = NEW.request_id
    WHERE v.id = NEW.vendor_id
      AND v.org_id = r.org_id
  ) THEN
    RAISE EXCEPTION 'Vendor does not belong to the request organization';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_validate_quote_vendor ON public.quotes;
CREATE TRIGGER trigger_validate_quote_vendor
  BEFORE INSERT OR UPDATE ON public.quotes
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_quote_vendor();

-- ================================================================
-- UNIQUE CONSTRAINTS
-- ================================================================

-- Prevent duplicate approvers on same request
-- (Existing unique constraint on approvals is sufficient, but adding explicit name)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_approver_per_request'
  ) THEN
    ALTER TABLE public.approvals 
    ADD CONSTRAINT unique_approver_per_request 
    UNIQUE (request_id, approver_id);
  END IF;
END $$;

-- ================================================================
-- TEST CASES
-- ================================================================

-- Test 1: Try to create request with project from different org (should fail)
-- INSERT INTO public.requests (created_by, org_id, project_id, type)
-- VALUES (
--   '10000000-0000-0000-0000-000000000002',
--   '11111111-1111-1111-1111-111111111111',
--   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', -- This belongs to org 222...
--   'recruitment'
-- );
-- Expected: ERROR: Project does not belong to the request organization

-- Test 2: Try to add quote with vendor from different org (should fail)
-- INSERT INTO public.quotes (request_id, vendor_id, amount)
-- VALUES (
--   'req11111-1111-1111-1111-111111111111', -- NGO Alpha request
--   'v2222222-2222-2222-2222-222222222221', -- NGO Beta vendor
--   1000.00
-- );
-- Expected: ERROR: Vendor does not belong to the request organization

-- Test 3: Try to add duplicate approver (should fail)
-- First insert will succeed, second will fail
-- INSERT INTO public.approvals (request_id, approver_id) VALUES (...);
-- INSERT INTO public.approvals (request_id, approver_id) VALUES (...); -- Same values
-- Expected: ERROR: duplicate key value violates unique constraint
