# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `public`

## Table Inventory by Application (Best-Effort)

### Shared Audit (schema: `public`)

- `revinfo`

## Target Schema Split DDL (Proposed)

```sql
CREATE TABLE public.revinfo (
  rev integer NOT NULL,
  revtstmp bigint,
  CONSTRAINT revinfo_pkey PRIMARY KEY (rev)
);

CREATE SEQUENCE public.revinfo_seq AS bigint;
```

### Migration Approach (Short)

```sql
-- Keep public.revinfo as the shared audit table for plants/vocabulary.
-- Ensure FKs in plants/vocabulary reference public.revinfo.
```

## Database Rename Operations

### Rename Database (DDL)

```sql
-- Terminate existing connections first (required)
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'costs' AND pid <> pg_backend_pid();

-- Rename the database
ALTER DATABASE costs RENAME TO new_database_name;
```

**Notes:**
- Requires exclusive access (no active connections)
- Only database owner or superuser can rename
- Update application connection strings after rename
