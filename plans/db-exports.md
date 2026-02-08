# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `exports`

## Table Inventory by Application (Best-Effort)

### Exports Service (schema: `exports`)

- `export_run`
- `flyway_schema_history_exports`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS exports;

CREATE SEQUENCE exports.export_run_id_seq AS bigint;

CREATE TABLE exports.export_run (
  id bigint NOT NULL DEFAULT nextval('exports.export_run_id_seq'::regclass),
  exporter_type varchar(64) NOT NULL,
  export_name varchar(128),
  status varchar(32) NOT NULL,
  started_at timestamp without time zone NOT NULL,
  finished_at timestamp without time zone,
  duration_ms bigint,
  exported_files text,
  upload_success boolean,
  error_message text,
  request_params text,
  CONSTRAINT export_run_pkey PRIMARY KEY (id)
);

CREATE TABLE exports.flyway_schema_history_exports (
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
  CONSTRAINT flyway_schema_history_exports_pk PRIMARY KEY (installed_rank)
);

CREATE INDEX idx_export_run_started_at ON exports.export_run USING btree (started_at);
CREATE INDEX idx_export_run_type_status ON exports.export_run USING btree (exporter_type, status);
CREATE INDEX flyway_schema_history_exports_s_idx ON exports.flyway_schema_history_exports USING btree (success);
```

### Migration Approach (Short)

```sql
-- Create schema/tables, then migrate export_run data.
```
