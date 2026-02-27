# Shared Notes — Backend Specification (Irids_Web)

## Background

Irids_Web is the Node.js/Express/SQLite backend for ColourNote. It uses:
- `db.js` — SQLite3 database singleton
- `routes/notes.js` — Note CRUD endpoints
- `models/noteModel.js` — Note database logic
- `scripts/migrations.js` — Versioned schema migrations
- `middleware/authMiddleware.js` — JWT verification
- Express 5.x, `jsonwebtoken`, `sqlite3`, `socket.io`

Current DB schema version: **13**. All schema changes must be added as a **migration to version 14** in `scripts/migrations.js`.

---

## 1. New Database Table: `note_shares`

Add to migration v14 in `scripts/migrations.js`:

```sql
CREATE TABLE IF NOT EXISTS note_shares (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    token TEXT UNIQUE NOT NULL,           -- URL-safe random string (32 chars), used in share URL
    owner_user_id INTEGER NOT NULL,       -- User who initiated the share
    owner_note_uuid TEXT NOT NULL,        -- UUID of the owner's note
    recipient_email TEXT,                 -- Email the share was addressed to (display hint only)
    recipient_user_id INTEGER,            -- Set when share is accepted
    recipient_note_uuid TEXT,             -- UUID of the recipient's copy (set after acceptance)
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'accepted' | 'revoked'
    created_at INTEGER NOT NULL,
    accepted_at INTEGER,
    expires_at INTEGER,                   -- Unix ms; NULL = no expiry
    FOREIGN KEY(owner_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_note_shares_token ON note_shares(token);
CREATE INDEX IF NOT EXISTS idx_note_shares_owner_uuid ON note_shares(owner_note_uuid);
CREATE INDEX IF NOT EXISTS idx_note_shares_recipient_uuid ON note_shares(recipient_note_uuid);
```

---

## 2. New API Endpoints

Add a new route file: `routes/shares.js`. Mount it in `app.js`:

```javascript
const sharesRouter = require('./routes/shares');
app.use('/', sharesRouter);
```

---

### `POST /notes/:uuid/share` — Create a share link

- **Auth**: Required (JWT)
- **Path param**: `uuid` — UUID of the note to share
- **Body**: `{ "recipientEmail": "bob@example.com" }`
- **Logic**:
  1. Verify the note with `uuid` exists and belongs to the authenticated user
  2. Generate a random 32-character URL-safe token (`crypto.randomBytes(24).toString('base64url')`)
  3. Set `expires_at` to 7 days from now (or NULL for no expiry)
  4. Insert into `note_shares`
  5. Return the share URL
- **Response 200**:
  ```json
  {
    "shareUrl": "https://irids.co.uk/share/abc123token...",
    "token": "abc123token..."
  }
  ```
- **Response 404**: Note not found or not owned by user
- **Response 400**: Note UUID missing or invalid body

---

### `GET /share/:token` — Public share acceptance page

- **Auth**: None (public)
- **Logic**:
  1. Look up `note_shares` by token
  2. If not found or status = 'revoked': serve a "Link not found or revoked" HTML page
  3. If status = 'accepted': serve "This note is already shared" page
  4. If expired (`expires_at` is set and in the past): serve "This link has expired" page
  5. Otherwise: look up the owner's note by `owner_note_uuid`; serve an HTML page showing:
     - Note title (first line of note content or `title` field)
     - "Shared by: [owner email]"
     - "Shared with: [recipient_email]" (if set)
     - A button: **"Accept — open in ColourNote"**
     - If the recipient is not logged in, prompt them to log in or register before accepting
- **Implementation**: Serve a self-contained HTML page (no frontend framework needed). Style simply. The "Accept" button POSTs to `POST /share/:token/accept`.

---

### `POST /share/:token/accept` — Accept a shared note

- **Auth**: Required — recipient must be authenticated (web session or JWT Bearer; support both)
- **Logic**:
  1. Look up `note_shares` by token
  2. Validate: status must be 'pending', not expired
  3. Validate: recipient is not the same user as the owner (prevent self-share — return 400)
  4. Fetch the owner's note by `owner_note_uuid`
  5. Create a **new note** for the recipient:
     - New UUID (generated fresh)
     - Copy `title`, `note`, `content_format`, `created_date`, `modified_date` from owner's note
     - `user_id` = recipient's user_id
     - `category_id` = NULL (recipient will assign their own category)
     - `active_state` = 0
  6. Update `note_shares`:
     - `recipient_user_id` = recipient user_id
     - `recipient_note_uuid` = new note UUID
     - `status` = 'accepted'
     - `accepted_at` = now
  7. Emit socket.io event `notes_updated` to recipient's room (if connected)
- **Response 200**:
  ```json
  { "message": "Note shared successfully", "noteUuid": "<recipient_note_uuid>" }
  ```
- **Response 400**: Already accepted, expired, or self-share
- **Response 404**: Token not found

---

### `GET /shares` — List shares for authenticated user

- **Auth**: Required
- **Logic**: Return all `note_shares` where `owner_user_id` = user OR `recipient_user_id` = user
- **Response 200**:
  ```json
  [
    {
      "id": 1,
      "token": "...",
      "ownerNoteUuid": "...",
      "recipientEmail": "bob@example.com",
      "status": "accepted",
      "createdAt": 1234567890000
    }
  ]
  ```

---

### `DELETE /shares/:id` — Revoke a share

- **Auth**: Required (owner only)
- **Logic**:
  1. Look up share by id, verify `owner_user_id` = authenticated user
  2. Set `status` = 'revoked'
  3. **Do not delete the recipient's note copy** — they keep their data
- **Response 200**: `{ "message": "Share revoked" }`

---

## 3. Server-Side Sync Propagation

When a note is updated via `PUT /notes/:id`, after the update is committed, propagate changes to any linked shared copy.

**Add to `models/noteModel.js`** (or inline in `routes/notes.js` after the PUT handler commits):

```javascript
async function propagateSharedNoteUpdate(updatedNoteUuid, title, noteContent, modifiedDate, db) {
    // Find any active share involving this note UUID (as owner OR recipient)
    const share = await db.getAsync(
        `SELECT * FROM note_shares
         WHERE (owner_note_uuid = ? OR recipient_note_uuid = ?)
         AND status = 'accepted'`,
        [updatedNoteUuid, updatedNoteUuid]
    );
    if (!share) return;

    // Determine which is the "other" copy
    const isOwner = share.owner_note_uuid === updatedNoteUuid;
    const targetUuid = isOwner ? share.recipient_note_uuid : share.owner_note_uuid;
    const targetUserId = isOwner ? share.recipient_user_id : share.owner_user_id;

    if (!targetUuid || !targetUserId) return; // share not yet accepted

    // Update the other copy — title + content + modified_date ONLY (not category_id)
    await db.runAsync(
        `UPDATE notes SET title = ?, note = ?, modified_date = ?, content_format = ?
         WHERE uuid = ? AND user_id = ?`,
        [title, noteContent, Date.now(), 'markdown', targetUuid, targetUserId]
    );

    // Emit socket.io event so the other user's app gets a sync prompt
    io.to(`user_${targetUserId}`).emit('notes_updated');
}
```

Call `propagateSharedNoteUpdate(...)` at the end of the `PUT /notes/:id` handler in `routes/notes.js`, after the note has been successfully written to the database.

**Important:** Do NOT propagate `category_id` — each user manages their own category assignment independently.

**Circular update prevention:** The propagation writes a new `modified_date = Date.now()` to the target via a direct DB write (not through the PUT endpoint), so it will not re-trigger propagation. No circular loop occurs.

---

## 4. Web Authentication for Share Acceptance Page

The `GET /share/:token` page must allow the recipient to log in or register before accepting:

1. If the recipient already has a web session (from a previous login to irids.co.uk), use it directly and show the Accept button immediately.
2. If not authenticated: show a compact login/register form inline on the share page, or redirect to `/login?redirect=/share/:token`.
3. After authentication, redirect back to `/share/:token` and auto-present the accept button.

Use `express-session` (already in the project) to persist auth state across the redirect.

---

## 5. Migration Version Bump

In `scripts/migrations.js`, add the v14 migration block following the existing pattern:

```javascript
if (currentVersion < 14) {
    db.run(`CREATE TABLE IF NOT EXISTS note_shares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT UNIQUE NOT NULL,
        owner_user_id INTEGER NOT NULL,
        owner_note_uuid TEXT NOT NULL,
        recipient_email TEXT,
        recipient_user_id INTEGER,
        recipient_note_uuid TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        accepted_at INTEGER,
        expires_at INTEGER,
        FOREIGN KEY(owner_user_id) REFERENCES users(user_id) ON DELETE CASCADE
    )`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_note_shares_token ON note_shares(token)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_note_shares_owner_uuid ON note_shares(owner_note_uuid)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_note_shares_recipient_uuid ON note_shares(recipient_note_uuid)`);
    db.run(`PRAGMA user_version = 14`);
}
```

---

## 6. Summary of File Changes

| File | Change |
|------|--------|
| `scripts/migrations.js` | Add migration v14: `note_shares` table + indexes |
| `routes/shares.js` | **New file**: `POST /notes/:uuid/share`, `GET /share/:token`, `POST /share/:token/accept`, `GET /shares`, `DELETE /shares/:id` |
| `routes/notes.js` | Call `propagateSharedNoteUpdate()` at end of `PUT /notes/:id` handler |
| `models/noteModel.js` | Add `propagateSharedNoteUpdate()` function (or inline in `routes/notes.js`) |
| `app.js` | Mount `routes/shares.js` |

---

## 7. End-to-End Test Scenario

1. **User A** swipes left on a note → taps "Share" → taps "Share access with another user"
2. Enters User B's email → taps "Share"
3. App calls `POST /notes/{uuid}/share` → receives `shareUrl`
4. iOS share sheet appears with the URL — User A sends it to User B via any means

5. **User B** taps the link → `https://irids.co.uk/share/{token}` opens in Safari
6. Sees the note title and "Accept" button — logs in if needed
7. Taps "Accept" → `POST /share/{token}/accept` → server creates note copy for User B

8. **User B** opens ColourNote, syncs → new note appears
9. User B assigns the note to a category of their choice

10. **User B** edits the note → saves → sync uploads to server → server propagates to User A's copy
11. **User A** syncs → sees User B's edits in their copy

### What to verify

- Share link works in Safari (unauthenticated and authenticated paths)
- Note copy is created correctly for recipient (correct content, NULL `category_id`)
- Edits by either user propagate to the other's copy on next sync
- Category assignments are independent for each user
- Revoking a share does not delete the recipient's note
- Expired/revoked links show appropriate error page
- Self-share (sending to own email) is rejected with a clear error
