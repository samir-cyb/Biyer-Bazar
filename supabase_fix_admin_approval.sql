-- ============================================================
-- BiyerBajar — Fix admin approval + add notifications
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Allow admins to UPDATE vendor_profiles ─────────────────────────────────
-- Without this, the approve/reject buttons fail silently due to RLS.

DROP POLICY IF EXISTS "admin_vendor_profiles_update" ON vendor_profiles;

CREATE POLICY "admin_vendor_profiles_update" ON vendor_profiles
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Also allow admins to read all vendor_profiles
DROP POLICY IF EXISTS "admin_vendor_profiles_select" ON vendor_profiles;

CREATE POLICY "admin_vendor_profiles_select" ON vendor_profiles
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── 2. Create notifications table ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  type        TEXT        NOT NULL DEFAULT 'info'
                CHECK (type IN ('info', 'success', 'warning', 'approval', 'rejection', 'booking', 'chat')),
  is_read     BOOLEAN     DEFAULT FALSE,
  data        JSONB       DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user    ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON notifications(user_id, is_read);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own notifications
CREATE POLICY "notifications_select" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Admins can insert notifications for any user
CREATE POLICY "notifications_insert" ON notifications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
    OR auth.uid() = user_id
  );

-- Enable realtime for live notification badge
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ── 3. Reload schema cache ─────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ── Verify ────────────────────────────────────────────────────────────────────
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('vendor_profiles', 'notifications')
ORDER BY tablename, policyname;
