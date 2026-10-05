-- Tunehold: database schema, migration 0000.
--
-- Source of truth for packages/db/migrations/0000_init.sql (created with
-- `drizzle-kit generate --custom --name=init`, then this file pasted in).
-- Later migrations are plain SQL files next to it. Never run `drizzle-kit push`:
-- Drizzle cannot express ON DELETE SET NULL (column) and would drop those keys.
--
-- Target: Postgres 15 or later (Supabase Postgres 17 for dev and prod; Neon or a
-- plain Postgres 15+ also work). Needs PG15 for UNIQUE NULLS NOT DISTINCT and
-- ON DELETE SET NULL (column list). gen_random_uuid() is core since PG13.
--
-- Run on an empty database:
--   psql "$DATABASE_URL_DIRECT" -v ON_ERROR_STOP=1 --single-transaction -f replica/schema.sql
--
-- Validation status (2026-10-04): NOT EXECUTED. The architect session had no
-- shell and no Postgres, so this file has not been run against a server. The
-- first build task that adds packages/db must run the command above against a
-- throwaway Postgres 17 (CI service container or `supabase start`) and fix any
-- error before the slice starts.
--
-- ACCESS RULES: data-layer checks. Every query goes through owner-scoped
-- repository functions in apps/web/src/server that take ctx.userId from the
-- verified Supabase JWT. Backstops in the database:
--   1. Row level security is enabled on every table with NO policies, and the
--      Supabase Data API is switched off, so the anon and authenticated roles can
--      read or write nothing even if a key leaks. The server connects as the
--      table owner (postgres), which bypasses RLS.
--   2. Composite foreign keys (child.owner_id must equal the parent's owner_id)
--      on every link a user can name by id: playlist items, favorites,
--      downloads, play events, playback state, track groupings. A bug that
--      passes another user's id fails at the database, not only in tests.
--
-- Conventions: uuid ids; timestamptz in UTC; created_at and updated_at on rows
-- that change (updated_at drives the offline sync cursor, so a trigger keeps
-- it current); append-only rows (favorites, play_events, tombstones) have
-- created_at only. Byte counts are bigint. No money, plan or billing tables:
-- payments are deferred (replica/deferred.md).

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

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

-- ---------------------------------------------------------------------------
-- People: profiles (one per Supabase Auth user, includes the storage limit),
-- invites, devices
-- ---------------------------------------------------------------------------

-- id equals auth.users.id (the JWT "sub"), so it has no default.
-- Storage limit and usage live here, not in a separate table: the limit check is
-- one atomic UPDATE on this row (see architecture.md, "Storage limit").
--   used_bytes     = bytes of the user's stored audio objects (tracks not yet purged)
--   reserved_bytes = bytes promised to upload sessions that have not completed
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

-- One row per app install or browser. The id is generated on the device at first
-- launch (crypto.randomUUID), so registration is an idempotent upsert.
-- revoked_at: signed out remotely; at its next sync the device wipes its downloads.
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
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
-- track of an album shares one object. Objects: u/{owner}/c/{sha256}-600.webp
-- and -300.webp. Unreferenced covers are deleted by the library_cleanup job.
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
-- deletes the ones left empty (writing tombstones for offline devices).
-- name_key / title_key: grouping keys computed in packages/media (Unicode NFC,
-- lower case, trimmed, inner spaces collapsed; accents KEPT, so distinct names
-- are not merged). search_text drops accents for search only.
create table public.artists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 500),
  name_key text not null check (char_length(name_key) between 1 and 500),
  search_text text generated always as (public.search_norm(name)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint artists_owner_name_key unique (owner_id, name_key),
  constraint artists_id_owner_key unique (id, owner_id)
);
create index artists_owner_updated_idx on public.artists (owner_id, updated_at);
create index artists_search_trgm_idx on public.artists using gin (search_text extensions.gin_trgm_ops);

-- artist_id is the album artist (albumartist tag, "Various Artists" for
-- compilations, else the first track artist). NULL means the tags name no artist.
-- artist_name is a display copy so album search can match "title + artist".
create table public.albums (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  artist_id uuid,
  artist_name text,
  title text not null check (char_length(title) between 1 and 500),
  title_key text not null check (char_length(title_key) between 1 and 500),
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
create index albums_owner_title_idx on public.albums (owner_id, title_key, id);
create index albums_owner_created_idx on public.albums (owner_id, created_at desc, id);
create index albums_owner_updated_idx on public.albums (owner_id, updated_at);
create index albums_search_trgm_idx on public.albums using gin (search_text extensions.gin_trgm_ops);

-- One uploaded file. The stored object (object_key, u/{owner}/o/{id}.{ext}) is
-- written once and never rewritten: that is the bit-for-bit guarantee (F6).
-- The id is chosen at upload reservation, so it is part of the object key.
-- Duplicates are detected per user only (no cross-user deduplication):
-- unique (owner_id, content_md5) among rows that are not deleted.
--
-- status:
--   processing  stored and verified; tag and cover extraction pending
--   ready       playable
--   failed      stored, but the audio could not be parsed (status_reason says why)
--   disabled    access switched off: no signing, no manifest, removed from devices
--               at their next sync. The object is kept. No v1 UI sets it (the
--               takedown workflow is deferred); it exists so every read path
--               already honours it.
--   deleted     the user deleted it; hidden everywhere; the purge_track job deletes
--               the object, gives the bytes back and then deletes the row (which
--               writes a tombstone).
--
-- Tag columns hold the EFFECTIVE tags: from the file, overridden by the user's
-- edits (S19). tags_raw keeps what the file said; user_edited_fields lists the
-- columns a re-extract must not overwrite.
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
  title text not null check (char_length(title) between 1 and 1000),
  artist_name text check (char_length(artist_name) <= 1000),
  album_title text check (char_length(album_title) <= 1000),
  album_artist_name text check (char_length(album_artist_name) <= 1000),
  track_no smallint check (track_no >= 0),
  track_total smallint check (track_total >= 0),
  disc_no smallint check (disc_no >= 0),
  disc_total smallint check (disc_total >= 0),
  year smallint check (year between 0 and 9999),
  genre text check (char_length(genre) <= 200),
  is_compilation boolean not null default false,
  tags_raw jsonb not null default '{}'::jsonb check (jsonb_typeof(tags_raw) = 'object'),
  user_edited_fields text[] not null default '{}',

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
create index tracks_owner_status_created_idx on public.tracks (owner_id, status, created_at desc, id);
create index tracks_owner_title_idx on public.tracks (owner_id, lower(title), id);
create index tracks_owner_updated_idx on public.tracks (owner_id, updated_at);
create index tracks_owner_last_played_idx
  on public.tracks (owner_id, last_played_at desc) where last_played_at is not null;
create index tracks_album_order_idx on public.tracks (album_id, disc_no, track_no);
create index tracks_artist_id_idx on public.tracks (artist_id);
create index tracks_cover_id_idx on public.tracks (cover_id);
create index tracks_search_trgm_idx on public.tracks using gin (search_text extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- Uploads and jobs
-- ---------------------------------------------------------------------------

-- One file being uploaded straight to object storage (never through Vercel).
-- kind 'audio': planned_track_id is the future tracks.id, already in object_key.
-- kind 'cover': a cover.jpg / folder.jpg sidecar from a folder upload, stored at
--   u/{owner}/in/{session id}.{ext} until the apply_sidecar_cover job uses it.
-- mode 'single': one presigned PUT (web under 32 MB; mobile always, background
--   URLSession). mode 'multipart': S3 multipart, 16 MB parts (web, 32 MB and up).
--   s3_upload_id is created lazily by the first POST /uploads/:id/parts (row
--   locked), so a 500-file batch call makes no storage round trips.
-- part_md5s: hex MD5 of each part, sent by the client when it asks for part URLs;
--   compared with the ETags from ListParts at /complete.
-- status: pending (reserved, bytes may be moving) -> completing (a /complete call
--   is running) -> completed | failed | aborted | expired.
-- reserved_bytes is what this session added to profiles.reserved_bytes; it is
-- released exactly once, by the transition out of pending/completing.
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
  ext text not null check (char_length(ext) between 1 and 10),
  object_key text not null unique,
  mode text not null check (mode in ('single', 'multipart')),
  s3_upload_id text,
  part_size_bytes integer check (part_size_bytes > 0),
  part_count integer check (part_count between 1 and 10000),
  part_md5s text[],
  reserved_bytes bigint not null default 0 check (reserved_bytes >= 0),
  status text not null default 'pending'
    check (status in ('pending', 'completing', 'completed', 'failed', 'aborted', 'expired')),
  error_code text check (char_length(error_code) <= 60),
  error_message text check (char_length(error_message) <= 500),
  expires_at timestamptz not null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint upload_sessions_audio_has_planned_id check ((kind = 'audio') = (planned_track_id is not null)),
  constraint upload_sessions_track_matches_plan check (track_id is null or track_id = planned_track_id),
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
create index upload_sessions_track_id_idx on public.upload_sessions (track_id);

-- Postgres job queue, claimed with FOR UPDATE SKIP LOCKED. Run inline by
-- next/server after() and by the sweep route (GitHub Actions schedule + daily
-- Vercel cron). owner_id is NULL for system jobs and for purge_user, which must
-- outlive the profile it deletes.
-- dedupe_key makes enqueueing idempotent ('extract:{trackId}', 'purge_track:{trackId}', ...).
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
-- playlist_items. cover_id NULL means the UI draws a mosaic of album covers.
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
  constraint playlists_cover_fkey foreign key (cover_id, owner_id)
    references public.covers (id, owner_id) on delete set null (cover_id)
);
create index playlists_owner_updated_idx on public.playlists (owner_id, updated_at desc);
create index playlists_owner_name_idx on public.playlists (owner_id, lower(name), id);
create index playlists_cover_id_idx on public.playlists (cover_id);
create index playlists_search_trgm_idx on public.playlists using gin (search_text extensions.gin_trgm_ops);

-- Ordering by fractional index keys (base-62 strings from the fractional-indexing
-- package), compared bytewise (COLLATE "C"). A move or an insert between two
-- items is ONE row update: the server picks a key between the neighbours' keys.
-- Two concurrent moves into the same gap produce the same key, hit the unique
-- index, and the server retries once with fresh neighbours.
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
  constraint playlist_items_order_key unique (playlist_id, sort_key)
);
create index playlist_items_track_id_idx on public.playlist_items (track_id);
create index playlist_items_owner_updated_idx on public.playlist_items (owner_id, updated_at);

-- The recon's "Like". The UI label is a brand decision (brand.md: "Favorites" or
-- "Keepers"); the identifier stays "favorites" either way.
create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  track_id uuid not null,
  created_at timestamptz not null default now(),
  constraint favorites_owner_track_key unique (owner_id, track_id),
  constraint favorites_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete cascade
);
create index favorites_owner_created_idx on public.favorites (owner_id, created_at desc, id);
create index favorites_track_id_idx on public.favorites (track_id);

-- ---------------------------------------------------------------------------
-- Listening: play events, playback state
-- ---------------------------------------------------------------------------

-- Append-only listening history (F8). The id is generated on the device, so the
-- offline outbox can retry safely (INSERT ... ON CONFLICT (id) DO NOTHING).
-- counted: the play met the play rule (30 s, or half the track if shorter);
-- only counted plays add to tracks.play_count.
-- played_at is UTC. client_tz is the device's IANA zone at play time: history is
-- the only place Tunehold shows local times.
-- The title/artist/album snapshot keeps history readable after the track is
-- deleted or its tags are edited.
create table public.play_events (
  id uuid primary key,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  track_id uuid,
  device_id uuid references public.devices (id) on delete set null,
  played_at timestamptz not null,
  ms_played integer not null check (ms_played >= 0),
  counted boolean not null,
  context_type text check (context_type in
    ('album', 'artist', 'playlist', 'favorites', 'library', 'search', 'queue')),
  context_id uuid,
  client_tz text check (char_length(client_tz) <= 64),
  track_title text not null check (char_length(track_title) between 1 and 1000),
  artist_name text check (char_length(artist_name) <= 1000),
  album_title text check (char_length(album_title) <= 1000),
  created_at timestamptz not null default now(),
  constraint play_events_track_fkey foreign key (track_id, owner_id)
    references public.tracks (id, owner_id) on delete set null (track_id),
  constraint play_events_not_future check (played_at <= created_at + interval '1 day')
);
create index play_events_owner_played_idx on public.play_events (owner_id, played_at desc);
create index play_events_track_id_idx on public.play_events (track_id);
create index play_events_device_id_idx on public.play_events (device_id);

-- One row per user: what is playing and what plays next, synced across devices
-- with optimistic concurrency (PUT with If-Match: version). This is the
-- PlaybackState fixes.md asks for before F4.
--   context_*        what was started: album, playlist, favorites, artist, the whole
--                    library (with its sort), search results (ids frozen in
--                    context_track_ids, at most 1000), or only the user queue.
--   context_cursor   natural order: the sort key of the current context member;
--                    the next one is the first member whose key is greater.
--   current_item_id  playlist item id, so a track listed twice resolves.
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
  device_id uuid references public.devices (id) on delete set null,
  context_type text check (context_type in
    ('album', 'artist', 'playlist', 'favorites', 'library', 'search', 'queue')),
  context_id uuid,
  context_sort text check (char_length(context_sort) <= 40),
  context_track_ids uuid[],
  context_cursor text collate "C" check (char_length(context_cursor) <= 200),
  current_track_id uuid,
  current_item_id uuid,
  position_ms integer not null default 0 check (position_ms >= 0),
  user_queue jsonb not null default '[]'::jsonb check (jsonb_typeof(user_queue) = 'array'),
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
  constraint playback_state_current_track_fkey foreign key (current_track_id, owner_id)
    references public.tracks (id, owner_id) on delete set null (current_track_id)
);
create index playback_state_device_id_idx on public.playback_state (device_id);
create index playback_state_current_track_idx on public.playback_state (current_track_id);

-- ---------------------------------------------------------------------------
-- Offline: downloads registry and tombstones
-- ---------------------------------------------------------------------------

-- What each device has confirmed it holds (downloaded, size and MD5 verified).
-- The device's own expo-sqlite index is authoritative for playback; this table
-- lets the web settings page show downloads per device and lets a lost device be
-- revoked. There is no device cap at personal scale.
-- scope says why the file is there (one track, an album, a playlist, favorites or
-- the whole library); a track held for two scopes keeps the first.
create table public.downloads (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  device_id uuid not null,
  track_id uuid not null,
  scope_type text not null check (scope_type in ('track', 'album', 'playlist', 'favorites', 'library')),
  scope_id uuid,
  size_bytes bigint not null check (size_bytes > 0),
  verified_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint downloads_device_track_key unique (device_id, track_id),
  constraint downloads_scope_id_required check (
    (scope_type in ('track', 'album', 'playlist')) = (scope_id is not null)
  ),
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
create index tombstones_owner_created_idx on public.tombstones (owner_id, created_at);
create index tombstones_created_idx on public.tombstones (created_at);

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
-- Row level security: enabled everywhere, no policies (deny-all backstop)
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

-- Supabase only (skipped on Neon or plain Postgres): take table grants away from
-- the API roles as a second layer, and tie profiles to auth.users.
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
