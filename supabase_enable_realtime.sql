-- ============================================================
-- BiyerBajar — Enable Realtime on chat tables
-- (notifications was already added in a previous migration)
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- Verify all realtime tables
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
