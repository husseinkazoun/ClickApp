-- ================================================================
-- File: rate-limit.sql
-- Purpose: Rate limiting infrastructure (stub - not enforced)
-- Target: STAGING ONLY
-- 
-- Table already exists in schema.sql
-- This adds the check function
-- ================================================================

CREATE OR REPLACE FUNCTION public.check_rate_limit(
  _user_id UUID,
  _action TEXT,
  _limit INT,
  _window_minutes INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  action_count INT;
BEGIN
  -- Count actions in time window
  SELECT COUNT(*) INTO action_count
  FROM public.rate_limits
  WHERE user_id = _user_id
    AND action = _action
    AND created_at > now() - (_window_minutes || ' minutes')::INTERVAL;
  
  -- Return true if under limit
  RETURN action_count < _limit;
END;
$$;

-- Usage: SELECT public.check_rate_limit(auth.uid(), 'submit_request', 10, 60);
