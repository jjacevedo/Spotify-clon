-- Tunehold: database schema, migration 0000.
--
-- Source of truth for packages/db/migrations/0000_init.sql (created with
-- `drizzle-kit generate --custom --name=init`, then this file pasted in).
-- Later migrations are plain SQL files next to it. Never run `drizzle-kit push`:
-- Drizzle cannot express ON DELETE SET NULL (column), deferrable constraints,
-- triggers, roles or policies, and would drop them.
--
-- Target: Postgres 15 or later (Supabase Postgres 17 for dev and prod; Neon or a
-- plain Postgres 15+ also work). Needs PG15 for UNIQUE NULLS NOT DISTINCT and
-- ON DELETE SET NULL (column list). gen_random_uuid() is core since PG13.
-- transaction_timeout is set only on PG17 and later.
--
-- Run on an empty database, as a role with CREATEROLE (Supabase's postgres):
--   psql "$DATABASE_URL_DIRECT" -v ON_ERROR_STOP=1 --single-transaction -f replica/schema.sql
-- Then, once per environment and outside the repo, give the API role a login:
--   alter role tunehold_app with login password '<from the secret store>';
--
-- Validation status (2026-10-05):
--   - The previous revision was executed on 2026-10-04 by the design review on
--     PostgreSQL 16.14 (ON_ERROR_STOP, --single-transaction): 16 tables, the
--     Supabase role branch against stand-in anon/authenticated roles and an
--     auth.users table, and a pg_dump -Fc / pg_restore round trip all passed.
--   - THIS revision (review fixes: counter triggers, the API role and its
--     policies, sort columns, rate_limits, constraint changes) has NOT been
--     executed: the session that wrote it had no shell and no Postgres. The first
--     task that adds packages/db runs the command above on postgres:17 (CI
--     service container or `supabase start`), plus the "Schema checks before 1a"
--     in architecture.md, and fixes any error before milestone 1a starts.
--
-- ACCESS RULES: row level security with real policies, plus owner-scoped
-- repositories in apps/web/src/server.
--   1. API requests connect as tunehold_app (NOBYPASSRLS). Each request runs in
--      one transaction that first calls
--        select set_config('app.uid', '<JWT sub>', true);
--      and every owner table has a policy owner_id = app_uid(). A query that
--      forgets its owner filter still sees only the caller's rows. The setting
--      is transaction-local, so it is safe through the Supavisor transaction
--      pooler.
--   2. Jobs, the sweep, admin routes and migrations connect as the table owner
--      (postgres), which bypasses RLS. That code is small and reviewed apart.
--   3. anon and authenticated (the Supabase Data API roles) keep no table
--      grants, and the Data API is switched off.
--   4. Composite foreign keys (child.owner_id must equal the parent's owner_id)
--      on every link a user can name by id: playlist items, favorites,
--      downloads, play events, playback state (track and device), track
--      groupings. A cross-user id fails at the database even on the owner
--      connection.
--
-- Storage counters (profiles.used_bytes, profiles.reserved_bytes) are kept by
-- triggers on tracks and upload_sessions. Application code never writes them;
-- the sweep only checks them (architecture.md, "Key queries").
--
-- Conventions: uuid ids; timestamptz in UTC; created_at and updated_at on rows
-- that change (updated_at drives the offline sync cursor together with id, and
-- a trigger keeps it current with clock_timestamp()); append-only rows
-- (favorites, play_events, tombstones) have created_at only. Byte counts are
-- bigint. Sort keys are text COLLATE "C" (bytewise, equal to SQLite BINARY on
-- the device). No money, plan or billing tables: payments are deferred
-- (replica/deferred.md).

-- ---------------------------------------------------------------------------
-- Extensions and helper functions
-- ---------------------------------------------------------------------------

create schema if not exists extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;

-- unaccent() is only STABLE (it reads a dictionary), so it cannot feed a
-- generated column or an index. This wrapper pins the dictionary and is safe to
-- mark IMMUTABLE. Everything is schema-qualified, so no search_path is needed.
create or replace function public.f_unaccent(input text)
returns text
language sql
immutable
parallel safe
strict
as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, input)
$$;

-- Search normal form: no accents, lower case. Used for search_text columns and
-- for the query string, so "Beyonce", "BEYONCÉ" and "beyoncé" all match.
create or replace function public.search_norm(input text)
returns text
language sql
immutable
parallel safe
as $$
  select lower(public.f_unaccent(coalesce(input, '')))
$$;

-- updated_at uses clock_timestamp(), not now(): now() is the transaction start,
-- so every row a long transaction writes would look older than its commit.
-- Ties inside one statement are broken by id in the (updated_at, id) cursor.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := clock_timestamp();
  return new;
end
$$;

-- The caller's id for row level security, set per transaction by the API.
-- NULL when unset, so no policy matches and the API role sees nothing.
create or replace function public.app_uid()
returns uuid
language sql
stable
parallel safe
as $$
  select nullif(current_setting('app.uid', true), '')::uuid
$$;

-- Raises if any column named in the trigger arguments changes.
create or replace function public.guard_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  col text;
begin
  foreach col in array tg_argv loop
    if (to_jsonb(old) -> col) is distinct from (to_jsonb(new) -> col) then
      raise exception 'column %.% cannot change', tg_table_name, col;
    end if;
  end loop;
  return new;
end
$$;

-- Whether an upload session's bytes count in profiles.reserved_bytes: while the
-- upload is in flight, and for a cover image while it waits in the inbox
-- (status 'completed' until it is 'consumed' or 'expired').
create or replace function public.upload_session_holds_bytes(kind text, status text)
returns boolean
language sql
immutable
parallel safe
as $$
  select status in ('pending', 'completing') or (kind = 'cover' and status = 'completed')
$$;

-- ---------------------------------------------------------------------------
-- The API role (row level security applies to it)
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'tunehold_app') then
    create role tunehold_app nologin nobypassrls;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- People: profiles (one per Supabase Auth user, includes the storage limit),
-- invites, devices
-- ---------------------------------------------------------------------------

-- id equals auth.users.id (the JWT "sub"), so it has no default.
-- Storage limit and usage live here, not in a separate table.
--   used_bytes     = sum(tracks.size_bytes) of the user's rows (kept by trigger)
--   reserved_bytes = sum(upload_sessions.reserved_bytes) of sessions that hold
--                    bytes (kept by trigger)
-- The reserve gate locks this row (select ... for update) before inserting
-- sessions, so concurrent batches are serialised.
-- The limit may be set below usage by the admin: nothing is deleted; new uploads
-- are refused until usage is under the limit again.
create table public.profiles (
  id uuid primary key,
  email text not null,
  display_name text not null default '' check (char_length(display_name) <= 80),
  role text not null default 'member' check (role in ('admin', 'member')),
  status text not null default 'invited'
    check (status in ('invited', 'active', 'disabled', 'deleting')),
  storage_limit_bytes bigint not null default 0 check (storage_limit_bytes >= 0),
  used_bytes bigint not null default 0 check (used_bytes >= 0),
  reserved_bytes bigint not null default 0 check (reserved_bytes >= 0),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index profiles_email_key on public.profiles (lower(email));
create index profiles_status_idx on public.profiles (status);

-- Invite-only accounts. The admin's POST /api/v1/admin/invites creates the
-- Supabase Auth user (auth.admin.generateLink type 'invite'), the profile
-- (status 'invited') and this row. Revoking an unaccepted invite deletes the
-- auth user and the profile, which cascades here.
create table public.invites (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles (id) on delete cascade,
  email text not null,
  invited_by uuid references public.profiles (id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  links_generated integer not null default 1 check (links_generated >= 1),
  last_link_at timestamptz not null default now(),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invites_accepted_has_time check ((status = 'accepted') = (accepted_at is not null))
);
create index invites_invited_by_idx on public.invites (invited_by);
create index invites_status_created_idx on public.invites (status, created_at desc);

-- One row per app install or browser sign-in. The id is generated on the device
-- (crypto.randomUUID) at every sign-in and after every wipe, so a restored or
-- migrated phone never reuses another install's id.
-- auth_session_id: the Supabase session (JWT session_id claim) this device
--   registered with. The API refuses every request whose session belongs to a
--   revoked device (401 device_revoked), which is what remote sign-out means.
-- revoked_at: signed out remotely; the device wipes its downloads on the 401.
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  auth_session_id uuid unique,
  name text not null check (char_length(name) between 1 and 80),
  platform text not null check (platform in ('web', 'ios', 'android')),
  app_version text check (char_length(app_version) <= 40),
  allow_cellular_downloads boolean not null default false,
  last_seen_at timestamptz not null default now(),
  last_sync_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint devices_id_owner_key unique (id, owner_id)
);
create index devices_owner_last_seen_idx on public.devices (owner_id, last_seen_at desc);

-- ---------------------------------------------------------------------------
-- Library: covers, artists, albums, tracks
-- ---------------------------------------------------------------------------

-- Cover images, deduplicated per user by the hash of the source image, so every
-- track of an album shares one row. Objects are keyed by the row id, never by
-- the hash: u/{owner}/c/{cover id}-600.webp and -300.webp. A new row therefore
-- never shares objects with a deleted one. Writers upload the objects under a
-- fresh id first, then insert the row under the per-user library lock; on a
-- hash conflict they reuse the existing row and delete their fresh objects after
-- commit. library_cleanup deletes unreferenced rows, then their objects after
-- its transaction commits.
create table public.covers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  content_sha256 text not null check (content_sha256 ~ '^[0-9a-f]{64}$'),
  key_600 text not null,
  key_300 text not null,
  source text not null check (source in ('embedded', 'sidecar', 'user')),
  source_width integer check (source_width > 0),
  source_height integer check (source_height > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint covers_owner_hash_key unique (owner_id, content_sha256),
  constraint covers_id_owner_key unique (id, owner_id)
);

-- Artists and albums are real per-user TABLES, not views over tracks:
--   - stable ids for URLs (/artist/:id, /album/:id), the offline mirror, export
--     and a later Subsonic-compatible layer;
--   - one row to hang the album cover, year and compilation flag on;
--   - grouping is decided once at ingest (and on tag edits), instead of on every
--     read of a 50k-track library.
-- Cost: ingest upserts them, tag edits re-point tracks, and library_cleanup
-- deletes the ones left empty (writing tombstones for offline devices). Every
-- transaction that upserts or points at artists, albums or covers takes
-- pg_advisory_xact_lock(hashtextextended('library:' || owner_id, 0)) first.
-- name_key / title_key: grouping keys computed in packages/media (Unicode NFC,
-- lower case, trimmed, inner spaces collapsed; accents KEPT, so distinct names
-- are not merged). sort_* keys: packages/media sortKey() (NFD, combining marks
-- removed, lower case, spaces collapsed, trimmed, first 100 code points), so
-- "Ángel" sorts with "angel". search_text drops accents for search only.
create table public.artists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 300),
  name_key text collate "C" not null check (char_length(name_key) between 1 and 300),
  sort_name text collate "C" not null check (char_length(sort_name) <= 100),
  search_text text generated always as (public.search_norm(name)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint artists_owner_name_key unique (owner_id, name_key),
  constraint artists_id_owner_key unique (id, owner_id)
);
create index artists_owner_sort_idx on public.artists (owner_id, sort_name, id);
create index artists_owner_updated_idx on public.artists (owner_id, updated_at, id);
create index artists_search_trgm_idx on public.artists using gin (search_text extensions.gin_trgm_ops);

-- artist_id is the album artist (albumartist tag, "Various Artists" for
-- compilations, else the first track artist). NULL means the tags name no artist.
-- artist_name is a display copy so album search can match "title + artist".
create table public.albums (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  artist_id uuid,
  artist_name text check (char_length(artist_name) <= 300),
  title text not null check (char_length(title) between 1 and 300),
  title_key text collate "C" not null check (char_length(title_key) between 1 and 300),
  sort_title text collate "C" not null check (char_length(sort_title) <= 100),
  sort_artist text collate "C" not null default '' check (char_length(sort_artist) <= 100),
  year smallint check (year between 0 and 9999),
  is_compilation boolean not null default false,
  cover_id uuid,
  search_text text generated always as (
    public.search_norm(title || ' ' || coalesce(artist_name, ''))
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint albums_owner_artist_title_key unique nulls not distinct (owner_id, artist_id, title_key),
  constraint albums_id_owner_key unique (id, owner_id),
  -- An artist is deleted only by library_cleanup, after its albums are gone.
  constraint albums_artist_fkey foreign key (artist_id, owner_id)
    references public.artists (id, owner_id) on delete restrict,
  constraint albums_cover_fkey foreign key (cover_id, owner_id)
    references public.covers (id, owner_id) on delete set null (cover_id)
);
create index albums_artist_id_idx on public.albums (artist_id);
create index albums_cover_id_idx on public.albums (cover_id);
create index albums_owner_sort_title_idx on public.albums (owner_id, sort_title, id);
create index albums_owner_sort_artist_idx on public.albums (owner_id, sort_artist, sort_title, id);
create index albums_owner_year_idx on public.albums (owner_id, (coalesce(year, 0)), sort_title, id);
create index albums_owner_created_idx on public.albums (owner_id, created_at desc, id desc);
create index albums_owner_updated_idx on public.albums (owner_id, updated_at, id);
create index albums_search_trgm_idx on public.albums using gin (search_text extensions.gin_trgm_ops);

-- One uploaded file. The stored object (object_key, u/{owner}/o/{id}.{ext}) is
-- written once and never rewritten: that is the bit-for-bit guarantee (F6).
-- owner_id, object_key, size_bytes and content_md5 cannot change (trigger).
-- The id is chosen at upload reservation, so it is part of the object key.
-- Duplicates are detected per user only (no cross-user deduplication):
-- unique (owner_id, content_md5) among rows that are not deleted.
--
-- status:
--   processing  stored and verified; tag and cover extraction pending
--   ready       playable
--   failed      stored, but the audio could not be parsed, or extraction gave up
--               after its last attempt (status_reason says why)
--   disabled    access switched off: no signing, no manifest, removed from devices
--               at their next sync. The object is kept. No v1 UI sets it (the
--               takedown workflow is deferred); it exists so every read path
--               already honours it.
--   deleted     the user deleted it; hidden everywhere; the purge_track job deletes
--               the object, then deletes the row (the trigger gives the bytes back)
--               and writes a tombstone.
--
-- Tag columns hold the EFFECTIVE tags: from the file (truncated to 300
-- characters), overridden by the user's edits (S19). tags_raw keeps an
-- allow-listed copy of what the file said (text frames only, no pictures or
-- binary values, each value at most 500 characters; 8 KB in total).
-- user_edited_fields lists the columns a re-extract must not overwrite.
-- track_no and disc_no are 0 when the tags don't say, so natural-order row
-- comparisons never meet a NULL.
create table public.tracks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  album_id uuid,
  artist_id uuid,
  cover_id uuid,
  status text not null default 'processing'
    check (status in ('processing', 'ready', 'failed', 'disabled', 'deleted')),
  status_reason text check (char_length(status_reason) <= 500),

  -- the stored original
  object_key text not null unique,
  original_filename text not null check (char_length(original_filename) between 1 and 1024),
  relative_path text check (char_length(relative_path) <= 4096),
  ext text not null check (ext in ('mp3', 'm4a', 'mp4', 'aac', 'flac', 'wav')),
  mime text not null check (char_length(mime) <= 100),
  size_bytes bigint not null check (size_bytes > 0),
  content_md5 text not null check (content_md5 ~ '^[0-9a-f]{32}$'),

  -- audio properties (music-metadata)
  codec text check (char_length(codec) <= 40),
  container text check (char_length(container) <= 40),
  duration_ms integer check (duration_ms >= 0),
  duration_estimated boolean not null default false,
  bitrate_kbps integer check (bitrate_kbps >= 0),
  sample_rate_hz integer check (sample_rate_hz > 0),
  bit_depth smallint check (bit_depth > 0),
  channels smallint check (channels > 0),
  lossless boolean,

  -- effective tags
  title text not null check (char_length(title) between 1 and 300),
  artist_name text check (char_length(artist_name) <= 300),
  album_title text check (char_length(album_title) <= 300),
  album_artist_name text check (char_length(album_artist_name) <= 300),
  track_no smallint not null default 0 check (track_no >= 0),
  track_total smallint check (track_total >= 0),
  disc_no smallint not null default 0 check (disc_no >= 0),
  disc_total smallint check (disc_total >= 0),
  year smallint check (year between 0 and 9999),
  genre text check (char_length(genre) <= 200),
  is_compilation boolean not null default false,
  tags_raw jsonb not null default '{}'::jsonb
    check (jsonb_typeof(tags_raw) = 'object' and octet_length(tags_raw::text) <= 8192),
  user_edited_fields text[] not null default '{}',

  -- natural-order sort keys (packages/media sortKey(); sent to devices as-is)
  sort_title text collate "C" not null check (char_length(sort_title) <= 100),
  sort_artist text collate "C" not null default '' check (char_length(sort_artist) <= 100),
  sort_album text collate "C" not null default '' check (char_length(sort_album) <= 100),

  -- personal stats (F8), kept in step with play_events in the same transaction
  play_count integer not null default 0 check (play_count >= 0),
  last_played_at timestamptz,

  search_text text generated always as (
    public.search_norm(title || ' ' || coalesce(artist_name, '') || ' ' || coalesce(album_title, ''))
  ) stored,

  ready_at timestamptz,
  disabled_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tracks_id_owner_key unique (id, owner_id),
  constraint tracks_album_fkey foreign key (album_id, owner_id)
    references public.albums (id, owner_id) on delete set null (album_id),
  constraint tracks_artist_fkey foreign key (artist_id, owner_id)
    references public.artists (id, owner_id) on delete set null (artist_id),
  constraint tracks_cover_fkey foreign key (cover_id, owner_id)
    references public.covers (id, owner_id) on delete set null (cover_id),
  constraint tracks_ready_has_duration check (status <> 'ready' or duration_ms is not null),
  constraint tracks_disabled_has_time check (status <> 'disabled' or disabled_at is not null),
  constraint tracks_deleted_has_time check (status <> 'deleted' or deleted_at is not null)
);
create unique index tracks_owner_md5_live_key
  on public.tracks (owner_id, content_md5) where status <> 'deleted';
-- Library lists and natural-order contexts read live rows only. A query with
-- status = 'ready' also uses these (it implies the index predicate).
create index tracks_owner_live_created_idx
  on public.tracks (owner_id, created_at desc, id desc) where status in ('ready', 'processing');
create index tracks_owner_live_title_idx
  on public.tracks (owner_id, sort_title, id) where status in ('ready', 'processing');
create index tracks_owner_live_artist_idx
  on public.tracks (owner_id, sort_artist, sort_album, disc_no, track_no, id)
  where status in ('ready', 'processing');
create index tracks_owner_live_album_idx
  on public.tracks (owner_id, sort_album, disc_no, track_no, id)
  where status in ('ready', 'processing');
create index tracks_owner_failed_idx
  on public.tracks (owner_id, created_at desc) where status = 'failed';
create index tracks_owner_updated_idx on public.tracks (owner_id, updated_at, id);
create index tracks_owner_last_played_idx
  on public.tracks (owner_id, last_played_at desc) where last_played_at is not null;
create index tracks_album_order_idx on public.tracks (album_id, disc_no, track_no, sort_title, id);
create index tracks_artist_order_idx
  on public.tracks (artist_id, (coalesce(year, 0)), sort_album, disc_no, track_no, id);
create index tracks_cover_id_idx on public.tracks (cover_id);
create index tracks_search_trgm_idx on public.tracks using gin (search_text extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- Uploads and jobs
-- ---------------------------------------------------------------------------

-- One file being uploaded straight to object storage (never through Vercel).
-- kind 'audio': planned_track_id is the future tracks.id, already in object_key.
-- kind 'cover': an image (<= 10 MiB, jpg/png/webp) stored at
--   u/{owner}/in/{session id}.{ext}: a cover.jpg / folder.jpg sidecar from a
--   folder upload (used by the apply_sidecar_cover job), or a user-chosen image
--   from POST /api/v1/covers/uploads (used by a PATCH with coverUploadId). It
--   becomes 'consumed' when the inbox object is deleted after use.
-- Every session reserves its declared size. Presigned PUTs and parts fix
--   Content-Length, so the stored bytes equal the reserved bytes.
-- mode 'single': one presigned PUT (web under 32 MB; mobile always; covers).
--   mode 'multipart': S3 multipart, 16 MB parts (web, 32 MB and up).
--   s3_upload_id is created lazily by the first POST /uploads/:id/parts (row
--   locked), so a 500-file batch call makes no storage round trips.
-- part_md5s: hex MD5 of each part, sent by the client when it asks for part URLs;
--   compared at /complete with the ETags from a server-side ListParts.
-- status: pending (reserved, bytes may be moving) -> completing (a /complete call
--   is running) -> completed (audio: terminal; cover: waiting in the inbox)
--   -> consumed (cover only) | failed | aborted | expired.
-- The upload_sessions_count_bytes trigger adds reserved_bytes to
-- profiles.reserved_bytes while upload_session_holds_bytes(kind, status), and
-- takes it away on the transition out, exactly once.
-- expires_at slides 72 h forward on activity, never past created_at + 7 days.
-- Finished rows are pruned by the sweep after 30 days.
create table public.upload_sessions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  batch_id uuid not null,
  kind text not null default 'audio' check (kind in ('audio', 'cover')),
  planned_track_id uuid,
  track_id uuid,
  original_filename text not null check (char_length(original_filename) between 1 and 1024),
  relative_path text check (char_length(relative_path) <= 4096),
  declared_size_bytes bigint not null check (declared_size_bytes > 0),
  declared_mime text check (char_length(declared_mime) <= 100),
  content_md5 text not null check (content_md5 ~ '^[0-9a-f]{32}$'),
  ext text not null,
  object_key text not null unique,
  mode text not null check (mode in ('single', 'multipart')),
  s3_upload_id text,
  part_size_bytes integer check (part_size_bytes > 0),
  part_count integer check (part_count between 1 and 10000),
  part_md5s text[],
  reserved_bytes bigint not null check (reserved_bytes >= 0),
  status text not null default 'pending'
    check (status in ('pending', 'completing', 'completed', 'consumed', 'failed', 'aborted', 'expired')),
  error_code text check (char_length(error_code) <= 60),
  error_message text check (char_length(error_message) <= 500),
  expires_at timestamptz not null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint upload_sessions_audio_has_planned_id check ((kind = 'audio') = (planned_track_id is not null)),
  constraint upload_sessions_track_matches_plan check (track_id is null or track_id = planned_track_id),
  constraint upload_sessions_ext_matches_kind check (
    (kind = 'audio' and ext in ('mp3', 'm4a', 'mp4', 'aac', 'flac', 'wav'))
    or (kind = 'cover' and ext in ('jpg', 'jpeg', 'png', 'webp'))
  ),
  constraint upload_sessions_cover_size check (kind <> 'cover' or declared_size_bytes <= 10485760),
  constraint upload_sessions_cover_single check (kind <> 'cover' or mode = 'single'),
  constraint upload_sessions_consumed_is_cover check (status <> 'consumed' or kind = 'cover'),
  constraint upload_sessions_reserves_declared check (reserved_bytes = declared_size_bytes),
  constraint upload_sessions_expiry_cap check (expires_at <= created_at + interval '7 days'),
  constraint upload_sessions_multipart_fields check (
    (mode = 'multipart') = (part_size_bytes is not null and part_count is not null)
  ),
  constraint upload_sessions_upload_id_only_multipart check (s3_upload_id is null or mode = 'multipart'),
  constraint upload_sessions_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete set null (track_id)
);
-- One live session per file per user: a second tab, device or retry resumes it.
create unique index upload_sessions_live_md5_key
  on public.upload_sessions (owner_id, content_md5)
  where kind = 'audio' and status in ('pending', 'completing');
create index upload_sessions_owner_batch_idx on public.upload_sessions (owner_id, batch_id, created_at);
create index upload_sessions_live_expires_idx
  on public.upload_sessions (expires_at) where status in ('pending', 'completing');
create index upload_sessions_cover_held_idx
  on public.upload_sessions (updated_at) where kind = 'cover' and status = 'completed';
create index upload_sessions_finished_idx
  on public.upload_sessions (updated_at)
  where status in ('completed', 'consumed', 'failed', 'aborted', 'expired');
create index upload_sessions_track_id_idx on public.upload_sessions (track_id);

-- Postgres job queue, claimed with FOR UPDATE SKIP LOCKED. Run inline by
-- next/server after() and by the sweep route (GitHub Actions schedule + daily
-- Vercel cron), always on the owner connection. owner_id is NULL for system jobs
-- and for purge_user, which must outlive the profile it deletes.
-- dedupe_key makes enqueueing idempotent ('extract:{trackId}', 'purge_track:{trackId}', ...).
-- When an extract job fails its last attempt, the same transaction marks the
-- track 'failed' with status_reason 'extract_gave_up: ...'.
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles (id) on delete cascade,
  kind text not null check (kind in (
    'extract', 'apply_sidecar_cover', 'regroup_batch',
    'purge_track', 'purge_user', 'library_cleanup'
  )),
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  dedupe_key text check (char_length(dedupe_key) <= 200),
  status text not null default 'queued' check (status in ('queued', 'running', 'done', 'failed')),
  attempts integer not null default 0 check (attempts >= 0),
  max_attempts integer not null default 5 check (max_attempts >= 1),
  run_after timestamptz not null default now(),
  locked_at timestamptz,
  locked_by text,
  last_error text check (char_length(last_error) <= 2000),
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint jobs_running_is_locked check (status <> 'running' or locked_at is not null)
);
create unique index jobs_live_dedupe_key
  on public.jobs (dedupe_key) where dedupe_key is not null and status in ('queued', 'running');
create index jobs_claim_idx on public.jobs (run_after) where status = 'queued';
create index jobs_running_locked_idx on public.jobs (locked_at) where status = 'running';
create index jobs_finished_idx on public.jobs (finished_at) where status in ('done', 'failed');
create index jobs_owner_id_idx on public.jobs (owner_id);

-- ---------------------------------------------------------------------------
-- Playlists and favorites
-- ---------------------------------------------------------------------------

-- kind 'smart' (F8, should): items are computed from rules on read; no rows in
-- playlist_items. rules follow the zod grammar in packages/contract (fixed
-- fields and operators, at most 20 conditions, depth <= 2) and compile only to
-- parameterised conditions. cover_id NULL means the UI draws a mosaic.
create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 200),
  description text check (char_length(description) <= 1000),
  kind text not null default 'manual' check (kind in ('manual', 'smart')),
  rules jsonb,
  cover_id uuid,
  search_text text generated always as (public.search_norm(name)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playlists_id_owner_key unique (id, owner_id),
  constraint playlists_rules_match_kind check ((kind = 'smart') = (rules is not null)),
  constraint playlists_rules_shape check (
    rules is null or (jsonb_typeof(rules) = 'object' and octet_length(rules::text) <= 8192)
  ),
  constraint playlists_cover_fkey foreign key (cover_id, owner_id)
    references public.covers (id, owner_id) on delete set null (cover_id)
);
create index playlists_owner_updated_idx on public.playlists (owner_id, updated_at, id);
create index playlists_owner_name_idx on public.playlists (owner_id, lower(name), id);
create index playlists_cover_id_idx on public.playlists (cover_id);
create index playlists_search_trgm_idx on public.playlists using gin (search_text extensions.gin_trgm_ops);

-- Ordering by fractional index keys (base-62 strings from the fractional-indexing
-- package), compared bytewise (COLLATE "C"). A move or an insert between two
-- items is ONE row update: the server picks a key between the neighbours' keys.
-- Every item mutation first locks the playlist row (select ... for update), so
-- two writers never pick the same key. When a new key would be longer than 64
-- characters, the same transaction rebalances the playlist: SET CONSTRAINTS
-- playlist_items_order_key DEFERRED, then rewrite every sort_key with evenly
-- spaced keys in the current order. The constraint is deferrable for that
-- rewrite; it is never an ON CONFLICT arbiter.
-- The same track may appear twice (each row has its own id); the API warns first.
create table public.playlist_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  playlist_id uuid not null,
  track_id uuid not null,
  sort_key text collate "C" not null
    check (sort_key ~ '^[0-9A-Za-z]+$' and char_length(sort_key) <= 128),
  added_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playlist_items_playlist_fkey foreign key (playlist_id, owner_id)
    references public.playlists (id, owner_id) on delete cascade,
  constraint playlist_items_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete cascade,
  constraint playlist_items_order_key unique (playlist_id, sort_key) deferrable initially immediate
);
create index playlist_items_track_id_idx on public.playlist_items (track_id);
create index playlist_items_owner_updated_idx on public.playlist_items (owner_id, updated_at, id);

-- The recon's "Like". The UI label is a brand decision (brand.md: "Favorites" or
-- "Keepers"); the identifier stays "favorites" either way. Favoriting a track
-- again deletes its 'favorite' tombstone in the same transaction.
create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  track_id uuid not null,
  created_at timestamptz not null default now(),
  constraint favorites_owner_track_key unique (owner_id, track_id),
  constraint favorites_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete cascade
);
create index favorites_owner_created_idx on public.favorites (owner_id, created_at desc, id desc);
create index favorites_track_id_idx on public.favorites (track_id);

-- ---------------------------------------------------------------------------
-- Listening: play events, playback state
-- ---------------------------------------------------------------------------

-- Append-only listening history (F8). The id is generated on the device, so the
-- offline outbox can retry safely (INSERT ... ON CONFLICT (id) DO NOTHING).
-- The insert is set-based with LEFT JOINs to the caller's tracks and devices: a
-- purged or unknown track is stored with track_id NULL and the client's title
-- snapshot ('orphaned'), an unknown device with device_id NULL, and played_at is
-- clamped to now(), so one stale event never blocks the batch.
-- counted: the play met the play rule (30 s, or half the track if shorter),
-- computed on the server; only counted plays add to tracks.play_count.
-- played_at is UTC. client_tz is the device's IANA zone at play time: history is
-- the only place Tunehold shows local times.
-- The title/artist/album snapshot keeps history readable after the track is
-- deleted or its tags are edited.
create table public.play_events (
  id uuid primary key,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  track_id uuid,
  device_id uuid,
  played_at timestamptz not null,
  ms_played integer not null check (ms_played >= 0),
  counted boolean not null,
  context_type text check (context_type in
    ('album', 'artist', 'playlist', 'favorites', 'library', 'search', 'queue')),
  context_id uuid,
  client_tz text check (char_length(client_tz) <= 64),
  track_title text not null check (char_length(track_title) between 1 and 300),
  artist_name text check (char_length(artist_name) <= 300),
  album_title text check (char_length(album_title) <= 300),
  created_at timestamptz not null default now(),
  constraint play_events_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete set null (track_id),
  constraint play_events_device_fkey foreign key (device_id, owner_id)
    references public.devices (id, owner_id) on delete set null (device_id),
  constraint play_events_not_future check (played_at <= created_at + interval '1 day')
);
create index play_events_owner_played_idx on public.play_events (owner_id, played_at desc);
create index play_events_track_id_idx on public.play_events (track_id);
create index play_events_device_id_idx on public.play_events (device_id);

-- One row per user: what is playing and what plays next.
-- device_id is the ACTIVE device. Only it writes the playback fields (context,
-- cursor, current track and item, position, is_playing, shuffle, repeat, ended)
-- through PUT /api/v1/playback-state; another device's PUT gets 409
-- not_active_device unless it is an explicit take-over by the user. user_queue
-- is shared: any device edits it through POST /api/v1/playback-state/queue ops,
-- and the active device removes entries as they start. Every write bumps version.
--   context_*        what was started: album, playlist, favorites, artist, the whole
--                    library (with its sort), search results (ids frozen in
--                    context_track_ids, at most 1000), or only the user queue.
--   context_cursor   natural order: {"v": [sort values...], "id": "<member id>"} of
--                    the current member; the next one is the first member whose
--                    (sort values, id) row is greater (see architecture.md,
--                    "Members").
--   current_item_id  playlist item id, so a track listed twice resolves.
--   position_ms/at   position and the server time it was reported.
--   user_queue       [{ "entryId": uuid, "trackId": uuid }, ...] played before the
--                    context continues ("play next", "add to queue"); max 1000.
--   shuffle_*        once-per-cycle shuffle (F4): order = md5(seed || ':' || memberId)
--                    ascending (bytewise); next = smallest key above shuffle_last_key;
--                    none left = end of cycle (repeat all: cycle + 1 and a new seed;
--                    repeat off: the context ends, F2).
--   ended            the context reached its end with repeat off (F2 end state).
create table public.playback_state (
  owner_id uuid primary key references public.profiles (id) on delete cascade,
  version bigint not null default 1 check (version >= 1),
  device_id uuid,
  context_type text check (context_type in
    ('album', 'artist', 'playlist', 'favorites', 'library', 'search', 'queue')),
  context_id uuid,
  context_sort text check (char_length(context_sort) <= 40),
  context_track_ids uuid[],
  context_cursor jsonb check (
    context_cursor is null
    or (jsonb_typeof(context_cursor) = 'object' and octet_length(context_cursor::text) <= 2048)
  ),
  current_track_id uuid,
  current_item_id uuid,
  position_ms integer not null default 0 check (position_ms >= 0),
  position_at timestamptz,
  is_playing boolean not null default false,
  user_queue jsonb not null default '[]'::jsonb check (
    case when jsonb_typeof(user_queue) = 'array'
         then jsonb_array_length(user_queue) <= 1000
         else false
    end
  ),
  shuffle boolean not null default false,
  shuffle_seed text check (shuffle_seed ~ '^[0-9a-f]{32}$'),
  shuffle_cycle integer not null default 0 check (shuffle_cycle >= 0),
  shuffle_last_key text collate "C" check (shuffle_last_key ~ '^[0-9a-f]{32}$'),
  repeat_mode text not null default 'off' check (repeat_mode in ('off', 'all', 'one')),
  ended boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playback_state_shuffle_has_seed check (not shuffle or shuffle_seed is not null),
  constraint playback_state_search_ids_bounded check (
    context_track_ids is null or cardinality(context_track_ids) <= 1000
  ),
  constraint playback_state_device_fkey foreign key (device_id, owner_id)
    references public.devices (id, owner_id) on delete set null (device_id),
  constraint playback_state_current_track_fkey foreign key (current_track_id, owner_id)
    references public.tracks (id, owner_id) on delete set null (current_track_id)
);
create index playback_state_device_id_idx on public.playback_state (device_id);
create index playback_state_current_track_idx on public.playback_state (current_track_id);

-- ---------------------------------------------------------------------------
-- Offline: downloads registry and tombstones
-- ---------------------------------------------------------------------------

-- Which tracks each device has confirmed it holds (downloaded, size and MD5
-- verified). The device's own expo-sqlite index is authoritative for playback
-- and records WHY each file is there (one file can serve several scopes: an
-- album, a playlist, favorites); the server only needs files and bytes per
-- device, for the settings page and for revoking a lost device. There is no
-- device cap at personal scale.
create table public.downloads (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  device_id uuid not null,
  track_id uuid not null,
  size_bytes bigint not null check (size_bytes > 0),
  verified_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint downloads_device_track_key unique (device_id, track_id),
  constraint downloads_device_fkey foreign key (device_id, owner_id)
    references public.devices (id, owner_id) on delete cascade,
  constraint downloads_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete cascade
);
create index downloads_owner_device_idx on public.downloads (owner_id, device_id);
create index downloads_track_id_idx on public.downloads (track_id);

-- Hard deletes that offline devices must hear about at their next sync (F5:
-- no periodic check-in; removal at next connection). Soft states (a track that
-- is 'deleted' but not yet purged, or 'disabled') reach devices as row changes.
-- Cascaded deletes write no tombstones of their own: devices apply the cascade
-- themselves (a track tombstone drops its playlist items, favorite and local
-- file; a playlist tombstone drops its items), and apply tombstones before rows.
-- entity_id is the deleted row's id, except 'favorite', where it is the track id.
-- Kept 180 days; a device whose cursor is older gets fullResync = true.
create table public.tombstones (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  entity text not null check (entity in
    ('track', 'album', 'artist', 'playlist', 'playlist_item', 'favorite')),
  entity_id uuid not null,
  created_at timestamptz not null default now()
);
create index tombstones_owner_created_idx on public.tombstones (owner_id, created_at, id);
create index tombstones_owner_entity_idx on public.tombstones (owner_id, entity, entity_id);
create index tombstones_created_idx on public.tombstones (created_at);

-- ---------------------------------------------------------------------------
-- Rate limits: fixed windows, one row per key (user + route, or IP + route)
-- ---------------------------------------------------------------------------

-- Written only through rate_limit_hit(); the API role has no policy here.
-- Rows older than a day are pruned by the sweep.
create table public.rate_limits (
  key text primary key check (char_length(key) <= 200),
  window_start timestamptz not null,
  hits integer not null check (hits >= 1)
);
create index rate_limits_window_idx on public.rate_limits (window_start);

-- Counts one hit for p_key in the current window of p_window_seconds and
-- returns true while the window holds at most p_max hits (false = 429).
create or replace function public.rate_limit_hit(p_key text, p_window_seconds integer, p_max integer)
returns boolean
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.rate_limits as r (key, window_start, hits)
  values (
    p_key,
    to_timestamp(
      (floor(extract(epoch from clock_timestamp()) / p_window_seconds) * p_window_seconds)::double precision
    ),
    1
  )
  on conflict (key) do update
    set hits = case when r.window_start = excluded.window_start then r.hits + 1 else 1 end,
        window_start = excluded.window_start
  returning r.hits <= p_max
$$;

-- ---------------------------------------------------------------------------
-- Storage counters (triggers; the only writers of used_bytes / reserved_bytes)
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER so the counter update never depends on the caller's row
-- level security. When a profile delete cascades, the profile row is already
-- invisible to these updates, so they touch nothing.

create or replace function public.tracks_count_bytes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set used_bytes = used_bytes + new.size_bytes where id = new.owner_id;
  elsif tg_op = 'DELETE' then
    update public.profiles set used_bytes = used_bytes - old.size_bytes where id = old.owner_id;
  end if;
  return null;
end
$$;

create or replace function public.upload_sessions_count_bytes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  delta bigint := 0;
begin
  if tg_op in ('UPDATE', 'DELETE') then
    if public.upload_session_holds_bytes(old.kind, old.status) then
      delta := delta - old.reserved_bytes;
    end if;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    if public.upload_session_holds_bytes(new.kind, new.status) then
      delta := delta + new.reserved_bytes;
    end if;
  end if;
  if delta <> 0 then
    if tg_op = 'DELETE' then
      update public.profiles set reserved_bytes = reserved_bytes + delta where id = old.owner_id;
    else
      update public.profiles set reserved_bytes = reserved_bytes + delta where id = new.owner_id;
    end if;
  end if;
  return null;
end
$$;

create trigger tracks_count_bytes
  after insert or delete on public.tracks
  for each row execute function public.tracks_count_bytes();
create trigger upload_sessions_count_bytes
  after insert or update of status, reserved_bytes or delete on public.upload_sessions
  for each row execute function public.upload_sessions_count_bytes();

-- The columns the counters depend on, and the stored original's identity,
-- cannot change after insert.
create trigger tracks_guard_immutable
  before update of owner_id, object_key, size_bytes, content_md5 on public.tracks
  for each row execute function public.guard_immutable('owner_id', 'object_key', 'size_bytes', 'content_md5');
create trigger upload_sessions_guard_immutable
  before update of owner_id, kind, declared_size_bytes, reserved_bytes on public.upload_sessions
  for each row execute function public.guard_immutable('owner_id', 'kind', 'declared_size_bytes', 'reserved_bytes');

-- ---------------------------------------------------------------------------
-- updated_at triggers (append-only tables have none)
-- ---------------------------------------------------------------------------

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger invites_set_updated_at before update on public.invites
  for each row execute function public.set_updated_at();
create trigger devices_set_updated_at before update on public.devices
  for each row execute function public.set_updated_at();
create trigger covers_set_updated_at before update on public.covers
  for each row execute function public.set_updated_at();
create trigger artists_set_updated_at before update on public.artists
  for each row execute function public.set_updated_at();
create trigger albums_set_updated_at before update on public.albums
  for each row execute function public.set_updated_at();
create trigger tracks_set_updated_at before update on public.tracks
  for each row execute function public.set_updated_at();
create trigger upload_sessions_set_updated_at before update on public.upload_sessions
  for each row execute function public.set_updated_at();
create trigger jobs_set_updated_at before update on public.jobs
  for each row execute function public.set_updated_at();
create trigger playlists_set_updated_at before update on public.playlists
  for each row execute function public.set_updated_at();
create trigger playlist_items_set_updated_at before update on public.playlist_items
  for each row execute function public.set_updated_at();
create trigger playback_state_set_updated_at before update on public.playback_state
  for each row execute function public.set_updated_at();
create trigger downloads_set_updated_at before update on public.downloads
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row level security: enabled everywhere; policies for the API role only
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.invites enable row level security;
alter table public.devices enable row level security;
alter table public.covers enable row level security;
alter table public.artists enable row level security;
alter table public.albums enable row level security;
alter table public.tracks enable row level security;
alter table public.upload_sessions enable row level security;
alter table public.jobs enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_items enable row level security;
alter table public.favorites enable row level security;
alter table public.play_events enable row level security;
alter table public.playback_state enable row level security;
alter table public.downloads enable row level security;
alter table public.tombstones enable row level security;
alter table public.rate_limits enable row level security;

-- A member reads and updates only their own profile; profiles are created and
-- deleted on the owner connection (admin invites, purge_user).
create policy profiles_self_select on public.profiles
  for select to tunehold_app
  using (id = (select public.app_uid()));
create policy profiles_self_update on public.profiles
  for update to tunehold_app
  using (id = (select public.app_uid()))
  with check (id = (select public.app_uid()));

-- An invited user reads and accepts their own invite (POST /me/activate).
create policy invites_self_select on public.invites
  for select to tunehold_app
  using (profile_id = (select public.app_uid()));
create policy invites_self_update on public.invites
  for update to tunehold_app
  using (profile_id = (select public.app_uid()))
  with check (profile_id = (select public.app_uid()));

-- Every owner table: the caller's rows only, for reads and writes.
do $$
declare
  t text;
begin
  foreach t in array array[
    'devices', 'covers', 'artists', 'albums', 'tracks', 'upload_sessions', 'jobs',
    'playlists', 'playlist_items', 'favorites', 'play_events', 'playback_state',
    'downloads', 'tombstones'
  ] loop
    execute format(
      'create policy %I on public.%I for all to tunehold_app '
      || 'using (owner_id = (select public.app_uid())) '
      || 'with check (owner_id = (select public.app_uid()))',
      t || '_owner', t
    );
  end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- Grants and limits for the API role
-- ---------------------------------------------------------------------------

grant usage on schema public to tunehold_app;
grant usage on schema extensions to tunehold_app;
grant select, insert, update, delete on all tables in schema public to tunehold_app;
alter default privileges in schema public
  grant select, insert, update, delete on tables to tunehold_app;

revoke all on function public.rate_limit_hit(text, integer, integer) from public;
grant execute on function public.rate_limit_hit(text, integer, integer) to tunehold_app;

-- Bounded transactions keep the sync overlap (120 s) larger than any commit
-- delay. The code never does network I/O inside a transaction.
alter role tunehold_app set statement_timeout = '60s';
alter role tunehold_app set idle_in_transaction_session_timeout = '30s';
do $$
begin
  if current_setting('server_version_num')::integer >= 170000 then
    execute 'alter role tunehold_app set transaction_timeout = ''90s''';
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Supabase only (skipped on Neon or plain Postgres): take table grants away from
-- the Data API roles, and tie profiles to auth.users.
-- ---------------------------------------------------------------------------

do $$
declare
  r text;
begin
  foreach r in array array['anon', 'authenticated'] loop
    if exists (select 1 from pg_roles where rolname = r) then
      execute format('revoke all on all tables in schema public from %I', r);
      execute format('alter default privileges in schema public revoke all on tables from %I', r);
    end if;
  end loop;

  -- ON DELETE RESTRICT on purpose: a user is removed only through the purge_user
  -- job (objects in storage first, then rows, then the auth user), never by
  -- deleting the auth user in the dashboard and orphaning their files.
  if to_regclass('auth.users') is not null then
    alter table public.profiles
      add constraint profiles_auth_user_fkey foreign key (id)
      references auth.users (id) on delete restrict;
  end if;
end
$$;
