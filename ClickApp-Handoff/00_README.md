# Click'App Handoff Package

Complete documentation and migration files for Click'App MVP.

## Quick Start

1. **Create branch**: `git checkout -b handoff/initial`
2. **Apply staging migrations**:
   ```bash
   cd ClickApp-Handoff/03_DB
   psql $DATABASE_URL_STAGING -f schema.sql
   psql $DATABASE_URL_STAGING -f rls.sql
   psql $DATABASE_URL_STAGING -f storage-policies.sql
   psql $DATABASE_URL_STAGING -f missing-constraints.sql
   psql $DATABASE_URL_STAGING -f status-transition.sql
   psql $DATABASE_URL_STAGING -f approvals-audit.sql
   psql $DATABASE_URL_STAGING -f search_path_fix.sql
   psql $DATABASE_URL_STAGING -f rate-limit.sql
   psql $DATABASE_URL_STAGING -f seed_minimal.sql
   ```
3. **Configure GitHub secrets** (see 08_Ops/cicd-plan.md)
4. **Test with seed accounts** (see 07_Testing/test-accounts.md)

## Structure

- **02_Env/** - Environment variables
- **03_DB/** - Database migrations & policies
- **04_Functions/** - Edge functions
- **07_Testing/** - Test accounts & scenarios
- **08_Ops/** - CI/CD workflows
- **09_Compliance/** - Data protection notes

## Test Accounts

| Email | Password | Role | Org |
|-------|----------|------|-----|
| super@test.com | TestPass123! | super_admin | - |
| admin1@ngo1.org | TestPass123! | org_admin | NGO Alpha |
| staff1@ngo1.org | TestPass123! | staff | NGO Alpha |
| staff2@ngo2.org | TestPass123! | staff | NGO Beta |

## Security Notes

- Email exposure within org is **intentional** (multi-tenant design)
- All SECURITY DEFINER functions use `SET search_path = public`
- Storage bucket is **private** with org-scoped RLS
- State machine enforced via triggers
