-- ================================================================
-- File: schema.sql
-- Purpose: Full database schema export for Click'App MVP
-- Target: STAGING ONLY (do not run on production)
-- 
-- How to apply:
--   1. Connect to staging database
--   2. Run: psql $DATABASE_URL_STAGING -f schema.sql
--   3. Verify with: \dt public.*
-- 
-- Notes:
--   - This file contains CREATE TABLE statements only
--   - RLS policies are in rls.sql
--   - Functions and triggers are in separate files
--   - Enum types are created first, then tables
-- ================================================================

-- ================================================================
-- ENUM TYPES
-- ================================================================

CREATE TYPE public.app_role AS ENUM ('staff', 'org_admin', 'super_admin');

CREATE TYPE public.request_type AS ENUM ('recruitment', 'procurement', 'service');

CREATE TYPE public.request_status AS ENUM ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'closed');

CREATE TYPE public.approval_decision AS ENUM ('pending', 'approved', 'rejected');

-- ================================================================
-- TABLES
-- ================================================================

-- Organizations table
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    primary_color TEXT DEFAULT '#0FB5AE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Departments table
CREATE TABLE public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(org_id, name)
);

-- Projects table
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(org_id, code)
);

-- Partners table (for project partner organizations)
CREATE TABLE public.partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_name TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Project-Partners junction table
CREATE TABLE public.project_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(project_id, partner_id)
);

-- Profiles table (extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    org_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- User roles table (separate from profiles for security)
CREATE TABLE public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.app_role NOT NULL,
    org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(user_id, role, org_id)
);

-- Vendors table
CREATE TABLE public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Requests table
CREATE TABLE public.requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE RESTRICT,
    dept_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    type public.request_type NOT NULL,
    status public.request_status NOT NULL DEFAULT 'draft',
    payload JSONB NOT NULL DEFAULT '{}',
    apps_script_job_id TEXT,
    apps_script_status TEXT,
    apps_script_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    submitted_at TIMESTAMP WITH TIME ZONE
);

-- Attachments table
CREATE TABLE public.attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.requests(id) ON DELETE CASCADE,
    filename TEXT NOT NULL,
    url TEXT NOT NULL,
    mime_type TEXT,
    size_bytes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Approvals table
CREATE TABLE public.approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.requests(id) ON DELETE CASCADE,
    approver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    decision public.approval_decision NOT NULL DEFAULT 'pending',
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    decided_at TIMESTAMP WITH TIME ZONE,
    deadline TIMESTAMP WITH TIME ZONE
);

-- Quotes table (for procurement requests)
CREATE TABLE public.quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.requests(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Audit log table
CREATE TABLE public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    action TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Rate limiting table
CREATE TABLE public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ip_address INET,
    action TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    window_start TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ================================================================
-- INDEXES
-- ================================================================

CREATE INDEX idx_departments_org_id ON public.departments(org_id);
CREATE INDEX idx_projects_org_id ON public.projects(org_id);
CREATE INDEX idx_profiles_org_id ON public.profiles(org_id);
CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX idx_vendors_org_id ON public.vendors(org_id);
CREATE INDEX idx_requests_created_by ON public.requests(created_by);
CREATE INDEX idx_requests_org_id ON public.requests(org_id);
CREATE INDEX idx_requests_project_id ON public.requests(project_id);
CREATE INDEX idx_requests_status ON public.requests(status);
CREATE INDEX idx_attachments_request_id ON public.attachments(request_id);
CREATE INDEX idx_approvals_request_id ON public.approvals(request_id);
CREATE INDEX idx_approvals_approver_id ON public.approvals(approver_id);
CREATE INDEX idx_quotes_request_id ON public.quotes(request_id);
CREATE INDEX idx_audit_log_entity ON public.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_actor ON public.audit_log(actor_id);
CREATE INDEX idx_rate_limits_user ON public.rate_limits(user_id, action);
CREATE INDEX idx_rate_limits_ip ON public.rate_limits(ip_address, action);

-- ================================================================
-- COMMENTS
-- ================================================================

COMMENT ON TABLE public.organizations IS 'NGO organizations using the platform';
COMMENT ON TABLE public.departments IS 'Departments within organizations';
COMMENT ON TABLE public.projects IS 'Projects with unique codes per organization';
COMMENT ON TABLE public.partners IS 'Partner organizations for projects';
COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users';
COMMENT ON TABLE public.user_roles IS 'User role assignments (NEVER check roles on profiles table)';
COMMENT ON TABLE public.vendors IS 'Vendors for procurement requests';
COMMENT ON TABLE public.requests IS 'Main requests table (recruitment/procurement/service)';
COMMENT ON TABLE public.attachments IS 'File attachments for requests';
COMMENT ON TABLE public.approvals IS 'Approval workflow records';
COMMENT ON TABLE public.quotes IS 'Vendor quotes for procurement';
COMMENT ON TABLE public.audit_log IS 'Audit trail for sensitive actions';
COMMENT ON TABLE public.rate_limits IS 'Rate limiting tracking';
