-- Migration: Relocate finance tables from public to finance schema
-- This script moves all finance-related tables and sequences to the dedicated finance schema

-- Step 1: Create the finance schema
CREATE SCHEMA IF NOT EXISTS finance;

-- Step 2: Create sequences in finance schema (copy from public with current values)
-- These are created first so we can set proper ownership later

-- Create sequences with current values from public
CREATE SEQUENCE finance.base_cost_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

CREATE SEQUENCE finance.daily_cost_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

CREATE SEQUENCE finance.monthly_cost_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

CREATE SEQUENCE finance.salary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

CREATE SEQUENCE finance.special_cost_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

CREATE SEQUENCE finance.special_cost_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO CYCLE;

-- Step 3: Copy sequence current values from public schema
SELECT setval('finance.base_cost_id_seq', currval('public.base_cost_id_seq'), true);
SELECT setval('finance.daily_cost_id_seq', currval('public.daily_cost_id_seq'), true);
SELECT setval('finance.monthly_cost_id_seq', currval('public.monthly_cost_id_seq'), true);
SELECT setval('finance.salary_id_seq', currval('public.salary_id_seq'), true);
SELECT setval('finance.special_cost_id_seq', currval('public.special_cost_id_seq'), true);
SELECT setval('finance.special_cost_entry_id_seq', currval('public.special_cost_entry_id_seq'), true);

-- Step 4: Create tables in finance schema with proper structure
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
    CONSTRAINT finance_flyway_schema_history_pk PRIMARY KEY (installed_rank)
);

CREATE UNIQUE INDEX finance_flyway_schema_history_pk ON finance.flyway_schema_history USING btree (installed_rank);
CREATE INDEX finance_flyway_schema_history_s_idx ON finance.flyway_schema_history USING btree (success);

-- Step 5: Copy data from public tables to finance tables
INSERT INTO finance.base_cost SELECT * FROM public.base_cost;
INSERT INTO finance.daily_cost SELECT * FROM public.daily_cost;
INSERT INTO finance.monthly_cost SELECT * FROM public.monthly_cost;
INSERT INTO finance.salary SELECT * FROM public.salary;
INSERT INTO finance.special_cost SELECT * FROM public.special_cost;
INSERT INTO finance.special_cost_entry SELECT * FROM public.special_cost_entry;
INSERT INTO finance.flyway_schema_history SELECT * FROM public.flyway_schema_history;

-- Step 6: Drop foreign key constraint from public schema
ALTER TABLE public.special_cost_entry DROP CONSTRAINT fk_special_cost;

-- Step 7: Drop tables from public schema
DROP TABLE public.flyway_schema_history;
DROP TABLE public.special_cost_entry;
DROP TABLE public.special_cost;
DROP TABLE public.salary;
DROP TABLE public.monthly_cost;
DROP TABLE public.daily_cost;
DROP TABLE public.base_cost;

-- Step 8: Drop sequences from public schema
DROP SEQUENCE public.special_cost_entry_id_seq;
DROP SEQUENCE public.special_cost_id_seq;
DROP SEQUENCE public.salary_id_seq;
DROP SEQUENCE public.monthly_cost_id_seq;
DROP SEQUENCE public.daily_cost_id_seq;
DROP SEQUENCE public.base_cost_id_seq;

-- Step 9: Add foreign key constraint in finance schema
ALTER TABLE finance.special_cost_entry
    ADD CONSTRAINT fk_special_cost
    FOREIGN KEY (special_cost_id)
    REFERENCES finance.special_cost(id)
    ON DELETE CASCADE;

-- Verification query (optional - run to confirm migration)
-- SELECT table_schema, table_name FROM information_schema.tables
-- WHERE table_name LIKE '%cost%' OR table_name = 'salary'
-- ORDER BY table_schema, table_name;
