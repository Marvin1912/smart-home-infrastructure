# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `plants`
- `public` (revinfo)

## Table Inventory by Application (Best-Effort)

### Plants (schema: `plants`)

- `flyway_schema_history_plants`
- `plant`
- `plant_aud`

### Shared Audit (schema: `public`)

- `revinfo`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS plants;

CREATE SEQUENCE plants.plant_id_seq AS integer;

CREATE TABLE plants.flyway_schema_history_plants (
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
  CONSTRAINT flyway_schema_history_plants_pk PRIMARY KEY (installed_rank)
);

CREATE TABLE plants.plant (
  id integer NOT NULL DEFAULT nextval('plants.plant_id_seq'::regclass),
  name varchar(255) NOT NULL,
  species varchar(255) NOT NULL,
  description text NOT NULL,
  location varchar(255) NOT NULL,
  watering_frequency smallint NOT NULL,
  last_watered_date date,
  image varchar(255),
  next_watered_date date,
  care_instructions text,
  fertilizing_frequency smallint,
  last_fertilized_date date,
  next_fertilized_date date,
  CONSTRAINT plant_pkey PRIMARY KEY (id)
);

CREATE TABLE plants.plant_aud (
  id integer NOT NULL,
  last_watered_date date,
  next_watered_date date,
  rev integer NOT NULL,
  revtype smallint,
  watering_frequency smallint,
  care_instructions text,
  description text,
  image varchar(255),
  location varchar(255),
  name varchar(255),
  species varchar(255),
  fertilizing_frequency smallint,
  last_fertilized_date date,
  next_fertilized_date date,
  CONSTRAINT plant_aud_pkey PRIMARY KEY (id, rev),
  CONSTRAINT plant_aud_location_check CHECK (location::text = ANY (ARRAY['LIVING_ROOM'::character varying, 'BEDROOM'::character varying, 'KITCHEN'::character varying, 'UNDEFINED'::character varying]::text[]))
);

ALTER TABLE plants.plant_aud ADD CONSTRAINT revinfo_fk FOREIGN KEY (rev) REFERENCES public.revinfo(rev);

CREATE INDEX flyway_schema_history_plants_s_idx ON plants.flyway_schema_history_plants USING btree (success);
```

### Migration Approach (Short)

```sql
-- Ensure public.revinfo exists (see plans/db-public.md), then migrate plants tables.
```
