================================================================================
PRODUCT REQUIREMENTS DOCUMENT (PRD)
MeetUp — Version 3.0
Focus: Meetup Scheduling Enhancements + New Core Features
Platform: Flutter | Backend: Supabase
================================================================================


1. CONFIRMED BUILT IN V1.0 (from screenshots)
--------------------------------------------------------------------------------

  Group Detail Screen:
    - Members tab: avatar, name, Admin badge, joined time — DONE
    - Meetups tab: date card, title, time, location, FAB (+) — DONE
    - Chat tab: real-time messaging, left/right bubbles, send button — DONE

  Schedule Meetup Screen:
    - Meetup Title field — DONE
    - Description field — DONE
    - Date picker (Saturday, March 28, 2026) — DONE
    - Time picker (6:00 PM) — DONE
    - Location field — DONE
    - Schedule Meetup button — DONE

  Invite Code: UDA510 chip shown on group detail — DONE


2. WHAT IS MISSING / NEEDS IMPROVEMENT
--------------------------------------------------------------------------------

  From Meetups tab screenshot:
    - "ricket" meetup on Mar 26 has no location shown (location is optional,
      but should show "No location" or a dash placeholder for consistency)
    - No RSVP count or status shown on meetup cards
    - No "Completed" label on past meetups (Mar 26 is already past)
    - Tapping a meetup card has no destination screen (Meetup Detail missing)

  From Schedule Meetup screenshot:
    - No max attendee limit field
    - No repeat/recurring option
    - No meetup category/type selector
    - No confirmation screen before saving
    - No ability to edit an existing meetup after creation

  From Chat screenshot:
    - Sender name shown above every bubble including own messages
      (own messages should NOT show sender name — only others should)
    - No date separator between messages from different days
      (messages jump from "about an hour ago" to "2 days ago" with no divider)
    - No "seen" or delivered indicator
    - Message input field is at very bottom, potentially hidden behind keyboard
      on some devices


3. NEW FEATURES FOR V2.0
--------------------------------------------------------------------------------

  FEATURE 1  : Meetup Detail Screen (missing entirely)
  FEATURE 2  : RSVP System (Going / Maybe / Not Going)
  FEATURE 3  : Schedule Meetup — Enhanced Fields
  FEATURE 4  : Edit Meetup (for creator/admin)
  FEATURE 5  : Cancel/Delete Meetup
  FEATURE 6  : Meetup Status Labels (Upcoming / Completed / Cancelled)
  FEATURE 7  : Chat UI Fixes (date separators, own name hidden)
  FEATURE 8  : Meetup Reminder (local notification only, no FCM)
  FEATURE 9  : Meetup Comments Section
  FEATURE 10 : Attendees List on Meetup Detail


4. FEATURE DETAILS
--------------------------------------------------------------------------------

FEATURE 1 — MEETUP DETAIL SCREEN
--------------------------------------------------------------------------------

Trigger: Tap any meetup card in Meetups tab OR Home screen

Screen Layout:

  App bar:
    - Back button (left)
    - Title: meetup title (e.g., "movie")
    - Edit icon (pencil) — visible only to creator or group admin (right)

  Body (scrollable):

    Section 1 — Date & Time Card:
      Large orange date badge (same style as meetup list card)
      Full date: "Monday, March 31, 2026"
      Time: "12:10 PM"

    Section 2 — Info Rows:
      📍 Location: "rtc x road"   (show "No location set" if empty)
      👤 Organized by: "shiva"
      👥 Group: "cricket"
      📝 Description: show description text
                      (hide this row entirely if no description)

    Section 3 — RSVP (Are you going?):
      Title: "Are you going?"
      Three pill buttons in a row:
        ✅ Going    🤔 Maybe    ❌ Can't Go
      Active selection highlighted in orange, others grey outline
      Below buttons: RSVP summary counts
        "3 Going  ·  1 Maybe  ·  1 Can't Go"
      User's current RSVP pre-selected if they already RSVP'd

    Section 4 — Attendees:
      Title: "Going (3)"
      Horizontal scrollable row of avatar circles with names below
      If no one has RSVP'd: "No responses yet"

    Section 5 — Comments:
      Title: "Comments (2)"
      List of comment items:
        Avatar (small) + name (bold) + comment text + timestamp
      "Add a comment..." input bar pinned at bottom
      Send button (arrow icon)

  Bottom section (destructive, only for creator/admin):
    "Cancel Meetup" in red text
    Confirmation dialog before cancelling


FEATURE 2 — RSVP SYSTEM
--------------------------------------------------------------------------------

Database table: meetup_rsvps
  - id          UUID PK
  - meetup_id   UUID FK → meetups.id
  - user_id     UUID FK → profiles.id
  - status      TEXT CHECK IN ('going', 'maybe', 'not_going')
  - updated_at  TIMESTAMP DEFAULT now()
  - UNIQUE (meetup_id, user_id)

RLS Policies:
  - SELECT: group members can view RSVPs for meetups in their groups
  - INSERT: authenticated user, only their own row
  - UPDATE: user can update only their own RSVP
  - DELETE: user can delete their own RSVP

Supabase SQL to create table:
  CREATE TABLE meetup_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meetup_id UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('going','maybe','not_going')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (meetup_id, user_id)
  );

Behavior:
  - Tapping a button does an UPSERT (insert or update on conflict)
  - Tapping the already-active button removes the RSVP (toggle off)
  - RSVP count on meetup card in list updates immediately
  - Home screen card shows small RSVP badge:
      Green dot + "Going" if user selected Going
      Yellow dot + "Maybe" if user selected Maybe
      Red dot + "Can't Go" if user selected Not Going
      Grey dot + "No response" if user has not RSVP'd


FEATURE 3 — SCHEDULE MEETUP ENHANCED FIELDS
--------------------------------------------------------------------------------

Current fields (already built):
  - Meetup Title
  - Description
  - Date
  - Time
  - Location

NEW fields to add:

  3a. MAX ATTENDEES (optional)
      Label: "Max Attendees (optional)"
      Input type: number field
      Placeholder: "e.g., 10  —  leave blank for unlimited"
      If max is set and RSVP 'Going' count reaches max:
        - New users trying to RSVP 'Going' see:
          "This meetup is full! You can still mark Maybe."
        - Going button disabled, Maybe and Can't Go still enabled
      Stored as: meetups.max_attendees INTEGER (nullable)

  3b. MEETUP CATEGORY
      Label: "Category"
      UI: Horizontal scrollable chip selector (tap to select one)
      Options:
        🏏 Sports
        🎬 Movie
        🍽️ Food & Dining
        🎮 Gaming
        📚 Study
        🎵 Music
        🏕️ Outdoor
        🎉 Party
        💼 Work
        🔧 Other
      Stored as: meetups.category TEXT (nullable)
      Used for: filtering on home screen (future), visual icon on card

  3c. MEETUP VISIBILITY
      Label: "Who can see this meetup?"
      UI: Toggle/radio selector
      Options:
        🔒 Group Members Only (default)
        🌐 Public (anyone with the link can view — V3.1 feature, show grayed out)
      Stored as: meetups.is_public BOOLEAN DEFAULT false

  3d. CONFIRMATION SCREEN BEFORE SAVING
      After user taps "Schedule Meetup":
        Show a review bottom sheet (modal) before saving
        Title: "Confirm Meetup Details"
        Shows:
          Title, Date, Time, Location, Category, Max Attendees
        Two buttons:
          "Edit" — dismisses sheet, returns to form
          "Confirm & Schedule" — saves to Supabase and navigates back

  Updated meetups table columns to add:
    ALTER TABLE meetups ADD COLUMN max_attendees INTEGER;
    ALTER TABLE meetups ADD COLUMN category TEXT;
    ALTER TABLE meetups ADD COLUMN is_public BOOLEAN DEFAULT false;


FEATURE 4 — EDIT MEETUP
--------------------------------------------------------------------------------

Trigger: Tap pencil icon on Meetup Detail screen (creator/admin only)

Screen: Same as Schedule Meetup screen but pre-filled with existing data

Behavior:
  - All fields editable
  - Date cannot be set to a past date
  - "Save Changes" button instead of "Schedule Meetup"
  - On save: updates Supabase meetups row
  - All group members see updated details immediately on their screens
  - Show snackbar: "Meetup updated successfully"

Access Control:
  - Only the meetup creator (created_by) or group admin can see edit icon
  - Other members see no edit option


FEATURE 5 — CANCEL / DELETE MEETUP
--------------------------------------------------------------------------------

Trigger: "Cancel Meetup" red text button at bottom of Meetup Detail screen
         (visible only to creator or group admin)

Flow:
  Step 1: Tap "Cancel Meetup"
  Step 2: Confirmation dialog appears:
    Title: "Cancel this meetup?"
    Body: "This will notify all members and remove the meetup
           from everyone's schedule."
    Buttons:
      "Keep Meetup" (secondary, dismisses dialog)
      "Yes, Cancel It" (destructive, red)
  Step 3: On confirm:
    - meetups.status set to 'cancelled' (do NOT delete the row)
    - Meetup card shows "Cancelled" badge in red
    - Meetup removed from Home screen upcoming list
    - Meetup still visible in Group Meetups tab with Cancelled label

  Meetups table status column:
    ALTER TABLE meetups ADD COLUMN status TEXT DEFAULT 'upcoming'
    CHECK (status IN ('upcoming', 'completed', 'cancelled'));


FEATURE 6 — MEETUP STATUS LABELS ON CARDS
--------------------------------------------------------------------------------

Current state:
  - Meetups tab shows cards with date, title, time, location only
  - No visual difference between upcoming and past meetups

Required changes:

  Card label badge (top-right corner of each meetup card):
    - "Upcoming" — green badge — for meetups in the future
    - "Today" — orange badge — for meetups happening today
    - "Completed" — grey badge — for meetups whose date has passed
    - "Cancelled" — red badge — for cancelled meetups

  Sort order in Meetups tab:
    1. Today's meetups (top)
    2. Upcoming future meetups (sorted ascending by date)
    3. Completed past meetups (sorted descending by date, grayed out)
    4. Cancelled meetups (bottom, grayed out, collapsed by default)

  Home screen:
    - Only show Upcoming and Today meetups
    - Never show Completed or Cancelled on Home screen

  RSVP count summary on meetup card (small, below time/location):
    "3 Going · 1 Maybe"  — show only if at least 1 RSVP exists


FEATURE 7 — CHAT UI FIXES
--------------------------------------------------------------------------------

Issue 1 — Own sender name shown above own messages:
  Fix: Never show sender name or avatar above/beside own messages
  Own messages: just the bubble (dark/black) + timestamp below
  Other messages: avatar (left) + name above bubble + timestamp below

Issue 2 — No date separator between messages:
  Fix: Insert a centered date separator row between message groups
  from different calendar days
  Format:
    ─────── Today ───────
    ─────── Yesterday ───────
    ─────── Mar 25, 2026 ───────
  Logic: Compare each message's date to previous message's date,
         insert separator when date changes

Issue 3 — Keyboard covering input field:
  Fix: Wrap chat screen in a widget that respects
       MediaQuery.of(context).viewInsets.bottom
       Or use resizeToAvoidBottomInset: true on the Scaffold
       Input bar must always be visible above the keyboard

Issue 4 — Message timestamps:
  Current: "about an hour ago", "2 days ago" (relative, correct)
  Improvement: Show exact time on long-press of a message
    e.g., long-press → tooltip shows "March 25, 2026 at 3:45 PM"


FEATURE 8 — LOCAL MEETUP REMINDER (no FCM needed)
--------------------------------------------------------------------------------

Implementation: Flutter local_notifications package only
No Firebase, no server-side code needed

Behavior:
  - When user schedules or RSVPs 'Going' to a meetup:
    Schedule a local notification for 1 hour before meetup time
  - Notification appears even if app is in background
  - Notification content:
    Title: "Meetup in 1 hour!"
    Body: "movie at rtc x road starts at 12:10 PM. Don't be late!"
  - Tapping notification → opens Meetup Detail screen (deep link)
  - If user cancels RSVP: cancel the local notification
  - If meetup is cancelled: cancel the local notification

Package to add:
  flutter_local_notifications: ^17.0.0

Permissions needed:
  Android: POST_NOTIFICATIONS (Android 13+)
  iOS: requestPermission for alerts and sounds


FEATURE 9 — MEETUP COMMENTS
--------------------------------------------------------------------------------

Location: Meetup Detail Screen, below Attendees section

Database table: meetup_comments
  CREATE TABLE meetup_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meetup_id UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
  );

RLS Policies:
  - SELECT: group members can view comments for meetups in their groups
  - INSERT: group members can add comments
  - DELETE: user can delete their own comments only

UI:
  Comment item layout:
    - Small avatar (circle, initials fallback) — left
    - Name (bold, orange) — top
    - Comment text — below name
    - Timestamp (relative, e.g., "3 hours ago") — bottom right
  Input bar pinned above keyboard:
    - "Add a comment..." placeholder
    - Send button (arrow)
  Empty state: "No comments yet. Start the conversation!"
  Real-time: subscribe to INSERT on meetup_comments
             filtered by meetup_id via Supabase Realtime

Moderation:
  - Long-press own comment → "Delete Comment" option
  - Admin can delete any comment (long-press → "Delete")


FEATURE 10 — ATTENDEES LIST ON MEETUP DETAIL
--------------------------------------------------------------------------------

Location: Meetup Detail Screen, below RSVP buttons

Layout:
  Three collapsible sections (tap header to expand/collapse):

  ✅ Going (3)
    → Horizontal scroll of avatar + name chips
    → Or vertical list if more than 5

  🤔 Maybe (1)
    → Same layout as Going

  ❌ Can't Go (1)
    → Same layout, names shown in grey text

  If all sections empty: "Be the first to respond!"

  Total attendee count shown in meetup card on list:
    Small text below time: "3 going"


5. DATABASE CHANGES SUMMARY FOR V2.0
--------------------------------------------------------------------------------

Run these SQL statements in Supabase SQL Editor:

  -- Add new columns to meetups
  ALTER TABLE meetups ADD COLUMN IF NOT EXISTS
    status TEXT DEFAULT 'upcoming'
    CHECK (status IN ('upcoming','completed','cancelled'));

  ALTER TABLE meetups ADD COLUMN IF NOT EXISTS
    max_attendees INTEGER;

  ALTER TABLE meetups ADD COLUMN IF NOT EXISTS
    category TEXT;

  ALTER TABLE meetups ADD COLUMN IF NOT EXISTS
    is_public BOOLEAN DEFAULT false;

  -- RSVP table
  CREATE TABLE IF NOT EXISTS meetup_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meetup_id UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('going','maybe','not_going')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (meetup_id, user_id)
  );

  -- Comments table
  CREATE TABLE IF NOT EXISTS meetup_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meetup_id UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
  );

  -- Enable RLS on new tables
  ALTER TABLE meetup_rsvps ENABLE ROW LEVEL SECURITY;
  ALTER TABLE meetup_comments ENABLE ROW LEVEL SECURITY;

  -- RLS for meetup_rsvps
  CREATE POLICY "rsvp_select" ON meetup_rsvps
    FOR SELECT USING (user_id = auth.uid());

  CREATE POLICY "rsvp_insert" ON meetup_rsvps
    FOR INSERT WITH CHECK (user_id = auth.uid());

  CREATE POLICY "rsvp_update" ON meetup_rsvps
    FOR UPDATE USING (user_id = auth.uid());

  CREATE POLICY "rsvp_delete" ON meetup_rsvps
    FOR DELETE USING (user_id = auth.uid());

  -- RLS for meetup_comments
  CREATE POLICY "comments_select" ON meetup_comments
    FOR SELECT USING (
      meetup_id IN (
        SELECT m.id FROM meetups m
        WHERE m.group_id IN (
          SELECT group_id FROM group_members
          WHERE user_id = auth.uid()
        )
      )
    );

  CREATE POLICY "comments_insert" ON meetup_comments
    FOR INSERT WITH CHECK (user_id = auth.uid());

  CREATE POLICY "comments_delete" ON meetup_comments
    FOR DELETE USING (user_id = auth.uid());


6. FLUTTER FILES TO CREATE OR MODIFY
--------------------------------------------------------------------------------

  CREATE (new screens):
    screens/meetups/meetup_detail_screen.dart
    widgets/rsvp_buttons_widget.dart
    widgets/attendees_section_widget.dart
    widgets/meetup_comments_widget.dart
    widgets/meetup_status_badge.dart
    widgets/meetup_confirm_sheet.dart   (confirmation bottom sheet)

  MODIFY (existing screens):
    screens/meetups/schedule_meetup_screen.dart
      → Add category chip selector
      → Add max attendees field
      → Add confirmation bottom sheet before save

    screens/groups/group_detail_screen.dart
      → Meetups tab: add status badge on cards
      → Meetups tab: add RSVP count summary on cards
      → Chat tab: fix own name shown, add date separators

    screens/home/home_screen.dart
      → Meetup cards: show RSVP badge
      → Filter to show only upcoming/today meetups


7. NEW PACKAGES TO ADD
--------------------------------------------------------------------------------

  flutter_local_notifications: ^17.0.0
    (local meetup reminders — no FCM needed)

  timezone: ^0.9.0
    (required by flutter_local_notifications for scheduled notifications)


8. IMPLEMENTATION PRIORITY FOR V2.0
--------------------------------------------------------------------------------

  WEEK 1:
    - Meetup Detail Screen (full layout)
    - RSVP buttons (Going / Maybe / Can't Go)
    - meetup_rsvps table + RLS

  WEEK 2:
    - Schedule Meetup: category chip selector
    - Schedule Meetup: max attendees field
    - Schedule Meetup: confirmation bottom sheet
    - Edit Meetup screen

  WEEK 3:
    - Cancel Meetup flow
    - Status badges on meetup cards (Upcoming/Today/Completed/Cancelled)
    - Attendees section on detail screen

  WEEK 4:
    - Chat UI fixes (date separators, hide own name)
    - Meetup comments (table + UI + realtime)
    - Local notification reminders

  WEEK 5:
    - Testing, edge cases, polish
    - Empty states on all new screens
    - Error handling (network errors, validation)


9. DESIGN RULES TO FOLLOW (CONSISTENT WITH EXISTING APP)
--------------------------------------------------------------------------------

  - Background: warm peach/cream gradient — keep on all new screens
  - Category chips: white background, orange border when selected,
                    grey border when unselected, rounded pill shape
  - Status badges: small rounded pill, color-coded:
      Today → orange (#E8845A)
      Upcoming → green (#4CAF50)
      Completed → grey (#9E9E9E)
      Cancelled → red (#F44336)
  - RSVP buttons: pill style, orange fill for active,
                  white with orange border for inactive
  - Confirmation bottom sheet: white background, rounded top corners,
                               drag handle at top
  - All new cards follow same shadow + radius style as existing cards
  - Input bars in comments + chat: same rounded style as existing inputs




================================================================================
END OF DOCUMENT — V2.0
================================================================================