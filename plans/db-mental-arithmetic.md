# Database Schemas (Current State)

Source: PostgreSQL schema catalog listing.

## User Schemas

- `mental_arithmetic`

## Table Inventory by Application (Best-Effort)

### Mental Arithmetic (schema: `mental_arithmetic`)

- `arithmetic_problem`
- `arithmetic_session`
- `arithmetic_settings`
- `flyway_schema_history_mental_arithmetic`
- `settings_operations`

## Target Schema Split DDL (Proposed)

```sql
CREATE SCHEMA IF NOT EXISTS mental_arithmetic;

CREATE SEQUENCE mental_arithmetic.arithmetic_settings_id_seq AS integer;

CREATE TABLE mental_arithmetic.arithmetic_problem (
  id varchar(255) NOT NULL,
  session_id varchar(255) NOT NULL,
  expression varchar(255) NOT NULL,
  answer integer NOT NULL,
  user_answer integer,
  is_correct boolean,
  time_spent bigint NOT NULL,
  presented_at timestamp without time zone NOT NULL,
  answered_at timestamp without time zone,
  operation_type varchar(50) NOT NULL,
  difficulty varchar(50) NOT NULL,
  operand1 integer NOT NULL,
  operand2 integer NOT NULL,
  CONSTRAINT arithmetic_problem_pkey PRIMARY KEY (id)
);

CREATE TABLE mental_arithmetic.arithmetic_session (
  id varchar(255) NOT NULL,
  created_at timestamp without time zone NOT NULL,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  status varchar(50) NOT NULL,
  settings_id integer NOT NULL,
  current_problem_index integer NOT NULL,
  score integer NOT NULL,
  correct_answers integer NOT NULL,
  incorrect_answers integer NOT NULL,
  total_time_spent bigint NOT NULL,
  problems_completed integer NOT NULL,
  total_problems integer NOT NULL,
  accuracy double precision NOT NULL,
  avg_time_per_problem double precision NOT NULL,
  is_completed boolean NOT NULL,
  is_timed_out boolean NOT NULL,
  notes varchar(255),
  CONSTRAINT arithmetic_session_pkey PRIMARY KEY (id)
);

CREATE TABLE mental_arithmetic.arithmetic_settings (
  id integer NOT NULL DEFAULT nextval('mental_arithmetic.arithmetic_settings_id_seq'::regclass),
  difficulty varchar(50) NOT NULL,
  problem_count integer NOT NULL,
  time_limit integer,
  show_immediate_feedback boolean NOT NULL,
  allow_pause boolean NOT NULL,
  show_progress boolean NOT NULL,
  show_timer boolean NOT NULL,
  enable_sound boolean NOT NULL,
  use_keypad boolean NOT NULL,
  session_name varchar(255),
  shuffle_problems boolean NOT NULL,
  repeat_incorrect_problems boolean NOT NULL,
  max_retries integer NOT NULL,
  show_correct_answer boolean NOT NULL,
  font_size varchar(50),
  high_contrast boolean,
  CONSTRAINT arithmetic_settings_pkey PRIMARY KEY (id)
);

CREATE TABLE mental_arithmetic.flyway_schema_history_mental_arithmetic (
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
  CONSTRAINT flyway_schema_history_mental_arithmetic_pk PRIMARY KEY (installed_rank)
);

CREATE TABLE mental_arithmetic.settings_operations (
  settings_id integer NOT NULL,
  operation_type varchar(50) NOT NULL,
  CONSTRAINT settings_operations_pkey PRIMARY KEY (settings_id, operation_type)
);

ALTER TABLE mental_arithmetic.arithmetic_problem ADD CONSTRAINT arithmetic_problem_session_id_fkey FOREIGN KEY (session_id) REFERENCES mental_arithmetic.arithmetic_session(id) ON DELETE CASCADE;
ALTER TABLE mental_arithmetic.arithmetic_session ADD CONSTRAINT arithmetic_session_settings_id_fkey FOREIGN KEY (settings_id) REFERENCES mental_arithmetic.arithmetic_settings(id);
ALTER TABLE mental_arithmetic.settings_operations ADD CONSTRAINT settings_operations_settings_id_fkey FOREIGN KEY (settings_id) REFERENCES mental_arithmetic.arithmetic_settings(id) ON DELETE CASCADE;

CREATE INDEX idx_arithmetic_problem_session_id ON mental_arithmetic.arithmetic_problem USING btree (session_id);
CREATE INDEX flyway_schema_history_mental_arithmetic_s_idx ON mental_arithmetic.flyway_schema_history_mental_arithmetic USING btree (success);
```

### Migration Approach (Short)

```sql
-- Create schema/tables, migrate data, then apply constraints and indexes if needed.
```
