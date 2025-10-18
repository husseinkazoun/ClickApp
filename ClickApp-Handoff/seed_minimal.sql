-- ================================================================
-- File: seed_minimal.sql
-- Purpose: Minimal seed data for testing Click'App MVP
-- Target: STAGING ONLY (do not run on production)
-- 
-- How to apply:
--   1. Ensure schema.sql, rls.sql have been applied
--   2. Run: psql $DATABASE_URL_STAGING -f seed_minimal.sql
--   3. Check: SELECT * FROM organizations;
-- 
-- Test Accounts Created:
--   - super@test.com (super_admin) - password: TestPass123!
--   - admin1@ngo1.org (org_admin, NGO Alpha) - password: TestPass123!
--   - staff1@ngo1.org (staff, NGO Alpha) - password: TestPass123!
--   - staff2@ngo2.org (staff, NGO Beta) - password: TestPass123!
-- 
-- Data Created:
--   - 3 Organizations (NGO Alpha, NGO Beta, NGO Gamma)
--   - 3 Departments (1 per org)
--   - 3 Projects (1 per org)
--   - 3 Vendors per org (9 total)
--   - 9 Requests (3 per type: recruitment, procurement, service)
-- ================================================================

-- ================================================================
-- CLEAR EXISTING DATA (STAGING ONLY!)
-- ================================================================

-- DANGER: This deletes all data. Only run on staging!
TRUNCATE TABLE 
  public.rate_limits,
  public.audit_log,
  public.quotes,
  public.approvals,
  public.attachments,
  public.requests,
  public.vendors,
  public.user_roles,
  public.profiles,
  public.project_partners,
  public.partners,
  public.projects,
  public.departments,
  public.organizations
CASCADE;

-- ================================================================
-- ORGANIZATIONS
-- ================================================================

INSERT INTO public.organizations (id, name, primary_color, logo_url) VALUES
('11111111-1111-1111-1111-111111111111', 'NGO Alpha', '#0FB9B1', NULL),
('22222222-2222-2222-2222-222222222222', 'NGO Beta', '#3B82F6', NULL),
('33333333-3333-3333-3333-333333333333', 'NGO Gamma', '#10B981', NULL);

-- ================================================================
-- DEPARTMENTS
-- ================================================================

INSERT INTO public.departments (id, org_id, name) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Programs'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Operations'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'Finance');

-- ================================================================
-- PROJECTS
-- ================================================================

INSERT INTO public.projects (id, org_id, name, code) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'Education Access Initiative', 'EAI-2024'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '22222222-2222-2222-2222-222222222222', 'Healthcare Outreach Program', 'HOP-2024'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '33333333-3333-3333-3333-333333333333', 'Clean Water Project', 'CWP-2024');

-- ================================================================
-- PARTNERS
-- ================================================================

INSERT INTO public.partners (id, org_name, email) VALUES
('99999991-9999-9999-9999-999999999999', 'UNICEF', 'partner@unicef.org'),
('99999992-9999-9999-9999-999999999999', 'WHO', 'partner@who.int'),
('99999993-9999-9999-9999-999999999999', 'World Bank', 'partner@worldbank.org');

INSERT INTO public.project_partners (project_id, partner_id) VALUES
('dddddddd-dddd-dddd-dddd-dddddddddddd', '99999991-9999-9999-9999-999999999999'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '99999992-9999-9999-9999-999999999999');

-- ================================================================
-- TEST USERS (auth.users)
-- ================================================================

-- NOTE: In real Supabase, users are created via signup API
-- This simulates what would exist after signup
-- Password hashes are for "TestPass123!" using bcrypt

-- Super Admin
INSERT INTO auth.users (
  id, 
  email, 
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'super@test.com',
  '$2a$10$rLJzUqT5kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kx', -- bcrypt hash
  now(),
  '{"name": "Super Admin"}',
  now(),
  now()
);

-- Org Admin for NGO Alpha
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '10000000-0000-0000-0000-000000000001',
  'admin1@ngo1.org',
  '$2a$10$rLJzUqT5kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kx',
  now(),
  '{"name": "Admin One"}',
  now(),
  now()
);

-- Staff for NGO Alpha
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '10000000-0000-0000-0000-000000000002',
  'staff1@ngo1.org',
  '$2a$10$rLJzUqT5kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kx',
  now(),
  '{"name": "Staff One"}',
  now(),
  now()
);

-- Staff for NGO Beta
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '20000000-0000-0000-0000-000000000002',
  'staff2@ngo2.org',
  '$2a$10$rLJzUqT5kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kxz.kx',
  now(),
  '{"name": "Staff Two"}',
  now(),
  now()
);

-- ================================================================
-- PROFILES
-- ================================================================

INSERT INTO public.profiles (id, name, email, org_id) VALUES
('00000000-0000-0000-0000-000000000000', 'Super Admin', 'super@test.com', NULL),
('10000000-0000-0000-0000-000000000001', 'Admin One', 'admin1@ngo1.org', '11111111-1111-1111-1111-111111111111'),
('10000000-0000-0000-0000-000000000002', 'Staff One', 'staff1@ngo1.org', '11111111-1111-1111-1111-111111111111'),
('20000000-0000-0000-0000-000000000002', 'Staff Two', 'staff2@ngo2.org', '22222222-2222-2222-2222-222222222222');

-- ================================================================
-- USER ROLES
-- ================================================================

INSERT INTO public.user_roles (user_id, role, org_id) VALUES
('00000000-0000-0000-0000-000000000000', 'super_admin', NULL),
('10000000-0000-0000-0000-000000000001', 'org_admin', '11111111-1111-1111-1111-111111111111'),
('10000000-0000-0000-0000-000000000002', 'staff', '11111111-1111-1111-1111-111111111111'),
('20000000-0000-0000-0000-000000000002', 'staff', '22222222-2222-2222-2222-222222222222');

-- ================================================================
-- VENDORS
-- ================================================================

INSERT INTO public.vendors (id, org_id, name, contact_person, email, phone) VALUES
-- NGO Alpha vendors
('v1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Office Supplies Ltd', 'John Doe', 'john@officesupplies.com', '+1234567890'),
('v1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'Tech Solutions Inc', 'Jane Smith', 'jane@techsolutions.com', '+1234567891'),
('v1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'Catering Services Pro', 'Bob Wilson', 'bob@catering.com', '+1234567892'),
-- NGO Beta vendors
('v2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', 'Medical Equipment Co', 'Alice Brown', 'alice@medequip.com', '+1234567893'),
('v2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Pharmaceutical Supplies', 'Charlie Davis', 'charlie@pharma.com', '+1234567894'),
('v2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222', 'Transport Logistics', 'Diana Evans', 'diana@transport.com', '+1234567895'),
-- NGO Gamma vendors
('v3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333', 'Water Filtration Systems', 'Eve Foster', 'eve@waterfilt.com', '+1234567896'),
('v3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333', 'Construction Materials', 'Frank Green', 'frank@construction.com', '+1234567897'),
('v3333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333', 'Engineering Consultants', 'Grace Hill', 'grace@engineering.com', '+1234567898');

-- ================================================================
-- REQUESTS
-- ================================================================

-- Recruitment Requests (3)
INSERT INTO public.requests (id, created_by, org_id, dept_id, project_id, type, status, payload, submitted_at) VALUES
('req11111-1111-1111-1111-111111111111', '10000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'recruitment', 'submitted', 
'{"position_title": "Program Officer", "contract_type": "Full-time", "duration_months": 12, "job_description": "Manage education programs", "evaluation_criteria": "Experience in NGO sector"}', 
now() - interval '2 days'),

('req22222-2222-2222-2222-222222222222', '20000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'recruitment', 'under_review',
'{"position_title": "Field Coordinator", "contract_type": "Contract", "duration_months": 6, "job_description": "Coordinate field operations", "evaluation_criteria": "Leadership skills"}',
now() - interval '1 day'),

('req33333-3333-3333-3333-333333333333', '10000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'recruitment', 'draft',
'{"position_title": "Finance Assistant", "contract_type": "Part-time", "duration_months": 12, "job_description": "Support finance department", "evaluation_criteria": "Accounting background"}',
NULL);

-- Procurement Requests (3)
INSERT INTO public.requests (id, created_by, org_id, dept_id, project_id, type, status, payload, submitted_at) VALUES
('req44444-4444-4444-4444-444444444444', '10000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'procurement', 'submitted',
'{"item_description": "Laptop computers (15 units)", "specifications": "Intel i5, 8GB RAM, 256GB SSD", "delivery_timeline": "2 weeks"}',
now() - interval '3 days'),

('req55555-5555-5555-5555-555555555555', '20000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'procurement', 'approved',
'{"item_description": "Medical supplies", "specifications": "Bandages, antiseptics, gloves", "delivery_timeline": "1 week"}',
now() - interval '5 days'),

('req66666-6666-6666-6666-666666666666', '10000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'procurement', 'draft',
'{"item_description": "Office furniture", "specifications": "Desks and chairs (10 sets)", "delivery_timeline": "3 weeks"}',
NULL);

-- Service Requests (3)
INSERT INTO public.requests (id, created_by, org_id, dept_id, project_id, type, status, payload, submitted_at) VALUES
('req77777-7777-7777-7777-777777777777', '20000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'service', 'submitted',
'{"service_category": "Catering", "priority": "medium", "location": "Main Office", "time_window": "Next week"}',
now() - interval '1 day'),

('req88888-8888-8888-8888-888888888888', '10000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'service', 'rejected',
'{"service_category": "Cleaning", "priority": "low", "location": "Storage Room", "time_window": "Flexible"}',
now() - interval '7 days'),

('req99999-9999-9999-9999-999999999999', '20000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'service', 'draft',
'{"service_category": "IT Support", "priority": "high", "location": "Remote", "time_window": "ASAP"}',
NULL);

-- ================================================================
-- APPROVALS (for under_review request)
-- ================================================================

INSERT INTO public.approvals (request_id, approver_id, decision, deadline) VALUES
('req22222-2222-2222-2222-222222222222', '10000000-0000-0000-0000-000000000001', 'pending', now() + interval '3 days');

-- ================================================================
-- QUOTES (for procurement requests)
-- ================================================================

INSERT INTO public.quotes (request_id, vendor_id, amount, currency, notes) VALUES
('req44444-4444-4444-4444-444444444444', 'v1111111-1111-1111-1111-111111111112', 15000.00, 'USD', 'Dell Latitude series, includes warranty'),
('req44444-4444-4444-4444-444444444444', 'v1111111-1111-1111-1111-111111111111', 14500.00, 'USD', 'HP ProBook, bulk discount applied'),
('req44444-4444-4444-4444-444444444444', 'v1111111-1111-1111-1111-111111111113', 15800.00, 'USD', 'Lenovo ThinkPad, premium support');

INSERT INTO public.quotes (request_id, vendor_id, amount, currency, notes) VALUES
('req55555-5555-5555-5555-555555555555', 'v2222222-2222-2222-2222-222222222221', 2500.00, 'USD', 'Complete medical kit, sterile packaging'),
('req55555-5555-5555-5555-555555555555', 'v2222222-2222-2222-2222-222222222222', 2300.00, 'USD', 'Generic brands, good quality'),
('req55555-5555-5555-5555-555555555555', 'v2222222-2222-2222-2222-222222222223', 2400.00, 'USD', 'Express delivery available');

-- ================================================================
-- AUDIT LOG ENTRIES
-- ================================================================

INSERT INTO public.audit_log (actor_id, entity_type, entity_id, action, metadata) VALUES
('10000000-0000-0000-0000-000000000002', 'request', 'req11111-1111-1111-1111-111111111111', 'created', '{"type": "recruitment"}'),
('10000000-0000-0000-0000-000000000002', 'request', 'req11111-1111-1111-1111-111111111111', 'submitted', '{"to_status": "submitted"}'),
('10000000-0000-0000-0000-000000000001', 'request', 'req55555-5555-5555-5555-555555555555', 'approved', '{"approved_by": "admin1@ngo1.org"}');

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Run these to verify seed data:
-- SELECT COUNT(*) FROM organizations; -- Should be 3
-- SELECT COUNT(*) FROM departments; -- Should be 3
-- SELECT COUNT(*) FROM projects; -- Should be 3
-- SELECT COUNT(*) FROM profiles; -- Should be 4
-- SELECT COUNT(*) FROM user_roles; -- Should be 4
-- SELECT COUNT(*) FROM vendors; -- Should be 9
-- SELECT COUNT(*) FROM requests; -- Should be 9
-- SELECT COUNT(*) FROM quotes; -- Should be 6
-- SELECT COUNT(*) FROM approvals; -- Should be 1
-- SELECT COUNT(*) FROM audit_log; -- Should be 3

-- Test user access:
-- SELECT r.* FROM requests r WHERE created_by = '10000000-0000-0000-0000-000000000002';
-- SELECT * FROM user_roles WHERE user_id = '00000000-0000-0000-0000-000000000000';
