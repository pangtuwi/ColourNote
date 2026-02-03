# ColourNote Cloud Sync Documentation

This document describes the database schema and cloud synchronization workflow for the ColourNote iOS app. It is intended for cloud system developers to ensure ongoing compatibility between the iOS client and the server.

**Last Updated**: February 3, 2026
**App Version**: 1.1 (Build 4)
**Sync Engine Version**: 1.2

---

## Table of Contents

1. [Database Schema](#database-schema)
   - [Notes Table](#notes-table)
   - [Categories Table](#categories-table)
   - [Sync Mappings Table](#sync-mappings-table)
2. [API Configuration](#api-configuration)
3. [Authentication](#authentication)
4. [API Data Models](#api-data-models)
   - [Cloud Note](#cloud-note)
   - [Cloud Category](#cloud-category)
   - [Create/Update Requests](#createupdate-requests)
5. [Sync Workflow](#sync-workflow)
   - [Full Sync Process](#full-sync-process)
   - [Delta Sync (v1.2)](#delta-sync-v12)
   - [Entity Matching Priority](#entity-matching-priority)
   - [Conflict Resolution](#conflict-resolution)
   - [ETag Support (v1.2)](#etag-support-v12)
6. [API Endpoints](#api-endpoints)
7. [Important Considerations](#important-considerations)

---

## Database Schema

### Notes Table

**Table Name**: `notes`
**Current Schema Version**: 9

| Column | Type | Description |
|--------|------|-------------|
| `_id` | INTEGER | Primary key, auto-increment |
| `uuid` | TEXT | UUID for cross-device identification (v9+) |
| `title` | TEXT | Note title |
| `created_date` | INTEGER | Creation timestamp (milliseconds since Unix epoch) |
| `modified_date` | INTEGER | Last modification timestamp (milliseconds since Unix epoch) |
| `note` | TEXT | Note content (supports Markdown) |
| `category_id` | INTEGER | Foreign key to categories table |
| `active_state` | INTEGER | 0 = active, 1 = deleted (soft delete) |
| `deleted_date` | INTEGER | Deletion timestamp (milliseconds since epoch), NULL if not deleted |
| `content_format` | TEXT | Content format, default "markdown" |

**Notes**:
- The `color_index` column is deprecated; note color is determined by the associated category
- Timestamps are stored as milliseconds since Unix epoch (not seconds)
- Soft delete: `active_state = 1` moves note to trash, `deleted_date` records when

### Categories Table

**Table Name**: `categories`
**Current Schema Version**: 3

| Column | Type | Description |
|--------|------|-------------|
| `category_id` | INTEGER | Primary key |
| `uuid` | TEXT | UUID for cross-device identification (v2+) |
| `category_name` | TEXT | Category display name |
| `color_hex` | TEXT | Color in #RRGGBB format (e.g., "#FF5733") |
| `sort_order` | INTEGER | Display order for categories |
| `is_protected` | INTEGER | 0 = unprotected, 1 = protected with passcode |
| `passcode_hash` | TEXT | SHA-256 hash of 4-digit PIN (local only, NOT synced) |
| `modified_at` | INTEGER | Last modification timestamp in milliseconds (v3+) |

**Indexes** (v3+):
- `idx_categories_uuid` - Index on `uuid` column for faster UUID lookups

**Important Security Note**: The `passcode_hash` column is **NOT synced** to the cloud. Category protection status (`is_protected`) is synced, but users must set passcodes locally on each device.

### Sync Mappings Table

**Table Name**: `sync_mappings`
**Current Schema Version**: 10

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key, auto-increment |
| `local_id` | INTEGER | Local entity ID (note or category) |
| `cloud_id` | TEXT | Cloud server ID (stored as string) |
| `entity_type` | TEXT | "note" or "category" |
| `last_synced` | INTEGER | Last sync timestamp (milliseconds since epoch), nullable |
| `sync_status` | TEXT | "synced", "pending_upload", "pending_download", "conflict" |
| `created_at` | INTEGER | Record creation timestamp |
| `modified_at` | INTEGER | Record modification timestamp |
| `etag` | TEXT | ETag for optimistic concurrency control (v10+), nullable |

**Indexes** (v10+):
- `idx_notes_uuid` - Index on notes `uuid` column for faster UUID lookups

This table maintains the relationship between local IDs and cloud IDs for synchronized entities.

---

## API Configuration

| Setting | Value |
|---------|-------|
| Base URL | `http://irids.co.uk` |
| Request Timeout | 30 seconds |
| Resource Timeout | 60 seconds |
| Content-Type | `application/json` |

---

## Authentication

### JWT Token Authentication

The app uses JWT (JSON Web Token) for authentication. The token is stored securely in the iOS Keychain.

**Keychain Keys**:
- `com.colornote.jwt_token` - JWT token
- `com.colornote.user_email` - User email

### Auth Request

```json
{
  "email": "user@example.com",
  "password": "user_password"
}
```

### Auth Response

```json
{
  "token": "jwt_token_string",
  "user_id": "user_id_string",
  "email": "user@example.com",
  "message": "optional_message"
}
```

### Authorization Header

All authenticated requests include:
```
Authorization: Bearer <jwt_token>
```

---

## API Data Models

### Cloud Note

**JSON Structure** (server response):

```json
{
  "_id": 123,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 1,
  "title": "Note Title",
  "note": "Note content text",
  "created_date": 1706918400000,
  "modified_date": 1706918400000,
  "color_index": null,
  "category_id": 1,
  "active_state": 0,
  "deleted_date": null,
  "content_format": "markdown"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | Integer | Yes (response) | Server-assigned note ID |
| `uuid` | String | No | UUID for cross-device identification |
| `user_id` | Integer | No | Owner user ID (server-assigned) |
| `title` | String | Yes | Note title |
| `note` | String | Yes | Note content |
| `created_date` | Integer | Yes | Creation timestamp (ms since epoch) |
| `modified_date` | Integer | No | Modification timestamp (ms since epoch) |
| `color_index` | Integer | No | Deprecated, not used |
| `category_id` | Integer | No | Associated category ID |
| `active_state` | Integer | No | 0 = active, 1 = deleted |
| `deleted_date` | Integer | No | Deletion timestamp (ms since epoch) |
| `content_format` | String | No | "markdown" (default) |

### Cloud Category

**JSON Structure** (server response):

```json
{
  "category_id": 1,
  "uuid": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": 1,
  "category_name": "Work",
  "color_hex": "#FF5733",
  "sort_order": 0,
  "is_protected": 0,
  "modified_at": 1706918400000
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category_id` | Integer | Yes (response) | Server-assigned category ID |
| `uuid` | String | No | UUID for cross-device identification |
| `user_id` | Integer | No | Owner user ID (server-assigned) |
| `category_name` | String | Yes | Category display name |
| `color_hex` | String | No | Color in #RRGGBB format |
| `sort_order` | Integer | No | Display order |
| `is_protected` | Integer | No | 0 = unprotected, 1 = protected |
| `modified_at` | Integer | No | Last modification timestamp (ms since epoch, v1.2+) |

### Create/Update Requests

#### Create Note Request

```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Note Title",
  "note": "Note content",
  "created_date": 1706918400000,
  "modified_date": 1706918400000,
  "category_id": 1,
  "active_state": 0,
  "deleted_date": null,
  "content_format": "markdown"
}
```

#### Create Category Request

```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Category Name",
  "color_hex": "#FF5733",
  "sort_order": 0,
  "is_protected": 0,
  "modified_at": 1706918400000
}
```

**Note**: For category creation, the field is `name` (not `category_name`).

---

## Sync Workflow

### Full Sync Process

The sync engine performs bidirectional synchronization in the following order:

```
1. CATEGORIES UPLOAD
   └─> Upload all local categories to cloud
       └─> For each category:
           ├─> If mapping exists: PUT /categories/{id}
           └─> If no mapping: POST /categories

2. CATEGORIES DOWNLOAD
   └─> Download all cloud categories
       └─> For each cloud category:
           ├─> Match by UUID (primary)
           ├─> Match by cloud ID mapping (secondary)
           ├─> Match by name (tertiary/fallback)
           └─> Create new if no match

3. NOTES UPLOAD
   └─> Upload all local notes to cloud
       └─> For each note:
           ├─> Skip if empty (no title AND no content)
           ├─> If mapping exists: PUT /notes/{id}
           └─> If no mapping: POST /notes

4. NOTES DOWNLOAD
   └─> Download all cloud notes
       └─> For each cloud note:
           ├─> Match by UUID (primary)
           ├─> Match by cloud ID mapping (secondary)
           ├─> Match by title (tertiary/fallback)
           └─> Create new if no match
```

**Important**: Categories are synced before notes because notes reference category IDs.

### Delta Sync (v1.2)

Delta synchronization allows the app to download only entities that have changed since the last sync, reducing bandwidth and improving performance.

#### Query Parameter

The `since` query parameter can be added to GET requests:

```
GET /categories?since=1706918400000
GET /notes?since=1706918400000
```

Where `since` is a timestamp in milliseconds since Unix epoch.

#### Expected Server Behavior

1. **With `since` parameter**: Return only entities where `modified_at > since`
2. **Without `since` parameter**: Return all entities (full sync)
3. **No changes**: Server may return HTTP 304 Not Modified (optional optimization)

#### Client-Side Tracking

The app tracks per-entity sync times:
- `lastCategorySyncTime` - Last successful category download timestamp
- `lastNoteSyncTime` - Last successful note download timestamp

These are stored in UserDefaults and used for subsequent delta sync requests.

### Entity Matching Priority

When downloading entities from the cloud, the app uses the following priority order to match with local entities:

#### Priority 1: UUID Match (Primary)
- The UUID field provides stable cross-device identification
- If a cloud entity has a UUID that matches a local entity's UUID, they are considered the same entity
- This is the most reliable matching method

#### Priority 2: Cloud ID Mapping (Secondary)
- Check the `sync_mappings` table for an existing local-to-cloud ID relationship
- Used when entities have been previously synced on this device

#### Priority 3: Name/Title Match (Tertiary - Fallback)
- For categories: match by `category_name` (case-insensitive)
- For notes: match by `title` (case-insensitive, non-empty titles only)
- This provides backwards compatibility for data migrated before UUIDs were implemented
- When matched by name, the local entity's UUID is updated to match the cloud UUID

#### No Match: Create New
- If no match is found by any method, a new local entity is created
- The cloud UUID is preserved on the new local entity

### Conflict Resolution

**Strategy**: Most recent modification wins

For notes:
- Compare `modified_date` timestamps (both stored as milliseconds since epoch)
- If cloud timestamp > local timestamp: update local with cloud data
- If cloud timestamp <= local timestamp: keep local data, mark as synced
- UUID is always updated if cloud has one and local differs

For categories (v1.2+):
- Compare `modified_at` timestamps (both stored as milliseconds since epoch)
- If cloud timestamp > local timestamp: update local with cloud data
- If cloud timestamp <= local timestamp: keep local data, mark as synced
- UUID is always updated if cloud has one and local differs

### ETag Support (v1.2)

ETags provide optimistic concurrency control for update operations, preventing lost updates when the same entity is modified on multiple devices.

#### Headers

| Header | Direction | Description |
|--------|-----------|-------------|
| `ETag` | Response | Server returns current entity version |
| `If-Match` | Request | Client sends stored ETag with PUT requests |

#### Workflow

1. **Create/Update Success**: Server returns `ETag` header with new version
2. **Client stores ETag**: Saved in `sync_mappings.etag` column
3. **Next Update**: Client sends `If-Match: <stored_etag>` header
4. **ETag Match**: Server processes update, returns new ETag
5. **ETag Mismatch**: Server returns HTTP 412 Precondition Failed

#### Conflict Resolution on 412

When the app receives a 412 response:

1. Fetch the current server version (GET request)
2. Compare `modified_at` timestamps
3. If local is newer: Force update without ETag (wins)
4. If cloud is newer: Accept cloud version (cloud wins)

#### Example

```
# Initial update (no stored ETag)
PUT /categories/1
Content-Type: application/json

{...}

# Response
HTTP/1.1 200 OK
ETag: "abc123"

# Subsequent update (with stored ETag)
PUT /categories/1
Content-Type: application/json
If-Match: "abc123"

{...}

# If ETag matches
HTTP/1.1 200 OK
ETag: "def456"

# If ETag doesn't match (concurrent edit)
HTTP/1.1 412 Precondition Failed
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Authenticate user, returns JWT |

### Categories

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/categories` | Get all categories for authenticated user |
| GET | `/categories?since={timestamp}` | Get categories modified after timestamp (delta sync, v1.2+) |
| GET | `/categories/{id}` | Get single category by ID |
| POST | `/categories` | Create new category |
| PUT | `/categories/{id}` | Update existing category (supports If-Match header, v1.2+) |
| DELETE | `/categories/{id}` | Delete category |

### Notes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notes` | Get all notes for authenticated user |
| GET | `/notes?since={timestamp}` | Get notes modified after timestamp (delta sync, v1.2+) |
| GET | `/notes/{id}` | Get single note by ID |
| POST | `/notes` | Create new note |
| PUT | `/notes/{id}` | Update existing note (supports If-Match header, v1.2+) |
| DELETE | `/notes/{id}` | Delete note |

### Response Formats

**List Endpoints** (GET /notes, GET /categories):
- Return arrays directly: `[{...}, {...}, ...]`
- Not wrapped in an object

**Create Endpoints** (POST):
- Return the created entity directly

**Update Endpoints** (PUT):
- Return a success message: `{"message": "Updated successfully"}`
- Include `ETag` header in response for optimistic concurrency (v1.2+)
- Return HTTP 412 if `If-Match` header doesn't match current version (v1.2+)

**Delete Endpoints** (DELETE):
- Return success indicator or message

---

## Important Considerations

### Timestamps

- All timestamps are in **milliseconds since Unix epoch** (not seconds)
- Example: `1706918400000` = February 3, 2024 00:00:00 UTC
- The app converts to/from ISO 8601 internally if needed

### UUID Generation

- UUIDs are generated client-side using `UUID().uuidString`
- Format: Standard UUID v4 (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- UUIDs are immutable once assigned
- Server should preserve and return UUIDs without modification

### Empty Notes

- Notes with empty title AND empty content are **skipped during upload**
- This prevents syncing placeholder/draft notes

### Soft Delete

- Deleted notes have `active_state = 1` and `deleted_date` set
- Deleted notes ARE synced to the cloud
- This allows restore functionality across devices

### Category Protection

- `is_protected` flag IS synced
- `passcode_hash` is NOT synced (security measure)
- Users must set passcodes independently on each device

### WAL Mode

- The app uses SQLite WAL (Write-Ahead Logging) mode
- Enables better concurrent read/write access during sync

### Auto-Sync Behavior

- Sync triggers on app launch (if auto-sync enabled)
- Sync triggers when app enters foreground
- Sync triggers when app enters background
- Manual sync available in settings

### Error Handling

- Partial failures don't stop the entire sync
- If category upload fails, note sync still proceeds
- Errors are logged but sync continues where possible

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| Feb 3, 2026 | 1.2 | Delta sync with `since` parameter, ETag support for optimistic concurrency, `modified_at` column for categories, per-entity sync timestamps |
| Feb 3, 2026 | 1.1 | Added UUID-based sync matching (primary match method) |
| Feb 2, 2026 | 1.0 | Initial cloud sync implementation |

---

## Contact

For questions about the sync protocol or API compatibility, contact the ColourNote development team.
