--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: absences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE absences (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    payed boolean DEFAULT false,
    private boolean DEFAULT false
);


--
-- Name: absences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE absences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: absences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE absences_id_seq OWNED BY absences.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clients (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    shortname character varying(4) NOT NULL
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clients_id_seq OWNED BY clients.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE departments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    shortname character varying(3) NOT NULL
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE departments_id_seq OWNED BY departments.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE employees (
    id integer NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    shortname character varying(3) NOT NULL,
    passwd character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    management boolean DEFAULT false,
    initial_vacation_days double precision DEFAULT 0,
    ldapname character varying(255),
    report_type character varying(255),
    default_attendance boolean DEFAULT false,
    default_project_id integer,
    user_periods character varying(3)[],
    eval_periods character varying(3)[],
    CONSTRAINT chk_report_type CHECK (((report_type)::text = ANY ((ARRAY['start_stop_day'::character varying, 'absolute_day'::character varying, 'week'::character varying, 'month'::character varying])::text[])))
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE employees_id_seq OWNED BY employees.id;


--
-- Name: employments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE employments (
    id integer NOT NULL,
    employee_id integer,
    percent integer NOT NULL,
    start_date date NOT NULL,
    end_date date
);


--
-- Name: employments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE employments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: employments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE employments_id_seq OWNED BY employments.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE holidays (
    id integer NOT NULL,
    holiday_date date NOT NULL,
    musthours_day double precision NOT NULL
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE holidays_id_seq OWNED BY holidays.id;


--
-- Name: overtime_vacations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE overtime_vacations (
    id integer NOT NULL,
    hours double precision NOT NULL,
    employee_id integer NOT NULL,
    transfer_date date NOT NULL
);


--
-- Name: overtime_vacations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE overtime_vacations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: overtime_vacations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE overtime_vacations_id_seq OWNED BY overtime_vacations.id;


--
-- Name: plannings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plannings (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    project_id integer NOT NULL,
    start_week integer NOT NULL,
    end_week integer,
    definitive boolean DEFAULT false NOT NULL,
    description text,
    monday_am boolean DEFAULT false NOT NULL,
    monday_pm boolean DEFAULT false NOT NULL,
    tuesday_am boolean DEFAULT false NOT NULL,
    tuesday_pm boolean DEFAULT false NOT NULL,
    wednesday_am boolean DEFAULT false NOT NULL,
    wednesday_pm boolean DEFAULT false NOT NULL,
    thursday_am boolean DEFAULT false NOT NULL,
    thursday_pm boolean DEFAULT false NOT NULL,
    friday_am boolean DEFAULT false NOT NULL,
    friday_pm boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: plannings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plannings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: plannings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plannings_id_seq OWNED BY plannings.id;


--
-- Name: projectmemberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projectmemberships (
    id integer NOT NULL,
    project_id integer,
    employee_id integer,
    projectmanagement boolean DEFAULT false,
    last_completed date,
    active boolean DEFAULT true
);


--
-- Name: projectmemberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projectmemberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: projectmemberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projectmemberships_id_seq OWNED BY projectmemberships.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    client_id integer,
    name character varying(255) NOT NULL,
    description text,
    billable boolean DEFAULT true,
    report_type character varying(255) DEFAULT 'month'::character varying,
    description_required boolean DEFAULT false,
    shortname character varying(3) NOT NULL,
    offered_hours double precision,
    parent_id integer,
    department_id integer,
    path_ids integer[],
    freeze_until date,
    CONSTRAINT chkname_report CHECK (((report_type)::text = ANY ((ARRAY['start_stop_day'::character varying, 'absolute_day'::character varying, 'week'::character varying, 'month'::character varying])::text[])))
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_notifications (
    id integer NOT NULL,
    date_from date NOT NULL,
    date_to date,
    message text NOT NULL
);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_notifications_id_seq OWNED BY user_notifications.id;


--
-- Name: worktimes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE worktimes (
    id integer NOT NULL,
    project_id integer,
    absence_id integer,
    employee_id integer,
    report_type character varying(255) NOT NULL,
    work_date date NOT NULL,
    hours double precision,
    from_start_time time without time zone,
    to_end_time time without time zone,
    description text,
    billable boolean DEFAULT true,
    booked boolean DEFAULT false,
    type character varying(255),
    CONSTRAINT chkname CHECK (((report_type)::text = ANY ((ARRAY['start_stop_day'::character varying, 'absolute_day'::character varying, 'week'::character varying, 'month'::character varying, 'auto_start'::character varying])::text[])))
);


--
-- Name: worktimes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE worktimes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: worktimes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE worktimes_id_seq OWNED BY worktimes.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE absences ALTER COLUMN id SET DEFAULT nextval('absences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clients ALTER COLUMN id SET DEFAULT nextval('clients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE departments ALTER COLUMN id SET DEFAULT nextval('departments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE employees ALTER COLUMN id SET DEFAULT nextval('employees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE employments ALTER COLUMN id SET DEFAULT nextval('employments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE holidays ALTER COLUMN id SET DEFAULT nextval('holidays_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE overtime_vacations ALTER COLUMN id SET DEFAULT nextval('overtime_vacations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE plannings ALTER COLUMN id SET DEFAULT nextval('plannings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE projectmemberships ALTER COLUMN id SET DEFAULT nextval('projectmemberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_notifications ALTER COLUMN id SET DEFAULT nextval('user_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE worktimes ALTER COLUMN id SET DEFAULT nextval('worktimes_id_seq'::regclass);


--
-- Name: absences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY absences
    ADD CONSTRAINT absences_pkey PRIMARY KEY (id);


--
-- Name: chk_unique_name; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT chk_unique_name UNIQUE (shortname);


--
-- Name: clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: employments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY employments
    ADD CONSTRAINT employments_pkey PRIMARY KEY (id);


--
-- Name: holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: overtime_vacations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY overtime_vacations
    ADD CONSTRAINT overtime_vacations_pkey PRIMARY KEY (id);


--
-- Name: plannings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plannings
    ADD CONSTRAINT plannings_pkey PRIMARY KEY (id);


--
-- Name: projectmemberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT projectmemberships_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- Name: worktimes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT worktimes_pkey PRIMARY KEY (id);


--
-- Name: index_employments_on_employee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_employments_on_employee_id ON employments USING btree (employee_id);


--
-- Name: index_projectmemberships_on_employee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projectmemberships_on_employee_id ON projectmemberships USING btree (employee_id);


--
-- Name: index_projectmemberships_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projectmemberships_on_project_id ON projectmemberships USING btree (project_id);


--
-- Name: index_projects_on_client_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_projects_on_client_id ON projects USING btree (client_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: worktimes_absences; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX worktimes_absences ON worktimes USING btree (absence_id, employee_id, work_date) WHERE ((type)::text = 'Absencetime'::text);


--
-- Name: worktimes_attendances; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX worktimes_attendances ON worktimes USING btree (employee_id, work_date) WHERE ((type)::text = 'Attendancetime'::text);


--
-- Name: worktimes_projects; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX worktimes_projects ON worktimes USING btree (project_id, employee_id, work_date) WHERE ((type)::text = 'Projecttime'::text);


--
-- Name: fk_employments_employees; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employments
    ADD CONSTRAINT fk_employments_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_project_department; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_project_department FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL;


--
-- Name: fk_project_parent; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_project_parent FOREIGN KEY (parent_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- Name: fk_projectmemberships_employees; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT fk_projectmemberships_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_projectmemberships_projects; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT fk_projectmemberships_projects FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- Name: fk_projects_clients; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_projects_clients FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: fk_times_absences; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_absences FOREIGN KEY (absence_id) REFERENCES absences(id) ON DELETE CASCADE;


--
-- Name: fk_times_employees; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_times_projects; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_projects FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');