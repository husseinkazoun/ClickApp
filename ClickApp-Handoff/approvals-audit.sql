-- ================================================================
-- File: approvals-audit.sql
-- Purpose: Audit logging trigger for approval decisions
-- Target: STAGING ONLY
-- 
-- How to apply:
--   1. Run: psql $DATABASE_URL_STAGING -f approvals-audit.sql
--   2. Make approval decision and check audit_log table
-- 
-- Logs Created:
--   - approval_created (when approval assigned)
--   - approval_decided (when approver makes decision)
--   - approval_overdue (checked via scheduled job - not implemented)
-- ================================================================

-- ================================================================
-- AUDIT TRIGGER FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION public.log_approval_decision()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  request_data JSONB;
BEGIN
  -- Build metadata
  SELECT jsonb_build_object(
    'approval_id', COALESCE(NEW.id, OLD.id),
    'request_id', COALESCE(NEW.request_id, OLD.request_id),
    'approver_id', COALESCE(NEW.approver_id, OLD.approver_id),
    'decision', NEW.decision,
    'comment', NEW.comment,
    'decided_at', NEW.decided_at,
    'deadline', NEW.deadline
  ) INTO request_data;

  -- Log based on operation
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_log (
      actor_id,
      entity_type,
      entity_id,
      action,
      metadata
    ) VALUES (
      auth.uid(),
      'approval',
      NEW.id,
      'approval_created',
      request_data
    );

  ELSIF TG_OP = 'UPDATE' THEN
    -- Only log if decision changed
    IF OLD.decision != NEW.decision THEN
      INSERT INTO public.audit_log (
        actor_id,
        entity_type,
        entity_id,
        action,
        metadata
      ) VALUES (
        auth.uid(),
        'approval',
        NEW.id,
        'approval_decided',
        request_data || jsonb_build_object(
          'previous_decision', OLD.decision,
          'changed_by', auth.uid()
        )
      );
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO public.audit_log (
      actor_id,
      entity_type,
      entity_id,
      action,
      metadata
    ) VALUES (
      auth.uid(),
      'approval',
      OLD.id,
      'approval_deleted',
      jsonb_build_object(
        'approval_id', OLD.id,
        'request_id', OLD.request_id,
        'approver_id', OLD.approver_id,
        'was_decision', OLD.decision
      )
    );
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Attach trigger
DROP TRIGGER IF EXISTS trigger_log_approval_decision ON public.approvals;
CREATE TRIGGER trigger_log_approval_decision
  AFTER INSERT OR UPDATE OR DELETE ON public.approvals
  FOR EACH ROW
  EXECUTE FUNCTION public.log_approval_decision();

-- ================================================================
-- REQUEST STATUS CHANGE AUDIT
-- ================================================================

CREATE OR REPLACE FUNCTION public.log_request_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only log if status changed
  IF OLD.status != NEW.status THEN
    INSERT INTO public.audit_log (
      actor_id,
      entity_type,
      entity_id,
      action,
      metadata
    ) VALUES (
      auth.uid(),
      'request',
      NEW.id,
      'status_changed',
      jsonb_build_object(
        'from_status', OLD.status,
        'to_status', NEW.status,
        'request_type', NEW.type,
        'changed_at', now()
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Attach trigger
DROP TRIGGER IF EXISTS trigger_log_request_status_change ON public.requests;
CREATE TRIGGER trigger_log_request_status_change
  AFTER UPDATE OF status ON public.requests
  FOR EACH ROW
  EXECUTE FUNCTION public.log_request_status_change();

-- ================================================================
-- OVERDUE APPROVAL CHECKER (Run as scheduled job)
-- ================================================================

-- This function should be called by a cron job or edge function
CREATE OR REPLACE FUNCTION public.check_overdue_approvals()
RETURNS TABLE (
  approval_id UUID,
  request_id UUID,
  approver_id UUID,
  deadline TIMESTAMP WITH TIME ZONE,
  days_overdue INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    a.id AS approval_id,
    a.request_id,
    a.approver_id,
    a.deadline,
    EXTRACT(DAY FROM (now() - a.deadline))::INTEGER AS days_overdue
  FROM public.approvals a
  WHERE a.decision = 'pending'
    AND a.deadline < now()
  ORDER BY a.deadline ASC;
$$;

-- Example usage (call from edge function):
-- SELECT * FROM public.check_overdue_approvals();

-- ================================================================
-- AUDIT LOG VIEWS (for reporting)
-- ================================================================

-- View: Recent approval activity
CREATE OR REPLACE VIEW public.recent_approval_activity AS
SELECT 
  al.created_at,
  al.action,
  p.name AS actor_name,
  p.email AS actor_email,
  al.metadata->>'approval_id' AS approval_id,
  al.metadata->>'decision' AS decision,
  al.metadata->>'comment' AS comment
FROM public.audit_log al
LEFT JOIN public.profiles p ON p.id = al.actor_id
WHERE al.entity_type = 'approval'
  AND al.created_at > now() - interval '30 days'
ORDER BY al.created_at DESC;

GRANT SELECT ON public.recent_approval_activity TO authenticated;

-- View: Request status history
CREATE OR REPLACE VIEW public.request_status_history AS
SELECT 
  al.created_at,
  al.entity_id AS request_id,
  p.name AS changed_by,
  al.metadata->>'from_status' AS from_status,
  al.metadata->>'to_status' AS to_status,
  al.metadata->>'request_type' AS request_type
FROM public.audit_log al
LEFT JOIN public.profiles p ON p.id = al.actor_id
WHERE al.entity_type = 'request'
  AND al.action = 'status_changed'
ORDER BY al.created_at DESC;

GRANT SELECT ON public.request_status_history TO authenticated;

-- ================================================================
-- NOTIFICATION HELPER (for email integration)
-- ================================================================

-- Function to get pending approvals needing notification
CREATE OR REPLACE FUNCTION public.get_pending_approvals_for_notification()
RETURNS TABLE (
  approval_id UUID,
  approver_email TEXT,
  approver_name TEXT,
  request_id UUID,
  request_type public.request_type,
  deadline TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    a.id AS approval_id,
    p.email AS approver_email,
    p.name AS approver_name,
    a.request_id,
    r.type AS request_type,
    a.deadline,
    a.created_at
  FROM public.approvals a
  JOIN public.profiles p ON p.id = a.approver_id
  JOIN public.requests r ON r.id = a.request_id
  WHERE a.decision = 'pending'
    AND a.deadline > now() -- Not yet overdue
    AND a.deadline < now() + interval '3 days' -- Due soon
  ORDER BY a.deadline ASC;
$$;

-- ================================================================
-- COMPLIANCE & GDPR
-- ================================================================

-- Function to anonymize audit logs for deleted users
CREATE OR REPLACE FUNCTION public.anonymize_audit_logs_for_user(user_uuid UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.audit_log
  SET 
    actor_id = NULL,
    metadata = metadata || jsonb_build_object('anonymized', true)
  WHERE actor_id = user_uuid;
$$;

-- This should be called when a user is deleted (GDPR right to be forgotten)
-- Example: SELECT public.anonymize_audit_logs_for_user('user-uuid-here');

-- ================================================================
-- TEST SCENARIOS
-- ================================================================

-- Test 1: Create approval and check audit log
-- INSERT INTO public.approvals (request_id, approver_id, deadline)
-- VALUES ('req11111-1111-1111-1111-111111111111', auth.uid(), now() + interval '3 days');
-- Then: SELECT * FROM audit_log WHERE entity_type = 'approval' ORDER BY created_at DESC LIMIT 1;
-- Expected: action = 'approval_created'

-- Test 2: Make approval decision and check audit
-- UPDATE public.approvals SET decision = 'approved', comment = 'Looks good'
-- WHERE id = 'approval-id-here';
-- Then: SELECT * FROM audit_log WHERE action = 'approval_decided' ORDER BY created_at DESC LIMIT 1;
-- Expected: metadata contains 'previous_decision' = 'pending'

-- Test 3: Check overdue approvals
-- SELECT * FROM public.check_overdue_approvals();
-- Expected: Returns approvals past their deadline

-- Test 4: View recent activity
-- SELECT * FROM public.recent_approval_activity LIMIT 10;
-- Expected: Shows latest approval actions with actor names
