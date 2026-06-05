-- ============================================================
-- BiyerBajar — Add missing columns to vendor_profiles
-- Run in Supabase Dashboard → SQL Editor
-- Safe to run multiple times (IF NOT EXISTS)
-- ============================================================

ALTER TABLE vendor_profiles
  ADD COLUMN IF NOT EXISTS price_range_min  INTEGER,
  ADD COLUMN IF NOT EXISTS price_range_max  INTEGER,
  ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0;

-- Force PostgREST to reload its schema cache immediately
NOTIFY pgrst, 'reload schema';

-- Confirm the columns now exist
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'vendor_profiles'
  AND column_name  IN ('price_range_min', 'price_range_max', 'years_experience')
ORDER BY column_name;
