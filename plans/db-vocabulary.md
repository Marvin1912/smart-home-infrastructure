# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `vocabulary`
- `public` (revinfo)

## Table Inventory by Application (Best-Effort)

### Vocabulary (schema: `vocabulary`)

- `flashcard`
- `flashcard_aud`
- `flyway_schema_history_vocabulary`

### Shared Audit (schema: `public`)

- `revinfo`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS vocabulary;

CREATE SEQUENCE vocabulary.flashcard_id_seq AS integer;

CREATE TABLE vocabulary.flashcard (
  id integer NOT NULL DEFAULT nextval('vocabulary.flashcard_id_seq'::regclass),
  anki_id varchar(255),
  front varchar(255) NOT NULL,
  back varchar(255) NOT NULL,
  description text,
  deck varchar(128),
  updated boolean DEFAULT false,
  CONSTRAINT flashcard_pkey PRIMARY KEY (id)
);

CREATE TABLE vocabulary.flashcard_aud (
  id integer NOT NULL,
  rev integer NOT NULL,
  revtype smallint,
  anki_id varchar(255),
  front varchar(255) NOT NULL,
  back varchar(255) NOT NULL,
  description text,
  deck varchar(128),
  updated boolean DEFAULT false,
  CONSTRAINT flashcard_aud_pkey PRIMARY KEY (id, rev)
);

CREATE TABLE vocabulary.flyway_schema_history_vocabulary (
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
  CONSTRAINT flyway_schema_history_vocabulary_pk PRIMARY KEY (installed_rank)
);

ALTER TABLE vocabulary.flashcard_aud ADD CONSTRAINT revinfo_fk FOREIGN KEY (rev) REFERENCES public.revinfo(rev);

CREATE INDEX flyway_schema_history_vocabulary_s_idx ON vocabulary.flyway_schema_history_vocabulary USING btree (success);
```

### Migration Approach (Short)

```sql
-- Ensure public.revinfo exists (see plans/db-public.md), then migrate vocabulary tables.
```
