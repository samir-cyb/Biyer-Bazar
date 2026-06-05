-- ============================================================
-- BiyerBajar — Database Health Check v2
-- Run in Supabase Dashboard → SQL Editor
-- Each section prints a result. Look for any ❌ rows.
-- ============================================================

-- ── 1. TABLE EXISTS CHECK ─────────────────────────────────────────────────────
-- Verifies all 7 new tables were created successfully.

SELECT
  t.table_name,
  CASE WHEN t.table_name IS NOT NULL THEN '✅ Exists' ELSE '❌ Missing' END AS status
FROM (
  VALUES
    ('profiles'),
    ('vendor_profiles'),
    ('event_posts'),
    ('bids'),
    ('reviews'),
    ('budget_plans'),
    ('vendor_packages'),
    ('vendor_menus'),
    ('vendor_discounts'),
    ('chat_conversations'),
    ('chat_messages'),
    ('bookings'),
    ('booking_payments')
) AS expected(table_name)
LEFT JOIN information_schema.tables t
  ON t.table_name = expected.table_name
  AND t.table_schema = 'public'
ORDER BY expected.table_name;


-- ── 2. COLUMN EXISTS CHECK on vendor_profiles ─────────────────────────────────
-- Verifies the 7 new columns were added to vendor_profiles.

SELECT
  col AS expected_column,
  CASE WHEN c.column_name IS NOT NULL THEN '✅ Exists' ELSE '❌ Missing' END AS status
FROM (
  VALUES
    ('approval_status'),
    ('rejection_reason'),
    ('capacity'),
    ('address'),
    ('specialty_tags'),
    ('cover_photo_url'),
    ('slug'),
    ('approved_at'),
    ('approved_by')
) AS expected(col)
LEFT JOIN information_schema.columns c
  ON c.table_name = 'vendor_profiles'
  AND c.table_schema = 'public'
  AND c.column_name = expected.col
ORDER BY expected.col;


-- ── 3. ROW LEVEL SECURITY ENABLED CHECK ──────────────────────────────────────
-- All new tables must have RLS enabled.

SELECT
  tablename,
  CASE WHEN rowsecurity THEN '✅ RLS On' ELSE '❌ RLS OFF — fix this!' END AS rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'vendor_packages', 'vendor_menus', 'vendor_discounts',
    'chat_conversations', 'chat_messages',
    'bookings', 'booking_payments'
  )
ORDER BY tablename;


-- ── 4. POLICY COUNT PER TABLE ─────────────────────────────────────────────────
-- Each new table should have at least 1 policy.

SELECT
  tablename,
  COUNT(*) AS policy_count,
  CASE WHEN COUNT(*) > 0 THEN '✅ Has policies' ELSE '❌ No policies!' END AS status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'vendor_packages', 'vendor_menus', 'vendor_discounts',
    'chat_conversations', 'chat_messages',
    'bookings', 'booking_payments'
  )
GROUP BY tablename
ORDER BY tablename;


-- ── 5. INDEX CHECK ────────────────────────────────────────────────────────────
-- Verifies performance indexes were created.

SELECT
  idx AS expected_index,
  CASE WHEN i.indexname IS NOT NULL THEN '✅ Exists' ELSE '❌ Missing' END AS status
FROM (
  VALUES
    ('idx_vendor_packages_vendor'),
    ('idx_vendor_menus_vendor'),
    ('idx_vendor_discounts_vendor'),
    ('idx_chat_conv_host'),
    ('idx_chat_conv_vendor'),
    ('idx_chat_messages_conv'),
    ('idx_chat_messages_created'),
    ('idx_bookings_host'),
    ('idx_bookings_vendor'),
    ('idx_bookings_status'),
    ('idx_vendor_approval')
) AS expected(idx)
LEFT JOIN pg_indexes i
  ON i.indexname = expected.idx
  AND i.schemaname = 'public'
ORDER BY expected.idx;


-- ── 6. ROW COUNTS ─────────────────────────────────────────────────────────────
-- Shows how many rows are in each table (good sanity check).

SELECT 'profiles'           AS tbl, COUNT(*) AS rows FROM profiles
UNION ALL
SELECT 'vendor_profiles',          COUNT(*) FROM vendor_profiles
UNION ALL
SELECT 'event_posts',              COUNT(*) FROM event_posts
UNION ALL
SELECT 'bids',                     COUNT(*) FROM bids
UNION ALL
SELECT 'vendor_packages',          COUNT(*) FROM vendor_packages
UNION ALL
SELECT 'vendor_menus',             COUNT(*) FROM vendor_menus
UNION ALL
SELECT 'vendor_discounts',         COUNT(*) FROM vendor_discounts
UNION ALL
SELECT 'chat_conversations',       COUNT(*) FROM chat_conversations
UNION ALL
SELECT 'chat_messages',            COUNT(*) FROM chat_messages
UNION ALL
SELECT 'bookings',                 COUNT(*) FROM bookings
UNION ALL
SELECT 'booking_payments',         COUNT(*) FROM booking_payments
ORDER BY tbl;


-- ── 7. VENDOR APPROVAL STATUS BREAKDOWN ──────────────────────────────────────
-- Shows how many vendors are pending / approved / rejected.

SELECT
  COALESCE(approval_status, 'unknown') AS status,
  COUNT(*) AS vendor_count
FROM vendor_profiles
GROUP BY approval_status
ORDER BY status;


-- ── 8. FOREIGN KEY CONSTRAINT CHECK ──────────────────────────────────────────
-- Verifies the circular FK between chat_conversations ↔ bookings was added.

SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name  AS foreign_table,
  ccu.column_name AS foreign_column,
  '✅ FK exists' AS status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN (
    'vendor_packages', 'vendor_menus', 'vendor_discounts',
    'chat_conversations', 'chat_messages',
    'bookings', 'booking_payments'
  )
ORDER BY tc.table_name, kcu.column_name;


-- ── 9. FLAGGED MESSAGES COUNT ─────────────────────────────────────────────────
-- Should be 0 if no one has tested yet. Non-zero means the filter is working.

SELECT
  COUNT(*) AS total_messages,
  SUM(CASE WHEN is_flagged THEN 1 ELSE 0 END) AS flagged_messages,
  SUM(CASE WHEN is_deleted THEN 1 ELSE 0 END) AS deleted_messages
FROM chat_messages;


-- ── 10. QUICK SUMMARY ─────────────────────────────────────────────────────────
-- One-line pass/fail for the most critical checks.

SELECT
  (SELECT COUNT(*) FROM information_schema.tables
   WHERE table_schema = 'public'
     AND table_name IN ('vendor_packages','vendor_menus','vendor_discounts',
                        'chat_conversations','chat_messages','bookings','booking_payments')
  ) AS new_tables_found,
  7 AS new_tables_expected,
  CASE
    WHEN (SELECT COUNT(*) FROM information_schema.tables
          WHERE table_schema = 'public'
            AND table_name IN ('vendor_packages','vendor_menus','vendor_discounts',
                               'chat_conversations','chat_messages','bookings','booking_payments')
         ) = 7
    THEN '✅ All 7 tables present — migration looks good!'
    ELSE '❌ Some tables are missing — re-run supabase_migration_v2.sql'
  END AS verdict;
