-- ================================================================
-- File: storage-policies.sql
-- Purpose: Supabase Storage bucket and RLS policies for attachments
-- Target: STAGING ONLY (do not run on production)
-- 
-- How to apply:
--   1. Run: psql $DATABASE_URL_STAGING -f storage-policies.sql
--   2. Verify bucket: SELECT * FROM storage.buckets WHERE id = 'request-attachments';
--   3. Test upload from frontend with authenticated user
-- 
-- Bucket Structure:
--   request-attachments/
--     ├── <request_id>/
--     │   ├── <filename1>
--     │   ├── <filename2>
--     │   └── ...
-- 
-- Access Control:
--   - Upload: Request creator only (to their own request's folder)
--   - Read: Request creator + org admins + super admins
--   - Update/Delete: Not allowed (immutable after upload)
-- ================================================================

-- ================================================================
-- CREATE BUCKET
-- ================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'request-attachments',
  'request-attachments',
  false, -- Private bucket
  26214400, -- 25MB limit (in bytes)
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'text/plain',
    'text/csv'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 26214400,
  allowed_mime_types = ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'text/plain',
    'text/csv'
  ];

-- ================================================================
-- STORAGE RLS POLICIES
-- ================================================================

-- Allow users to upload files to their own request folders
CREATE POLICY "Users can upload to their own requests"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'request-attachments'
  AND auth.role() = 'authenticated'
  AND (
    -- Extract request_id from path (format: request_id/filename)
    (storage.foldername(name))[1] IN (
      SELECT id::text FROM public.requests WHERE created_by = auth.uid()
    )
  )
);

-- Allow users to read files from their own requests
CREATE POLICY "Users can read their own request files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'request-attachments'
  AND (
    -- Request creator
    (storage.foldername(name))[1] IN (
      SELECT id::text FROM public.requests WHERE created_by = auth.uid()
    )
    -- OR org admin for same org
    OR EXISTS (
      SELECT 1 FROM public.requests r
      JOIN public.profiles p ON p.id = auth.uid()
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.org_id = p.org_id
        AND public.has_role(auth.uid(), 'org_admin'::app_role)
    )
    -- OR super admin
    OR public.is_super_admin(auth.uid())
  )
);

-- Org admins can read files within their organization
CREATE POLICY "Org admins can read org request files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'request-attachments'
  AND auth.role() = 'authenticated'
  AND (
    public.has_role(auth.uid(), 'org_admin'::app_role)
    AND EXISTS (
      SELECT 1 FROM public.requests r
      JOIN public.profiles p ON p.id = auth.uid()
      WHERE r.id::text = (storage.foldername(name))[1]
        AND r.org_id = p.org_id
    )
  )
);

-- Super admins can read all files
CREATE POLICY "Super admins can read all files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'request-attachments'
  AND public.is_super_admin(auth.uid())
);

-- ================================================================
-- PREVENT UPDATE/DELETE (Immutable)
-- ================================================================

-- No policies for UPDATE or DELETE means these operations are blocked
-- Files cannot be modified or deleted after upload for audit trail purposes

-- ================================================================
-- HELPER FUNCTION FOR PATH VALIDATION
-- ================================================================

-- Function to validate request_id exists before upload
CREATE OR REPLACE FUNCTION public.validate_storage_path(path TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  request_uuid UUID;
BEGIN
  -- Extract request_id from path (first folder)
  BEGIN
    request_uuid := (regexp_match(path, '^([a-f0-9-]+)/'))[1]::UUID;
  EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
  END;
  
  -- Check if request exists and user owns it
  RETURN EXISTS (
    SELECT 1 FROM public.requests 
    WHERE id = request_uuid 
      AND created_by = auth.uid()
  );
END;
$$;

-- ================================================================
-- USAGE NOTES
-- ================================================================

-- Frontend upload example:
-- const { data, error } = await supabase.storage
--   .from('request-attachments')
--   .upload(`${requestId}/${file.name}`, file, {
--     cacheControl: '3600',
--     upsert: false
--   });

-- Frontend download example:
-- const { data } = await supabase.storage
--   .from('request-attachments')
--   .download(`${requestId}/${filename}`);

-- Get public URL (won't work since bucket is private, but generates signed URL):
-- const { data } = await supabase.storage
--   .from('request-attachments')
--   .createSignedUrl(`${requestId}/${filename}`, 3600); // 1 hour expiry

-- ================================================================
-- SECURITY CONSIDERATIONS
-- ================================================================

-- 1. Path Injection: RLS policies use foldername() to safely extract request_id
-- 2. File Size: Enforced at bucket level (25MB)
-- 3. MIME Types: Enforced at bucket level (whitelist approach)
-- 4. Virus Scanning: NOT implemented - consider Supabase Edge Function + ClamAV
-- 5. Immutability: No UPDATE/DELETE policies = audit-safe
-- 6. Org Isolation: Policies check org_id through requests table join
