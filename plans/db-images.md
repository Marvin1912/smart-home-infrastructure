# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `images`

## Table Inventory by Application (Best-Effort)

### Images Service (schema: `images`)

- `flyway_schema_history_images`
- `image`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS images;

CREATE TABLE images.flyway_schema_history_images (
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
  CONSTRAINT flyway_schema_history_images_pk PRIMARY KEY (installed_rank)
);

CREATE TABLE images.image (
  id uuid NOT NULL DEFAULT images.uuid_generate_v4(),
  content bytea NOT NULL,
  content_type varchar(100) NOT NULL,
  CONSTRAINT image_pkey PRIMARY KEY (id)
);

CREATE INDEX flyway_schema_history_images_s_idx ON images.flyway_schema_history_images USING btree (success);
```

### Migration Approach (Short)

```sql
-- Create schema/tables, then migrate image data.
```
