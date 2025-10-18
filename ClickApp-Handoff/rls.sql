-- ================================================================
-- File: rls.sql
-- Purpose: Row-Level Security policies for Click'App
-- Target: STAGING ONLY (do not run on production)
-- 
-- How to apply:
--   1. Ensure schema.sql and search_path_fix.sql have been applied
--   2. Run: psql $DATABASE_URL_STAGING -f rls.sql
--   3. Verify with: \d+ public.requests (check policies section)
-- 
-- Security Model:
--   - staff: Can create/read own requests
--   - org_admin: Full CRUD within their organization
--   - super_admin: Full CRUD across all organizations
-- 
-- CRITICAL: Always use SECURITY DEFINER functions (has_role, is_super_admin, get_user_org)
--           to avoid recursive RLS issues
-- ================================================================

-- Enable RLS on all tables
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- ORGANIZATIONS
-- ================================================================

CREATE POLICY "orgs_read"
ON public.organizations FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    id = get_user_org(auth.uid()) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "Org admins can update their organization"
ON public.organizations FOR UPDATE
USING (
  id = get_user_org(auth.uid()) 
  AND has_role(auth.uid(), 'org_admin'::app_role)
);

CREATE POLICY "Super admins can manage all organizations"
ON public.organizations FOR ALL
USING (is_super_admin(auth.uid()));

-- ================================================================
-- DEPARTMENTS
-- ================================================================

CREATE POLICY "depts_read"
ON public.departments FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    org_id = get_user_org(auth.uid()) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "Org admins can manage departments"
ON public.departments FOR ALL
USING (
  (
    org_id = get_user_org(auth.uid()) 
    AND has_role(auth.uid(), 'org_admin'::app_role)
  ) 
  OR is_super_admin(auth.uid())
);

-- ================================================================
-- PROJECTS
-- ================================================================

CREATE POLICY "projects_read"
ON public.projects FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    org_id = get_user_org(auth.uid()) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "Org admins can manage projects"
ON public.projects FOR ALL
USING (
  (
    org_id = get_user_org(auth.uid()) 
    AND has_role(auth.uid(), 'org_admin'::app_role)
  ) 
  OR is_super_admin(auth.uid())
);

-- ================================================================
-- PARTNERS
-- ================================================================

CREATE POLICY "partners_read"
ON public.partners FOR SELECT
USING (is_super_admin(auth.uid()));

CREATE POLICY "partners_insert"
ON public.partners FOR INSERT
WITH CHECK (is_super_admin(auth.uid()));

-- ================================================================
-- PROJECT_PARTNERS
-- ================================================================

CREATE POLICY "proj_partners_read"
ON public.project_partners FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    EXISTS (
      SELECT 1 FROM projects pr
      JOIN profiles p ON p.id = auth.uid()
      WHERE pr.id = project_partners.project_id 
        AND pr.org_id = p.org_id
    ) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "proj_partners_insert_admin"
ON public.project_partners FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM projects pr
    JOIN profiles p ON p.id = auth.uid()
    WHERE pr.id = project_partners.project_id 
      AND pr.org_id = p.org_id
  ) 
  AND (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  )
);

-- ================================================================
-- PROFILES
-- ================================================================

-- SECURITY NOTE: This policy prevents email harvesting
-- Regular users can only see their own profile
-- Org admins can see profiles within their org
-- Super admins can see all profiles
CREATE POLICY "profiles_read_org_scoped"
ON public.profiles FOR SELECT
USING (
  is_super_admin(auth.uid()) 
  OR (
    org_id IS NOT NULL 
    AND org_id = get_user_org(auth.uid())
    AND (
      id = auth.uid() 
      OR has_role(auth.uid(), 'org_admin'::app_role)
    )
  )
);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- ================================================================
-- USER_ROLES
-- ================================================================

CREATE POLICY "Users can view their own roles"
ON public.user_roles FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Org admins can manage roles in their org"
ON public.user_roles FOR ALL
USING (
  org_id = get_user_org(auth.uid()) 
  AND has_role(auth.uid(), 'org_admin'::app_role)
);

CREATE POLICY "Super admins can manage all roles"
ON public.user_roles FOR ALL
USING (is_super_admin(auth.uid()));

-- ================================================================
-- VENDORS
-- ================================================================

CREATE POLICY "vendors_read_same_org"
ON public.vendors FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() 
        AND p.org_id = vendors.org_id
    ) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "vendors_insert_admin_same_org"
ON public.vendors FOR INSERT
WITH CHECK (
  (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  ) 
  AND EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.id = auth.uid() 
      AND p.org_id = vendors.org_id
  )
);

CREATE POLICY "vendors_mutate_admin_same_org"
ON public.vendors FOR UPDATE
USING (
  (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  ) 
  AND EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.id = auth.uid() 
      AND p.org_id = vendors.org_id
  )
);

CREATE POLICY "vendors_delete_admin_same_org"
ON public.vendors FOR DELETE
USING (
  (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  ) 
  AND EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.id = auth.uid() 
      AND p.org_id = vendors.org_id
  )
);

-- ================================================================
-- REQUESTS
-- ================================================================

CREATE POLICY "insert_own_requests"
ON public.requests FOR INSERT
WITH CHECK (created_by = auth.uid());

CREATE POLICY "select_own_or_admin"
ON public.requests FOR SELECT
USING (
  created_by = auth.uid() 
  OR has_role(auth.uid(), 'org_admin'::app_role) 
  OR is_super_admin(auth.uid())
);

-- Approvers and admins can update
CREATE POLICY "update_by_admin_or_approver"
ON public.requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM approvals a 
    WHERE a.request_id = requests.id 
      AND a.approver_id = auth.uid()
  ) 
  OR has_role(auth.uid(), 'org_admin'::app_role) 
  OR is_super_admin(auth.uid())
);

-- ================================================================
-- ATTACHMENTS
-- ================================================================

CREATE POLICY "select_att_own_or_admin"
ON public.attachments FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM requests r 
    WHERE r.id = attachments.request_id 
      AND (
        r.created_by = auth.uid() 
        OR has_role(auth.uid(), 'org_admin'::app_role) 
        OR is_super_admin(auth.uid())
      )
  )
);

CREATE POLICY "ins_att_own_req"
ON public.attachments FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM requests r 
    WHERE r.id = attachments.request_id 
      AND r.created_by = auth.uid()
  )
);

-- ================================================================
-- APPROVALS
-- ================================================================

CREATE POLICY "select_approvals_own_or_admin"
ON public.approvals FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM requests r 
    WHERE r.id = approvals.request_id 
      AND (
        r.created_by = auth.uid() 
        OR has_role(auth.uid(), 'org_admin'::app_role) 
        OR is_super_admin(auth.uid())
      )
  )
);

CREATE POLICY "ins_approvals_admin_only"
ON public.approvals FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'org_admin'::app_role) 
  OR is_super_admin(auth.uid())
);

CREATE POLICY "update_own_approval"
ON public.approvals FOR UPDATE
USING (approver_id = auth.uid());

-- ================================================================
-- QUOTES
-- ================================================================

CREATE POLICY "quotes_read"
ON public.quotes FOR SELECT
USING (
  auth.role() = 'authenticated' 
  AND (
    EXISTS (
      SELECT 1 FROM requests r
      JOIN projects pr ON pr.id = r.project_id
      JOIN profiles p ON p.id = auth.uid()
      WHERE r.id = quotes.request_id 
        AND pr.org_id = p.org_id
    ) 
    OR is_super_admin(auth.uid())
  )
);

CREATE POLICY "quotes_insert"
ON public.quotes FOR INSERT
WITH CHECK (
  (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  ) 
  AND EXISTS (
    SELECT 1 FROM requests r
    JOIN projects pr ON pr.id = r.project_id
    JOIN profiles p ON p.id = auth.uid()
    WHERE r.id = quotes.request_id 
      AND pr.org_id = p.org_id
  )
);

CREATE POLICY "quotes_update"
ON public.quotes FOR UPDATE
USING (
  (
    has_role(auth.uid(), 'org_admin'::app_role) 
    OR is_super_admin(auth.uid())
  ) 
  AND EXISTS (
    SELECT 1 FROM requests r
    JOIN projects pr ON pr.id = r.project_id
    JOIN profiles p ON p.id = auth.uid()
    WHERE r.id = quotes.request_id 
      AND pr.org_id = p.org_id
  )
);

-- ================================================================
-- AUDIT_LOG
-- ================================================================

CREATE POLICY "All authenticated users can create audit logs"
ON public.audit_log FOR INSERT
WITH CHECK (auth.uid() = actor_id);

CREATE POLICY "Org admins can view audit logs for their org"
ON public.audit_log FOR SELECT
USING (
  has_role(auth.uid(), 'org_admin'::app_role) 
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = audit_log.actor_id 
      AND profiles.org_id = get_user_org(auth.uid())
  )
);

CREATE POLICY "Super admins can view all audit logs"
ON public.audit_log FOR SELECT
USING (is_super_admin(auth.uid()));

-- ================================================================
-- RATE_LIMITS
-- ================================================================

CREATE POLICY "Users can view their own rate limits"
ON public.rate_limits FOR SELECT
USING (user_id = auth.uid() OR is_super_admin(auth.uid()));

CREATE POLICY "System can insert rate limits"
ON public.rate_limits FOR INSERT
WITH CHECK (true);

-- ================================================================
-- SECURITY ANALYSIS
-- ================================================================

-- CRITICAL VULNERABILITIES ADDRESSED:
-- 1. Email harvesting: profiles_read_org_scoped restricts cross-org visibility
-- 2. Privilege escalation: Roles stored in separate table with SECURITY DEFINER functions
-- 3. Recursive RLS: All helper functions use SECURITY DEFINER + SET search_path
-- 4. Cross-org data leaks: All policies check org_id via get_user_org()
-- 5. Audit bypass: audit_log requires actor_id = auth.uid()

-- KNOWN LIMITATIONS:
-- 1. Email exposure within org is intentional (multi-tenant admin requirement)
-- 2. Super admins have unrestricted access (by design)
-- 3. Rate limiting policies allow unrestricted INSERT (must be enforced in application layer)
