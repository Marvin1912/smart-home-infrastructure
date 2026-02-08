# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `finance`

## Table Inventory by Application (Best-Effort)

### Finance / Budgeting (schema: `finance`)

- `base_cost`
- `daily_cost`
- `monthly_cost`
- `salary`
- `special_cost`
- `special_cost_entry`
- `flyway_schema_history`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS finance;

CREATE SEQUENCE finance.base_cost_id_seq AS integer;
CREATE SEQUENCE finance.daily_cost_id_seq AS integer;
CREATE SEQUENCE finance.monthly_cost_id_seq AS integer;
CREATE SEQUENCE finance.salary_id_seq AS integer;
CREATE SEQUENCE finance.special_cost_id_seq AS integer;
CREATE SEQUENCE finance.special_cost_entry_id_seq AS integer;

CREATE TABLE finance.base_cost (
  id integer NOT NULL DEFAULT nextval('finance.base_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT base_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.daily_cost (
  id integer NOT NULL DEFAULT nextval('finance.daily_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  description varchar(512),
  CONSTRAINT daily_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.monthly_cost (
  id integer NOT NULL DEFAULT nextval('finance.monthly_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT monthly_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.salary (
  id integer NOT NULL DEFAULT nextval('finance.salary_id_seq'::regclass),
  salary_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT salary_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.special_cost (
  id integer NOT NULL DEFAULT nextval('finance.special_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  CONSTRAINT special_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.special_cost_entry (
  id integer NOT NULL DEFAULT nextval('finance.special_cost_entry_id_seq'::regclass),
  description varchar(2048) NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  special_cost_id integer NOT NULL,
  additional_info varchar(2048),
  CONSTRAINT special_cost_entry_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.flyway_schema_history (
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
  CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank)
);

CREATE UNIQUE INDEX flyway_schema_history_pk ON finance.flyway_schema_history USING btree (installed_rank);
CREATE INDEX flyway_schema_history_s_idx ON finance.flyway_schema_history USING btree (success);

ALTER TABLE finance.special_cost_entry ADD CONSTRAINT fk_special_cost FOREIGN KEY (special_cost_id) REFERENCES finance.special_cost(id) ON DELETE CASCADE;
```

### Migration Approach (Short)

```sql
-- Move public finance tables into finance schema and update sequence defaults.

-- Step 1: Create the finance schema
CREATE SCHEMA IF NOT EXISTS finance;

-- Step 2: Create sequences in finance schema with current values from public
CREATE SEQUENCE finance.base_cost_id_seq AS integer;
CREATE SEQUENCE finance.daily_cost_id_seq AS integer;
CREATE SEQUENCE finance.monthly_cost_id_seq AS integer;
CREATE SEQUENCE finance.salary_id_seq AS integer;
CREATE SEQUENCE finance.special_cost_id_seq AS integer;
CREATE SEQUENCE finance.special_cost_entry_id_seq AS integer;

-- Copy sequence values
SELECT setval('finance.base_cost_id_seq', currval('public.base_cost_id_seq'), true);
SELECT setval('finance.daily_cost_id_seq', currval('public.daily_cost_id_seq'), true);
SELECT setval('finance.monthly_cost_id_seq', currval('public.monthly_cost_id_seq'), true);
SELECT setval('finance.salary_id_seq', currval('public.salary_id_seq'), true);
SELECT setval('finance.special_cost_id_seq', currval('public.special_cost_id_seq'), true);
SELECT setval('finance.special_cost_entry_id_seq', currval('public.special_cost_entry_id_seq'), true);

-- Step 3: Create tables in finance schema
CREATE TABLE finance.base_cost (
  id integer NOT NULL DEFAULT nextval('finance.base_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT finance_base_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.daily_cost (
  id integer NOT NULL DEFAULT nextval('finance.daily_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  description varchar(512),
  CONSTRAINT finance_daily_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.monthly_cost (
  id integer NOT NULL DEFAULT nextval('finance.monthly_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT finance_monthly_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.salary (
  id integer NOT NULL DEFAULT nextval('finance.salary_id_seq'::regclass),
  salary_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  CONSTRAINT finance_salary_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.special_cost (
  id integer NOT NULL DEFAULT nextval('finance.special_cost_id_seq'::regclass),
  cost_date date NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  CONSTRAINT finance_special_cost_pkey PRIMARY KEY (id)
);

CREATE TABLE finance.special_cost_entry (
  id integer NOT NULL DEFAULT nextval('finance.special_cost_entry_id_seq'::regclass),
  description varchar(2048) NOT NULL,
  creation_date timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  value numeric(7,2) NOT NULL,
  special_cost_id integer NOT NULL,
  additional_info varchar(2048),
  CONSTRAINT finance_special_cost_entry_pkey PRIMARY KEY (id)
);

-- Step 4: Copy data
INSERT INTO finance.base_cost SELECT * FROM public.base_cost;
INSERT INTO finance.daily_cost SELECT * FROM public.daily_cost;
INSERT INTO finance.monthly_cost SELECT * FROM public.monthly_cost;
INSERT INTO finance.salary SELECT * FROM public.salary;
INSERT INTO finance.special_cost SELECT * FROM public.special_cost;
INSERT INTO finance.special_cost_entry SELECT * FROM public.special_cost_entry;
INSERT INTO finance.flyway_schema_history SELECT * FROM public.flyway_schema_history;

-- Step 5: Drop old objects from public schema
ALTER TABLE public.special_cost_entry DROP CONSTRAINT fk_special_cost;
DROP TABLE public.flyway_schema_history;
DROP TABLE public.special_cost_entry;
DROP TABLE public.special_cost;
DROP TABLE public.salary;
DROP TABLE public.monthly_cost;
DROP TABLE public.daily_cost;
DROP TABLE public.base_cost;
DROP SEQUENCE public.special_cost_entry_id_seq;
DROP SEQUENCE public.special_cost_id_seq;
DROP SEQUENCE public.salary_id_seq;
DROP SEQUENCE public.monthly_cost_id_seq;
DROP SEQUENCE public.daily_cost_id_seq;
DROP SEQUENCE public.base_cost_id_seq;

-- Step 6: Recreate foreign key in finance schema
ALTER TABLE finance.special_cost_entry ADD CONSTRAINT fk_special_cost FOREIGN KEY (special_cost_id) REFERENCES finance.special_cost(id) ON DELETE CASCADE;
```
