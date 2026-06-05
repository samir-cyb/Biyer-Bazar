-- ============================================================
-- BiyerBajar — Supabase Migration v2
-- New features: vendor profiles v2, in-app chat, bookings, payments
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- ── 1. UPDATE vendor_profiles — add new columns ───────────────────────────────

ALTER TABLE vendor_profiles
  ADD COLUMN IF NOT EXISTS approval_status    TEXT    NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS rejection_reason   TEXT,
  ADD COLUMN IF NOT EXISTS capacity           INTEGER,          -- for venues
  ADD COLUMN IF NOT EXISTS address            TEXT,
  ADD COLUMN IF NOT EXISTS specialty_tags     TEXT[]  DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS cover_photo_url    TEXT,
  ADD COLUMN IF NOT EXISTS slug               TEXT    UNIQUE,   -- for public profile URL
  ADD COLUMN IF NOT EXISTS approved_at        TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS approved_by        UUID REFERENCES profiles(id);

-- Vendors that were already verified get auto-approved
UPDATE vendor_profiles SET approval_status = 'approved' WHERE is_verified = TRUE;

-- ── 2. vendor_packages — service packages with pricing ────────────────────────

CREATE TABLE IF NOT EXISTS vendor_packages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name            TEXT        NOT NULL,
  description     TEXT,
  price           INTEGER     NOT NULL,   -- BDT
  price_type      TEXT        NOT NULL DEFAULT 'fixed'
                    CHECK (price_type IN ('fixed', 'per_head', 'per_day', 'negotiable')),
  includes        JSONB       DEFAULT '[]',   -- array of included items
  is_popular      BOOLEAN     DEFAULT FALSE,
  is_active       BOOLEAN     DEFAULT TRUE,
  sort_order      INTEGER     DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. vendor_menus — meal planning (for catering category) ───────────────────

CREATE TABLE IF NOT EXISTS vendor_menus (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  menu_name       TEXT        NOT NULL,
  meal_type       TEXT        NOT NULL DEFAULT 'all'
                    CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snacks', 'all')),
  items           JSONB       DEFAULT '[]',   -- [{name, description, is_veg}]
  per_head_price  INTEGER,
  min_guests      INTEGER     DEFAULT 0,
  max_guests      INTEGER,
  is_active       BOOLEAN     DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. vendor_discounts — discounts & special offers ─────────────────────────

CREATE TABLE IF NOT EXISTS vendor_discounts (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT        NOT NULL,
  description     TEXT,
  discount_type   TEXT        NOT NULL DEFAULT 'percentage'
                    CHECK (discount_type IN ('percentage', 'flat')),
  discount_value  INTEGER     NOT NULL,   -- % or BDT amount
  min_booking_amt INTEGER     DEFAULT 0,
  valid_from      DATE,
  valid_until     DATE,
  is_active       BOOLEAN     DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. chat_conversations — one per host-vendor pair ─────────────────────────

CREATE TABLE IF NOT EXISTS chat_conversations (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id               UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vendor_id             UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  booking_id            UUID,       -- linked booking (nullable, FK added after bookings table)
  last_message_at       TIMESTAMPTZ DEFAULT NOW(),
  last_message_preview  TEXT,
  host_unread_count     INTEGER     DEFAULT 0,
  vendor_unread_count   INTEGER     DEFAULT 0,
  is_archived           BOOLEAN     DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (host_id, vendor_id)       -- one conversation per pair
);

-- ── 6. chat_messages ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_messages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID        NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  sender_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content         TEXT        NOT NULL,
  is_flagged      BOOLEAN     DEFAULT FALSE,   -- auto-flagged for links/phones
  flag_reason     TEXT,                        -- 'link' | 'phone' | 'manual'
  is_deleted      BOOLEAN     DEFAULT FALSE,
  is_read         BOOLEAN     DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. bookings ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bookings (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id             UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vendor_id           UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  package_id          UUID        REFERENCES vendor_packages(id) ON DELETE SET NULL,
  conversation_id     UUID        REFERENCES chat_conversations(id) ON DELETE SET NULL,
  event_date          DATE        NOT NULL,
  service_category    TEXT        NOT NULL,
  agreed_amount       INTEGER     NOT NULL,   -- BDT
  status              TEXT        NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
  notes               TEXT,
  host_confirmed      BOOLEAN     DEFAULT FALSE,
  vendor_confirmed    BOOLEAN     DEFAULT FALSE,
  cancellation_reason TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK from chat_conversations to bookings now that bookings table exists
ALTER TABLE chat_conversations
  ADD CONSTRAINT fk_chat_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;

-- ── 8. booking_payments ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS booking_payments (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      UUID        NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  total_amount    INTEGER     NOT NULL,
  paid_amount     INTEGER     DEFAULT 0,
  payment_method  TEXT        DEFAULT 'pending'
                    CHECK (payment_method IN ('cash', 'bkash', 'nagad', 'rocket', 'bank', 'other', 'pending')),
  status          TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'partial', 'paid', 'refunded')),
  transaction_ref TEXT,
  notes           TEXT,
  paid_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. INDEXES for performance ────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_vendor_packages_vendor     ON vendor_packages(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_menus_vendor        ON vendor_menus(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_discounts_vendor    ON vendor_discounts(vendor_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_host             ON chat_conversations(host_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_vendor           ON chat_conversations(vendor_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conv         ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created      ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_host              ON bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_vendor            ON bookings(vendor_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status            ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_vendor_approval            ON vendor_profiles(approval_status);

-- ── 10. ROW LEVEL SECURITY ────────────────────────────────────────────────────

ALTER TABLE vendor_packages       ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_menus          ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_discounts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages         ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_payments      ENABLE ROW LEVEL SECURITY;

-- vendor_packages: vendor can manage own, everyone can read active ones
CREATE POLICY "vendor_packages_select" ON vendor_packages
  FOR SELECT USING (is_active = TRUE OR auth.uid() = vendor_id);
CREATE POLICY "vendor_packages_manage" ON vendor_packages
  FOR ALL USING (auth.uid() = vendor_id);

-- vendor_menus: same as packages
CREATE POLICY "vendor_menus_select" ON vendor_menus
  FOR SELECT USING (is_active = TRUE OR auth.uid() = vendor_id);
CREATE POLICY "vendor_menus_manage" ON vendor_menus
  FOR ALL USING (auth.uid() = vendor_id);

-- vendor_discounts: same pattern
CREATE POLICY "vendor_discounts_select" ON vendor_discounts
  FOR SELECT USING (is_active = TRUE OR auth.uid() = vendor_id);
CREATE POLICY "vendor_discounts_manage" ON vendor_discounts
  FOR ALL USING (auth.uid() = vendor_id);

-- chat_conversations: only participants + admins can see
CREATE POLICY "chat_conv_participant_select" ON chat_conversations
  FOR SELECT USING (
    auth.uid() = host_id
    OR auth.uid() = vendor_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
CREATE POLICY "chat_conv_host_create" ON chat_conversations
  FOR INSERT WITH CHECK (auth.uid() = host_id);
CREATE POLICY "chat_conv_participant_update" ON chat_conversations
  FOR UPDATE USING (auth.uid() = host_id OR auth.uid() = vendor_id);

-- chat_messages: participants + admins can read; participants can insert
CREATE POLICY "chat_msg_select" ON chat_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_conversations cc
      WHERE cc.id = conversation_id
        AND (cc.host_id = auth.uid() OR cc.vendor_id = auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );
CREATE POLICY "chat_msg_insert" ON chat_messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM chat_conversations cc
      WHERE cc.id = conversation_id
        AND (cc.host_id = auth.uid() OR cc.vendor_id = auth.uid())
    )
  );
CREATE POLICY "chat_msg_update_read" ON chat_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM chat_conversations cc
      WHERE cc.id = conversation_id
        AND (cc.host_id = auth.uid() OR cc.vendor_id = auth.uid())
    )
  );

-- bookings: host and vendor see own bookings
CREATE POLICY "bookings_select" ON bookings
  FOR SELECT USING (
    auth.uid() = host_id
    OR auth.uid() = vendor_id
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "bookings_host_create" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = host_id);
CREATE POLICY "bookings_update" ON bookings
  FOR UPDATE USING (
    auth.uid() = host_id
    OR auth.uid() = vendor_id
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- booking_payments: follow booking access
CREATE POLICY "payments_select" ON booking_payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.id = booking_id
        AND (b.host_id = auth.uid() OR b.vendor_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "payments_manage" ON booking_payments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.id = booking_id
        AND (b.host_id = auth.uid() OR b.vendor_id = auth.uid())
    )
  );

-- ── 11. REALTIME — enable on chat tables ──────────────────────────────────────
-- Run these via Supabase Dashboard → Database → Replication → Tables
-- or via the API if you prefer.
-- ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;
-- ALTER PUBLICATION supabase_realtime ADD TABLE bookings;

-- ── 12. STORAGE BUCKET — vendor covers ───────────────────────────────────────
-- Run in Storage section of Supabase dashboard, or via:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('vendor-covers', 'vendor-covers', true)
-- ON CONFLICT DO NOTHING;

-- ── Done ─────────────────────────────────────────────────────────────────────
-- Tables created: vendor_packages, vendor_menus, vendor_discounts,
--                 chat_conversations, chat_messages, bookings, booking_payments
-- vendor_profiles updated with: approval_status, rejection_reason, capacity,
--                                address, specialty_tags, cover_photo_url, slug
