# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## System Schemas

- `information_schema`
- `pg_catalog`
- `pg_toast`

## User Schemas

- `exports`
- `images`
- `linkwarden`
- `mental_arithmetic`
- `plants`
- `public`
- `vocabulary`

## Table Inventory by Application (Best-Effort)

Notes:

- Groupings below are inferred from table names and schema hints only.
- `public` appears to contain multiple applications; it is split into Wiki.js-related tables and finance/budgeting tables as requested.
- Migration/audit tables are included under each application for completeness.

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

### Mental Arithmetic (schema: `mental_arithmetic`)

- `arithmetic_problem`
- `arithmetic_session`
- `arithmetic_settings`
- `flyway_schema_history_mental_arithmetic`
- `settings_operations`

### Plants (schema: `plants`)

- `flyway_schema_history_plants`
- `plant`
- `plant_aud`

### Vocabulary (schema: `vocabulary`)

- `flashcard`
- `flashcard_aud`
- `flyway_schema_history_vocabulary`

### Images Service (schema: `images`)

- `flyway_schema_history_images`
- `image`

### Exports Service (schema: `exports`)

- `export_run`
- `flyway_schema_history_exports`

### Wiki.js (schema: `public`, inferred)

- `analytics`
- `apiKeys`
- `assetData`
- `assetFolders`
- `assets`
- `authentication`
- `brute`
- `commentProviders`
- `comments`
- `editors`
- `flyway_schema_history`
- `groups`
- `locales`
- `loggers`
- `migrations`
- `migrations_lock`
- `navigation`
- `pageHistory`
- `pageHistoryTags`
- `pageLinks`
- `pageTags`
- `pageTree`
- `pages`
- `renderers`
- `revinfo`
- `searchEngines`
- `sessions`
- `settings`
- `storage`
- `tags`
- `userAvatars`
- `userGroups`
- `userKeys`
- `users`

### Finance / Budgeting (schema: `public`, inferred)

- `base_cost`
- `daily_cost`
- `monthly_cost`
- `salary`
- `special_cost`
- `special_cost_entry`
