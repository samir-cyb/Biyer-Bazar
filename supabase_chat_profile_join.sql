-- ============================================================
-- BiyerBajar — Verify chat_conversations FK names for profile join
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- Check the actual FK constraint names on chat_conversations
SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name  AS foreign_table,
  ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'chat_conversations'
ORDER BY kcu.column_name;
