# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `linkwarden`

## Table Inventory by Application (Best-Effort)

### Linkwarden (schema: `linkwarden`)

- `AccessToken`
- `Account`
- `AppMigration`
- `Collection`
- `DashboardSection`
- `Highlight`
- `Link`
- `PasswordResetToken`
- `RssSubscription`
- `Subscription`
- `Tag`
- `User`
- `UsersAndCollections`
- `VerificationToken`
- `WhitelistedUser`
- `_LinkToTag`
- `_PinnedLinks`
- `_prisma_migrations`

## Target Schema Split DDL (Proposed)

Notes:

- DDL is derived from current catalog.

```sql
CREATE SCHEMA IF NOT EXISTS linkwarden;

CREATE TYPE linkwarden."AiTaggingMethod" AS ENUM ('DISABLED', 'GENERATE', 'PREDEFINED', 'EXISTING');
CREATE TYPE linkwarden."AppMigrationStatus" AS ENUM ('APPLIED', 'PENDING', 'FAILED');
CREATE TYPE linkwarden."DashboardSectionType" AS ENUM ('STATS', 'RECENT_LINKS', 'PINNED_LINKS', 'COLLECTION');
CREATE TYPE linkwarden."LinksRouteTo" AS ENUM ('ORIGINAL', 'PDF', 'READABLE', 'MONOLITH', 'SCREENSHOT', 'DETAILS');
CREATE TYPE linkwarden."Theme" AS ENUM ('dark', 'light', 'auto');

CREATE SEQUENCE linkwarden."AccessToken_id_seq" AS integer;
CREATE SEQUENCE linkwarden."AppMigration_id_seq" AS integer;
CREATE SEQUENCE linkwarden."Collection_id_seq" AS integer;
CREATE SEQUENCE linkwarden."DashboardSection_id_seq" AS integer;
CREATE SEQUENCE linkwarden."Highlight_id_seq" AS integer;
CREATE SEQUENCE linkwarden."Link_id_seq" AS integer;
CREATE SEQUENCE linkwarden."RssSubscription_id_seq" AS integer;
CREATE SEQUENCE linkwarden."Subscription_id_seq" AS integer;
CREATE SEQUENCE linkwarden."Tag_id_seq" AS integer;
CREATE SEQUENCE linkwarden."User_id_seq" AS integer;
CREATE SEQUENCE linkwarden."WhitelistedUser_id_seq" AS integer;

CREATE TABLE linkwarden."AccessToken" (
  id integer NOT NULL DEFAULT nextval('linkwarden."AccessToken_id_seq"'::regclass),
  name text NOT NULL,
  "userId" integer NOT NULL,
  token text NOT NULL,
  revoked boolean NOT NULL DEFAULT false,
  expires timestamp(3) without time zone NOT NULL,
  "lastUsedAt" timestamp(3) without time zone,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "isSession" boolean NOT NULL DEFAULT false,
  CONSTRAINT "AccessToken_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Account" (
  id text NOT NULL,
  "userId" integer NOT NULL,
  type text NOT NULL,
  provider text NOT NULL,
  "providerAccountId" text NOT NULL,
  refresh_token text,
  access_token text,
  expires_at integer,
  token_type text,
  scope text,
  id_token text,
  session_state text,
  CONSTRAINT "Account_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."AppMigration" (
  id integer NOT NULL DEFAULT nextval('linkwarden."AppMigration_id_seq"'::regclass),
  name text NOT NULL,
  status linkwarden."AppMigrationStatus" NOT NULL,
  "finishedAt" timestamp(3) without time zone,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AppMigration_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Collection" (
  id integer NOT NULL DEFAULT nextval('linkwarden."Collection_id_seq"'::regclass),
  name text NOT NULL,
  description text NOT NULL DEFAULT ''::text,
  color text NOT NULL DEFAULT '#0ea5e9'::text,
  "isPublic" boolean NOT NULL DEFAULT false,
  "ownerId" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "parentId" integer,
  icon text,
  "iconWeight" text,
  "createdById" integer,
  CONSTRAINT "Collection_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."DashboardSection" (
  id integer NOT NULL DEFAULT nextval('linkwarden."DashboardSection_id_seq"'::regclass),
  "userId" integer NOT NULL,
  "collectionId" integer,
  type linkwarden."DashboardSectionType" NOT NULL,
  "order" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DashboardSection_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Highlight" (
  id integer NOT NULL DEFAULT nextval('linkwarden."Highlight_id_seq"'::regclass),
  color text NOT NULL,
  comment text,
  "linkId" integer NOT NULL,
  "userId" integer NOT NULL,
  "startOffset" integer NOT NULL,
  "endOffset" integer NOT NULL,
  text text NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Highlight_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Link" (
  id integer NOT NULL DEFAULT nextval('linkwarden."Link_id_seq"'::regclass),
  name text NOT NULL DEFAULT ''::text,
  url text,
  description text NOT NULL DEFAULT ''::text,
  "collectionId" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  pdf text,
  image text,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  readable text,
  "lastPreserved" timestamp(3) without time zone,
  "textContent" text,
  type text NOT NULL DEFAULT 'url'::text,
  preview text,
  "importDate" timestamp(3) without time zone,
  monolith text,
  color text,
  icon text,
  "iconWeight" text,
  "createdById" integer,
  "aiTagged" boolean NOT NULL DEFAULT false,
  "indexVersion" integer,
  "clientSide" boolean NOT NULL DEFAULT false,
  CONSTRAINT "Link_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."PasswordResetToken" (
  identifier text NOT NULL,
  token text NOT NULL,
  expires timestamp(3) without time zone NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE linkwarden."RssSubscription" (
  id integer NOT NULL DEFAULT nextval('linkwarden."RssSubscription_id_seq"'::regclass),
  url text NOT NULL,
  name text NOT NULL,
  "lastBuildDate" timestamp(3) without time zone,
  "collectionId" integer NOT NULL,
  "ownerId" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "RssSubscription_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Subscription" (
  id integer NOT NULL DEFAULT nextval('linkwarden."Subscription_id_seq"'::regclass),
  active boolean NOT NULL,
  "stripeSubscriptionId" text NOT NULL,
  "currentPeriodStart" timestamp(3) without time zone NOT NULL,
  "currentPeriodEnd" timestamp(3) without time zone NOT NULL,
  "userId" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  quantity integer NOT NULL DEFAULT 1,
  CONSTRAINT "Subscription_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."Tag" (
  id integer NOT NULL DEFAULT nextval('linkwarden."Tag_id_seq"'::regclass),
  name text NOT NULL,
  "ownerId" integer NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "archiveAsMonolith" boolean,
  "archiveAsPDF" boolean,
  "archiveAsReadable" boolean,
  "archiveAsScreenshot" boolean,
  "archiveAsWaybackMachine" boolean,
  "aiTag" boolean,
  "aiGenerated" boolean NOT NULL DEFAULT false,
  CONSTRAINT "Tag_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."User" (
  id integer NOT NULL DEFAULT nextval('linkwarden."User_id_seq"'::regclass),
  name text,
  username text,
  email text,
  "emailVerified" timestamp(3) without time zone,
  password text,
  "isPrivate" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "archiveAsPDF" boolean NOT NULL DEFAULT true,
  "archiveAsScreenshot" boolean NOT NULL DEFAULT true,
  "archiveAsWaybackMachine" boolean NOT NULL DEFAULT false,
  image text,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "linksRouteTo" linkwarden."LinksRouteTo" NOT NULL DEFAULT 'ORIGINAL'::linkwarden."LinksRouteTo",
  "collectionOrder" integer[] DEFAULT ARRAY[]::integer[],
  "preventDuplicateLinks" boolean NOT NULL DEFAULT false,
  "unverifiedNewEmail" text,
  locale text NOT NULL DEFAULT 'en'::text,
  "archiveAsMonolith" boolean NOT NULL DEFAULT true,
  "parentSubscriptionId" integer,
  "referredBy" text,
  "aiPredefinedTags" text[] DEFAULT ARRAY[]::text[],
  "aiTaggingMethod" linkwarden."AiTaggingMethod" NOT NULL DEFAULT 'DISABLED'::linkwarden."AiTaggingMethod",
  "aiTagExistingLinks" boolean NOT NULL DEFAULT false,
  "archiveAsReadable" boolean NOT NULL DEFAULT true,
  "readableFontFamily" text DEFAULT 'sans-serif'::text,
  "readableFontSize" text DEFAULT '20px'::text,
  "readableLineHeight" text DEFAULT '1.8'::text,
  "readableLineWidth" text DEFAULT 'normal'::text,
  theme linkwarden."Theme" NOT NULL DEFAULT 'dark'::linkwarden."Theme",
  "lastPickedAt" timestamp(3) without time zone,
  "acceptPromotionalEmails" boolean NOT NULL DEFAULT false,
  "trialEndEmailSent" boolean NOT NULL DEFAULT false,
  CONSTRAINT "User_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."UsersAndCollections" (
  "userId" integer NOT NULL,
  "collectionId" integer NOT NULL,
  "canCreate" boolean NOT NULL,
  "canUpdate" boolean NOT NULL,
  "canDelete" boolean NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UsersAndCollections_pkey" PRIMARY KEY ("userId", "collectionId")
);

CREATE TABLE linkwarden."VerificationToken" (
  identifier text NOT NULL,
  token text NOT NULL,
  expires timestamp(3) without time zone NOT NULL,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE linkwarden."WhitelistedUser" (
  id integer NOT NULL DEFAULT nextval('linkwarden."WhitelistedUser_id_seq"'::regclass),
  username text NOT NULL DEFAULT ''::text,
  "userId" integer,
  "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "WhitelistedUser_pkey" PRIMARY KEY (id)
);

CREATE TABLE linkwarden."_LinkToTag" (
  "A" integer NOT NULL,
  "B" integer NOT NULL,
  CONSTRAINT "_LinkToTag_AB_pkey" PRIMARY KEY ("A", "B")
);

CREATE TABLE linkwarden."_PinnedLinks" (
  "A" integer NOT NULL,
  "B" integer NOT NULL,
  CONSTRAINT "_PinnedLinks_AB_pkey" PRIMARY KEY ("A", "B")
);

CREATE TABLE linkwarden._prisma_migrations (
  id varchar(36) NOT NULL,
  checksum varchar(64) NOT NULL,
  finished_at timestamptz,
  migration_name varchar(255) NOT NULL,
  logs text,
  rolled_back_at timestamptz,
  started_at timestamptz NOT NULL DEFAULT now(),
  applied_steps_count integer NOT NULL DEFAULT 0,
  CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id)
);

ALTER TABLE linkwarden."AccessToken" ADD CONSTRAINT "AccessToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Collection" ADD CONSTRAINT "Collection_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE linkwarden."Collection" ADD CONSTRAINT "Collection_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Collection" ADD CONSTRAINT "Collection_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES linkwarden."Collection"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."DashboardSection" ADD CONSTRAINT "DashboardSection_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES linkwarden."Collection"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."DashboardSection" ADD CONSTRAINT "DashboardSection_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Highlight" ADD CONSTRAINT "Highlight_linkId_fkey" FOREIGN KEY ("linkId") REFERENCES linkwarden."Link"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Highlight" ADD CONSTRAINT "Highlight_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Link" ADD CONSTRAINT "Link_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES linkwarden."Collection"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Link" ADD CONSTRAINT "Link_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."RssSubscription" ADD CONSTRAINT "RssSubscription_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES linkwarden."Collection"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Subscription" ADD CONSTRAINT "Subscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."Tag" ADD CONSTRAINT "Tag_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."User" ADD CONSTRAINT "User_parentSubscriptionId_fkey" FOREIGN KEY ("parentSubscriptionId") REFERENCES linkwarden."Subscription"(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE linkwarden."UsersAndCollections" ADD CONSTRAINT "UsersAndCollections_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES linkwarden."Collection"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."UsersAndCollections" ADD CONSTRAINT "UsersAndCollections_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."WhitelistedUser" ADD CONSTRAINT "WhitelistedUser_userId_fkey" FOREIGN KEY ("userId") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."_LinkToTag" ADD CONSTRAINT "_LinkToTag_A_fkey" FOREIGN KEY ("A") REFERENCES linkwarden."Link"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."_LinkToTag" ADD CONSTRAINT "_LinkToTag_B_fkey" FOREIGN KEY ("B") REFERENCES linkwarden."Tag"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."_PinnedLinks" ADD CONSTRAINT "_PinnedLinks_A_fkey" FOREIGN KEY ("A") REFERENCES linkwarden."Link"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE linkwarden."_PinnedLinks" ADD CONSTRAINT "_PinnedLinks_B_fkey" FOREIGN KEY ("B") REFERENCES linkwarden."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE UNIQUE INDEX "AccessToken_token_key" ON linkwarden."AccessToken" USING btree (token);
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON linkwarden."Account" USING btree (provider, "providerAccountId");
CREATE UNIQUE INDEX "AppMigration_name_key" ON linkwarden."AppMigration" USING btree (name);
CREATE INDEX "Collection_ownerId_idx" ON linkwarden."Collection" USING btree ("ownerId");
CREATE UNIQUE INDEX "DashboardSection_userId_collectionId_key" ON linkwarden."DashboardSection" USING btree ("userId", "collectionId");
CREATE INDEX "Link_collectionId_idx" ON linkwarden."Link" USING btree ("collectionId");
CREATE UNIQUE INDEX "PasswordResetToken_token_key" ON linkwarden."PasswordResetToken" USING btree (token);
CREATE UNIQUE INDEX "Subscription_stripeSubscriptionId_key" ON linkwarden."Subscription" USING btree ("stripeSubscriptionId");
CREATE UNIQUE INDEX "Subscription_userId_key" ON linkwarden."Subscription" USING btree ("userId");
CREATE UNIQUE INDEX "Tag_name_ownerId_key" ON linkwarden."Tag" USING btree (name, "ownerId");
CREATE INDEX "Tag_ownerId_idx" ON linkwarden."Tag" USING btree ("ownerId");
CREATE UNIQUE INDEX "User_email_key" ON linkwarden."User" USING btree (email);
CREATE UNIQUE INDEX "User_username_key" ON linkwarden."User" USING btree (username);
CREATE INDEX "UsersAndCollections_userId_idx" ON linkwarden."UsersAndCollections" USING btree ("userId");
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON linkwarden."VerificationToken" USING btree (identifier, token);
CREATE UNIQUE INDEX "VerificationToken_token_key" ON linkwarden."VerificationToken" USING btree (token);
CREATE INDEX "_LinkToTag_B_index" ON linkwarden."_LinkToTag" USING btree ("B");
CREATE INDEX "_PinnedLinks_B_index" ON linkwarden."_PinnedLinks" USING btree ("B");
```

### Migration Approach (Short)

```sql
-- 1) Create schema/types/sequences/tables.
-- 2) Load data into linkwarden schema.
-- 3) Re-apply constraints and indexes if loading data first.
```
