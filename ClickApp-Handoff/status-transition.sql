-- ================================================================
-- File: status-transition.sql
-- Purpose: State machine enforcement for request status transitions
-- Target: STAGING ONLY
-- 
-- How to apply:
--   1. Run: psql $DATABASE_URL_STAGING -f status-transition.sql
--   2. Test transitions with different user roles
-- 
-- State Machine:
--   draft → submitted (creator only)
--   submitted → under_review (org_admin only)
--   under_review → approved/rejected (approvers via approval decision)
--   approved/rejected → closed (org_admin)
-- 
-- Automatic Transitions:
--   - When all approvers approve → status becomes 'approved'
--   - When any approver rejects → status becomes 'rejected'
-- ================================================================

-- ================================================================
-- STATE MACHINE DIAGRAM
-- ================================================================

/*
  ┌───────┐
  │ draft │──────────────┐
  └───────┘              │ (creator: submit)
                         ▼
                  ┌──────────┐
                  │submitted │
                  └──────────┘
                         │ (org_admin: review)
                         ▼
                ┌──────────────┐
                │ under_review │
                └──────────────┘
                   │         │
     (approve all) │         │ (any reject)
                   ▼         ▼
              ┌─────────┐ ┌──────────┐
              │approved │ │ rejected │
              └─────────┘ └──────────┘
                   │         │
                   └────┬────┘
                        │ (org_admin: close)
                        ▼
                   ┌────────┐
                   │ closed │
                   └────────┘
*/

-- ================================================================
-- VALIDATION FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION public.validate_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  old_status public.request_status;
  new_status public.request_status;
  user_role public.app_role;
BEGIN
  old_status := OLD.status;
  new_status := NEW.status;

  -- If status unchanged, allow
  IF old_status = new_status THEN
    RETURN NEW;
  END IF;

  -- Get user's primary role for this org
  SELECT role INTO user_role
  FROM public.user_roles
  WHERE user_id = auth.uid()
    AND (org_id = NEW.org_id OR role = 'super_admin')
  ORDER BY 
    CASE role
      WHEN 'super_admin' THEN 1
      WHEN 'org_admin' THEN 2
      WHEN 'staff' THEN 3
    END
  LIMIT 1;

  -- Super admins can do anything
  IF user_role = 'super_admin' THEN
    RETURN NEW;
  END IF;

  -- Validate transitions based on roles
  CASE old_status
    WHEN 'draft' THEN
      -- draft → submitted (creator only)
      IF new_status = 'submitted' THEN
        IF OLD.created_by != auth.uid() THEN
          RAISE EXCEPTION 'Only request creator can submit draft';
        END IF;
        -- Auto-set submitted_at
        NEW.submitted_at := now();
      ELSE
        RAISE EXCEPTION 'Draft can only transition to submitted, got %', new_status;
      END IF;

    WHEN 'submitted' THEN
      -- submitted → under_review (org_admin only)
      IF new_status = 'under_review' THEN
        IF user_role != 'org_admin' THEN
          RAISE EXCEPTION 'Only org_admin can move request to under_review';
        END IF;
      ELSE
        RAISE EXCEPTION 'Submitted can only transition to under_review, got %', new_status;
      END IF;

    WHEN 'under_review' THEN
      -- under_review → approved/rejected
      -- This should happen automatically via approval trigger, not direct update
      IF new_status NOT IN ('approved', 'rejected') THEN
        RAISE EXCEPTION 'Under review can only transition to approved/rejected, got %', new_status;
      END IF;
      -- Allow if triggered by approval system
      -- (We'll check this in the approval trigger)

    WHEN 'approved', 'rejected' THEN
      -- approved/rejected → closed (org_admin)
      IF new_status = 'closed' THEN
        IF user_role != 'org_admin' THEN
          RAISE EXCEPTION 'Only org_admin can close request';
        END IF;
      ELSE
        RAISE EXCEPTION 'Approved/Rejected can only transition to closed, got %', new_status;
      END IF;

    WHEN 'closed' THEN
      -- Closed is terminal (can be reopened by admin if needed)
      IF user_role != 'org_admin' THEN
        RAISE EXCEPTION 'Only org_admin can reopen closed request';
      END IF;

    ELSE
      RAISE EXCEPTION 'Unknown status: %', old_status;
  END CASE;

  RETURN NEW;
END;
$$;

-- Attach trigger
DROP TRIGGER IF EXISTS trigger_validate_status_transition ON public.requests;
CREATE TRIGGER trigger_validate_status_transition
  BEFORE UPDATE OF status ON public.requests
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_status_transition();

-- ================================================================
-- AUTO-TRANSITION ON APPROVAL DECISION
-- ================================================================

-- When approval decision changes, check if request status should update
CREATE OR REPLACE FUNCTION public.auto_transition_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  pending_count INT;
  rejected_count INT;
  total_count INT;
BEGIN
  -- Only process if decision changed
  IF OLD.decision = NEW.decision THEN
    RETURN NEW;
  END IF;

  -- Update decided_at timestamp
  NEW.decided_at := now();

  -- Count approval states for this request
  SELECT 
    COUNT(*) FILTER (WHERE decision = 'pending'),
    COUNT(*) FILTER (WHERE decision = 'rejected'),
    COUNT(*)
  INTO pending_count, rejected_count, total_count
  FROM public.approvals
  WHERE request_id = NEW.request_id;

  -- If any rejection → set request to rejected
  IF rejected_count > 0 THEN
    UPDATE public.requests
    SET status = 'rejected'
    WHERE id = NEW.request_id
      AND status = 'under_review';
  
  -- If all approved (no pending) → set request to approved
  ELSIF pending_count = 0 AND total_count > 0 THEN
    UPDATE public.requests
    SET status = 'approved'
    WHERE id = NEW.request_id
      AND status = 'under_review';
  END IF;

  RETURN NEW;
END;
$$;

-- Attach trigger to approvals
DROP TRIGGER IF EXISTS trigger_auto_transition_on_approval ON public.approvals;
CREATE TRIGGER trigger_auto_transition_on_approval
  BEFORE UPDATE OF decision ON public.approvals
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_transition_on_approval();

-- ================================================================
-- HELPER VIEW: Request Status Summary
-- ================================================================

CREATE OR REPLACE VIEW public.request_status_summary AS
SELECT 
  r.id,
  r.status,
  r.type,
  r.created_by,
  r.submitted_at,
  COUNT(a.id) AS total_approvers,
  COUNT(a.id) FILTER (WHERE a.decision = 'approved') AS approved_count,
  COUNT(a.id) FILTER (WHERE a.decision = 'rejected') AS rejected_count,
  COUNT(a.id) FILTER (WHERE a.decision = 'pending') AS pending_count,
  CASE 
    WHEN r.status = 'under_review' AND COUNT(a.id) FILTER (WHERE a.decision = 'pending') = 0 
      THEN 'Ready for final decision'
    WHEN r.status = 'under_review' AND MIN(a.deadline) < now() 
      THEN 'Overdue approval'
    ELSE 'On track'
  END AS workflow_status
FROM public.requests r
LEFT JOIN public.approvals a ON a.request_id = r.id
GROUP BY r.id;

-- Grant access to view
GRANT SELECT ON public.request_status_summary TO authenticated;

-- ================================================================
-- TEST SCENARIOS
-- ================================================================

-- Test 1: Creator submits draft
-- UPDATE public.requests SET status = 'submitted' 
-- WHERE id = 'req33333-3333-3333-3333-333333333333'
--   AND created_by = auth.uid();
-- Expected: SUCCESS, submitted_at set

-- Test 2: Non-creator tries to submit
-- (Switch to different user first)
-- UPDATE public.requests SET status = 'submitted' 
-- WHERE id = 'req33333-3333-3333-3333-333333333333';
-- Expected: ERROR: Only request creator can submit draft

-- Test 3: Org admin moves to review
-- (As org_admin user)
-- UPDATE public.requests SET status = 'under_review'
-- WHERE id = 'req11111-1111-1111-1111-111111111111';
-- Expected: SUCCESS

-- Test 4: Staff tries to move to review
-- (As staff user)
-- UPDATE public.requests SET status = 'under_review'
-- WHERE id = 'req11111-1111-1111-1111-111111111111';
-- Expected: ERROR: Only org_admin can move request to under_review

-- Test 5: Approver approves → auto-transition
-- UPDATE public.approvals SET decision = 'approved'
-- WHERE request_id = 'req22222-2222-2222-2222-222222222222'
--   AND approver_id = auth.uid();
-- Then check: SELECT status FROM requests WHERE id = 'req22222-...';
-- Expected: status = 'approved' (if all approved)

-- Test 6: Approver rejects → auto-transition
-- UPDATE public.approvals SET decision = 'rejected'
-- WHERE request_id = 'req22222-2222-2222-2222-222222222222'
--   AND approver_id = auth.uid();
-- Then check: SELECT status FROM requests WHERE id = 'req22222-...';
-- Expected: status = 'rejected' (immediately)
