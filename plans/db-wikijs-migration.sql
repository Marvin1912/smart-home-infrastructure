-- Migration: Move Wiki.js tables from public to wikijs schema
-- This script creates the wikijs schema and all required objects

-- Step 1: Create the wikijs schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS wikijs;

-- Step 2: Create sequences in wikijs schema
CREATE SEQUENCE IF NOT EXISTS wikijs."apiKeys_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."assetFolders_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.assets_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.comments_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.groups_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.migrations_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.migrations_lock_index_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."pageHistoryTags_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."pageHistory_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."pageLinks_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."pageTags_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.pages_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.tags_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."userGroups_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs."userKeys_id_seq" AS integer;
CREATE SEQUENCE IF NOT EXISTS wikijs.users_id_seq AS integer;

-- Step 3: Create tables in wikijs schema

CREATE TABLE wikijs.analytics (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json NOT NULL,
  CONSTRAINT wikijs_analytics_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs."apiKeys" (
  id integer NOT NULL DEFAULT nextval('wikijs."apiKeys_id_seq"'::regclass),
  name varchar(255) NOT NULL,
  key text NOT NULL,
  expiration varchar(255) NOT NULL,
  "isRevoked" boolean NOT NULL DEFAULT false,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  CONSTRAINT wikijs_apiKeys_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."assetData" (
  id integer NOT NULL,
  data bytea NOT NULL,
  CONSTRAINT wikijs_assetData_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."assetFolders" (
  id integer NOT NULL DEFAULT nextval('wikijs."assetFolders_id_seq"'::regclass),
  name varchar(255) NOT NULL,
  slug varchar(255) NOT NULL,
  "parentId" integer,
  CONSTRAINT wikijs_assetFolders_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.assets (
  id integer NOT NULL DEFAULT nextval('wikijs.assets_id_seq'::regclass),
  filename varchar(255) NOT NULL,
  hash varchar(255) NOT NULL,
  ext varchar(255) NOT NULL,
  kind text NOT NULL DEFAULT 'binary'::text,
  mime varchar(255) NOT NULL DEFAULT 'application/octet-stream'::character varying,
  "fileSize" integer,
  metadata json,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  "folderId" integer,
  "authorId" integer,
  CONSTRAINT wikijs_assets_pkey PRIMARY KEY (id),
  CONSTRAINT wikijs_assets_kind_check CHECK (kind = ANY (ARRAY['binary'::text, 'image'::text]))
);

CREATE TABLE wikijs.authentication (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json NOT NULL,
  "selfRegistration" boolean NOT NULL DEFAULT false,
  "domainWhitelist" json NOT NULL,
  "autoEnrollGroups" json NOT NULL,
  "order" integer NOT NULL DEFAULT 0,
  "strategyKey" varchar(255) NOT NULL DEFAULT ''::character varying,
  "displayName" varchar(255) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT wikijs_authentication_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.brute (
  key varchar(255),
  "firstRequest" bigint,
  "lastRequest" bigint,
  lifetime bigint,
  count integer
);

CREATE TABLE wikijs."commentProviders" (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json NOT NULL,
  CONSTRAINT wikijs_commentProviders_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.comments (
  id integer NOT NULL DEFAULT nextval('wikijs.comments_id_seq'::regclass),
  content text NOT NULL,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  "pageId" integer,
  "authorId" integer,
  render text NOT NULL DEFAULT ''::text,
  name varchar(255) NOT NULL DEFAULT ''::character varying,
  email varchar(255) NOT NULL DEFAULT ''::character varying,
  ip varchar(255) NOT NULL DEFAULT ''::character varying,
  "replyTo" integer NOT NULL DEFAULT 0,
  CONSTRAINT wikijs_comments_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.editors (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json NOT NULL,
  CONSTRAINT wikijs_editors_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.flyway_schema_history (
  installed_rank integer NOT NULL,
  version varchar(50),
  description varchar(200) NOT NULL,
  type varchar(20) NOT NULL,
  script varchar(1000) NOT NULL,
  checksum integer,
  installed_by varchar(100) NOT NULL,
  installed_on timestamp without time zone NOT NULL DEFAULT now(),
  execution_time integer NOT NULL,
  success boolean NOT NULL,
  CONSTRAINT wikijs_flyway_schema_history_pk PRIMARY KEY (installed_rank)
);

CREATE TABLE wikijs.groups (
  id integer NOT NULL DEFAULT nextval('wikijs.groups_id_seq'::regclass),
  name varchar(255) NOT NULL,
  permissions json NOT NULL,
  "pageRules" json NOT NULL,
  "isSystem" boolean NOT NULL DEFAULT false,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  "redirectOnLogin" varchar(255) NOT NULL DEFAULT '/'::character varying,
  CONSTRAINT wikijs_groups_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.locales (
  code varchar(5) NOT NULL,
  strings json,
  "isRTL" boolean NOT NULL DEFAULT false,
  name varchar(255) NOT NULL,
  "nativeName" varchar(255) NOT NULL,
  availability integer NOT NULL DEFAULT 0,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  CONSTRAINT wikijs_locales_pkey PRIMARY KEY (code)
);

CREATE TABLE wikijs.loggers (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  level varchar(255) NOT NULL DEFAULT 'warn'::character varying,
  config json,
  CONSTRAINT wikijs_loggers_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.migrations (
  id integer NOT NULL DEFAULT nextval('wikijs.migrations_id_seq'::regclass),
  name varchar(255),
  batch integer,
  migration_time timestamptz,
  CONSTRAINT wikijs_migrations_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.migrations_lock (
  index integer NOT NULL DEFAULT nextval('wikijs.migrations_lock_index_seq'::regclass),
  is_locked integer,
  CONSTRAINT wikijs_migrations_lock_pkey PRIMARY KEY (index)
);

CREATE TABLE wikijs.navigation (
  key varchar(255) NOT NULL,
  config json,
  CONSTRAINT wikijs_navigation_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs."pageHistory" (
  id integer NOT NULL DEFAULT nextval('wikijs."pageHistory_id_seq"'::regclass),
  path varchar(255) NOT NULL,
  hash varchar(255) NOT NULL,
  title varchar(255) NOT NULL,
  description varchar(255),
  "isPrivate" boolean NOT NULL DEFAULT false,
  "isPublished" boolean NOT NULL DEFAULT false,
  "publishStartDate" varchar(255),
  "publishEndDate" varchar(255),
  action varchar(255) DEFAULT 'updated'::character varying,
  "pageId" integer,
  content text,
  "contentType" varchar(255) NOT NULL,
  "createdAt" varchar(255) NOT NULL,
  "editorKey" varchar(255),
  "localeCode" varchar(5),
  "authorId" integer,
  "versionDate" varchar(255) NOT NULL DEFAULT ''::character varying,
  extra json NOT NULL DEFAULT '{}'::json,
  CONSTRAINT wikijs_pageHistory_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."pageHistoryTags" (
  id integer NOT NULL DEFAULT nextval('wikijs."pageHistoryTags_id_seq"'::regclass),
  "pageId" integer,
  "tagId" integer,
  CONSTRAINT wikijs_pageHistoryTags_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."pageLinks" (
  id integer NOT NULL DEFAULT nextval('wikijs."pageLinks_id_seq"'::regclass),
  path varchar(255) NOT NULL,
  "localeCode" varchar(5) NOT NULL,
  "pageId" integer,
  CONSTRAINT wikijs_pageLinks_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."pageTags" (
  id integer NOT NULL DEFAULT nextval('wikijs."pageTags_id_seq"'::regclass),
  "pageId" integer,
  "tagId" integer,
  CONSTRAINT wikijs_pageTags_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."pageTree" (
  id integer NOT NULL,
  path varchar(255) NOT NULL,
  depth integer NOT NULL,
  title varchar(255) NOT NULL,
  "isPrivate" boolean NOT NULL DEFAULT false,
  "isFolder" boolean NOT NULL DEFAULT false,
  "privateNS" varchar(255),
  parent integer,
  "pageId" integer,
  "localeCode" varchar(5),
  ancestors json,
  CONSTRAINT wikijs_pageTree_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.pages (
  id integer NOT NULL DEFAULT nextval('wikijs.pages_id_seq'::regclass),
  path varchar(255) NOT NULL,
  hash varchar(255) NOT NULL,
  title varchar(255) NOT NULL,
  description varchar(255),
  "isPrivate" boolean NOT NULL DEFAULT false,
  "isPublished" boolean NOT NULL DEFAULT false,
  "privateNS" varchar(255),
  "publishStartDate" varchar(255),
  "publishEndDate" varchar(255),
  content text,
  render text,
  toc json,
  "contentType" varchar(255) NOT NULL,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  "editorKey" varchar(255),
  "localeCode" varchar(5),
  "authorId" integer,
  "creatorId" integer,
  extra json NOT NULL DEFAULT '{}'::json,
  CONSTRAINT wikijs_pages_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.renderers (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json,
  CONSTRAINT wikijs_renderers_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs."searchEngines" (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  config json,
  CONSTRAINT wikijs_searchEngines_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.sessions (
  sid varchar(255) NOT NULL,
  sess json NOT NULL,
  expired timestamptz NOT NULL,
  CONSTRAINT wikijs_sessions_pkey PRIMARY KEY (sid)
);

CREATE TABLE wikijs.settings (
  key varchar(255) NOT NULL,
  value json,
  "updatedAt" varchar(255) NOT NULL,
  CONSTRAINT wikijs_settings_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.storage (
  key varchar(255) NOT NULL,
  "isEnabled" boolean NOT NULL DEFAULT false,
  mode varchar(255) NOT NULL DEFAULT 'push'::character varying,
  config json,
  "syncInterval" varchar(255),
  state json,
  CONSTRAINT wikijs_storage_pkey PRIMARY KEY (key)
);

CREATE TABLE wikijs.tags (
  id integer NOT NULL DEFAULT nextval('wikijs.tags_id_seq'::regclass),
  tag varchar(255) NOT NULL,
  title varchar(255),
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  CONSTRAINT wikijs_tags_pkey PRIMARY KEY (id),
  CONSTRAINT wikijs_tags_tag_unique UNIQUE (tag)
);

CREATE TABLE wikijs."userAvatars" (
  id integer NOT NULL,
  data bytea NOT NULL,
  CONSTRAINT wikijs_userAvatars_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."userGroups" (
  id integer NOT NULL DEFAULT nextval('wikijs."userGroups_id_seq"'::regclass),
  "userId" integer,
  "groupId" integer,
  CONSTRAINT wikijs_userGroups_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs."userKeys" (
  id integer NOT NULL DEFAULT nextval('wikijs."userKeys_id_seq"'::regclass),
  kind varchar(255) NOT NULL,
  token varchar(255) NOT NULL,
  "createdAt" varchar(255) NOT NULL,
  "validUntil" varchar(255) NOT NULL,
  "userId" integer,
  CONSTRAINT wikijs_userKeys_pkey PRIMARY KEY (id)
);

CREATE TABLE wikijs.users (
  id integer NOT NULL DEFAULT nextval('wikijs.users_id_seq'::regclass),
  email varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  "providerId" varchar(255),
  password varchar(255),
  "tfaIsActive" boolean NOT NULL DEFAULT false,
  "tfaSecret" varchar(255),
  "jobTitle" varchar(255) DEFAULT ''::character varying,
  location varchar(255) DEFAULT ''::character varying,
  "pictureUrl" varchar(255),
  timezone varchar(255) NOT NULL DEFAULT 'America/New_York'::character varying,
  "isSystem" boolean NOT NULL DEFAULT false,
  "isActive" boolean NOT NULL DEFAULT false,
  "isVerified" boolean NOT NULL DEFAULT false,
  "mustChangePwd" boolean NOT NULL DEFAULT false,
  "createdAt" varchar(255) NOT NULL,
  "updatedAt" varchar(255) NOT NULL,
  "providerKey" varchar(255) NOT NULL DEFAULT 'local'::character varying,
  "localeCode" varchar(5) NOT NULL DEFAULT 'en'::character varying,
  "defaultEditor" varchar(255) NOT NULL DEFAULT 'markdown'::character varying,
  "lastLoginAt" varchar(255),
  "dateFormat" varchar(255) NOT NULL DEFAULT ''::character varying,
  appearance varchar(255) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT wikijs_users_pkey PRIMARY KEY (id),
  CONSTRAINT wikijs_users_providerkey_email_unique UNIQUE ("providerKey", email)
);

-- Step 4: Add foreign key constraints
ALTER TABLE wikijs."assetFolders" ADD CONSTRAINT wikijs_assetfolders_parentid_foreign FOREIGN KEY ("parentId") REFERENCES wikijs."assetFolders"(id);
ALTER TABLE wikijs.assets ADD CONSTRAINT wikijs_assets_authorid_foreign FOREIGN KEY ("authorId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs.assets ADD CONSTRAINT wikijs_assets_folderid_foreign FOREIGN KEY ("folderId") REFERENCES wikijs."assetFolders"(id);
ALTER TABLE wikijs.comments ADD CONSTRAINT wikijs_comments_authorid_foreign FOREIGN KEY ("authorId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs.comments ADD CONSTRAINT wikijs_comments_pageid_foreign FOREIGN KEY ("pageId") REFERENCES wikijs.pages(id);
ALTER TABLE wikijs."pageHistory" ADD CONSTRAINT wikijs_pagehistory_authorid_foreign FOREIGN KEY ("authorId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs."pageHistory" ADD CONSTRAINT wikijs_pagehistory_editorkey_foreign FOREIGN KEY ("editorKey") REFERENCES wikijs.editors(key);
ALTER TABLE wikijs."pageHistory" ADD CONSTRAINT wikijs_pagehistory_localecode_foreign FOREIGN KEY ("localeCode") REFERENCES wikijs.locales(code);
ALTER TABLE wikijs."pageHistoryTags" ADD CONSTRAINT wikijs_pagehistorytags_pageid_foreign FOREIGN KEY ("pageId") REFERENCES wikijs."pageHistory"(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageHistoryTags" ADD CONSTRAINT wikijs_pagehistorytags_tagid_foreign FOREIGN KEY ("tagId") REFERENCES wikijs.tags(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageLinks" ADD CONSTRAINT wikijs_pagelinks_pageid_foreign FOREIGN KEY ("pageId") REFERENCES wikijs.pages(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageTags" ADD CONSTRAINT wikijs_pagetags_pageid_foreign FOREIGN KEY ("pageId") REFERENCES wikijs.pages(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageTags" ADD CONSTRAINT wikijs_pagetags_tagid_foreign FOREIGN KEY ("tagId") REFERENCES wikijs.tags(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageTree" ADD CONSTRAINT wikijs_pagetree_localecode_foreign FOREIGN KEY ("localeCode") REFERENCES wikijs.locales(code);
ALTER TABLE wikijs."pageTree" ADD CONSTRAINT wikijs_pagetree_pageid_foreign FOREIGN KEY ("pageId") REFERENCES wikijs.pages(id) ON DELETE CASCADE;
ALTER TABLE wikijs."pageTree" ADD CONSTRAINT wikijs_pagetree_parent_foreign FOREIGN KEY (parent) REFERENCES wikijs."pageTree"(id) ON DELETE CASCADE;
ALTER TABLE wikijs.pages ADD CONSTRAINT wikijs_pages_authorid_foreign FOREIGN KEY ("authorId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs.pages ADD CONSTRAINT wikijs_pages_creatorid_foreign FOREIGN KEY ("creatorId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs.pages ADD CONSTRAINT wikijs_pages_editorkey_foreign FOREIGN KEY ("editorKey") REFERENCES wikijs.editors(key);
ALTER TABLE wikijs.pages ADD CONSTRAINT wikijs_pages_localecode_foreign FOREIGN KEY ("localeCode") REFERENCES wikijs.locales(code);
ALTER TABLE wikijs."userGroups" ADD CONSTRAINT wikijs_usergroups_groupid_foreign FOREIGN KEY ("groupId") REFERENCES wikijs.groups(id) ON DELETE CASCADE;
ALTER TABLE wikijs."userGroups" ADD CONSTRAINT wikijs_usergroups_userid_foreign FOREIGN KEY ("userId") REFERENCES wikijs.users(id) ON DELETE CASCADE;
ALTER TABLE wikijs."userKeys" ADD CONSTRAINT wikijs_userkeys_userid_foreign FOREIGN KEY ("userId") REFERENCES wikijs.users(id);
ALTER TABLE wikijs.users ADD CONSTRAINT wikijs_users_defaulteditor_foreign FOREIGN KEY ("defaultEditor") REFERENCES wikijs.editors(key);
ALTER TABLE wikijs.users ADD CONSTRAINT wikijs_users_localecode_foreign FOREIGN KEY ("localeCode") REFERENCES wikijs.locales(code);
ALTER TABLE wikijs.users ADD CONSTRAINT wikijs_users_providerkey_foreign FOREIGN KEY ("providerKey") REFERENCES wikijs.authentication(key);

-- Step 5: Create indexes
CREATE INDEX wikijs_flyway_schema_history_s_idx ON wikijs.flyway_schema_history USING btree (success);
CREATE INDEX wikijs_pagelinks_path_localecode_index ON wikijs."pageLinks" USING btree (path, "localeCode");
CREATE INDEX wikijs_sessions_expired_index ON wikijs.sessions USING btree (expired);
