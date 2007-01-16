--
-- PostgreSQL database dump
--

SET client_encoding = 'UNICODE';
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: absences; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE absences (
    id serial NOT NULL,
    name character varying(255) NOT NULL,
    payed boolean DEFAULT false
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE clients (
    id serial NOT NULL,
    name character varying(255) NOT NULL,
    contact character varying(255) NOT NULL
);


--
-- Name: employees; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE employees (
    id serial NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    shortname character varying(3) NOT NULL,
    passwd character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(255) NOT NULL,
    management boolean DEFAULT false,
    initial_vacation_days double precision DEFAULT 0::double precision
);


--
-- Name: employments; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE employments (
    id serial NOT NULL,
    employee_id integer,
    percent integer NOT NULL,
    start_date date NOT NULL,
    end_date date
);


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE holidays (
    id serial NOT NULL,
    holiday_date date NOT NULL,
    musthours_day double precision NOT NULL
);


--
-- Name: projectmemberships; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE projectmemberships (
    id serial NOT NULL,
    project_id integer,
    employee_id integer,
    projectmanagement boolean DEFAULT false
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE projects (
    id serial NOT NULL,
    client_id integer,
    name character varying(255) NOT NULL,
    description text
);


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE schema_info (
    version integer
);


--
-- Name: worktimes; Type: TABLE; Schema: public; Owner: puzzle; Tablespace: 
--

CREATE TABLE worktimes (
    id serial NOT NULL,
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
    CONSTRAINT chkname CHECK ((((((report_type)::text = 'start_stop_day'::text) OR ((report_type)::text = 'absolute_day'::text)) OR ((report_type)::text = 'week'::text)) OR ((report_type)::text = 'month'::text)))
);


--
-- Name: absences_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY absences
    ADD CONSTRAINT absences_pkey PRIMARY KEY (id);


--
-- Name: chk_unique_name; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT chk_unique_name UNIQUE (shortname);


--
-- Name: clients_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: employees_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: employments_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY employments
    ADD CONSTRAINT employments_pkey PRIMARY KEY (id);


--
-- Name: holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: projectmemberships_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT projectmemberships_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: worktimes_pkey; Type: CONSTRAINT; Schema: public; Owner: puzzle; Tablespace: 
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT worktimes_pkey PRIMARY KEY (id);


--
-- Name: fk_employments_employees; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY employments
    ADD CONSTRAINT fk_employments_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_projectmemberships_employees; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT fk_projectmemberships_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_projectmemberships_projects; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY projectmemberships
    ADD CONSTRAINT fk_projectmemberships_projects FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- Name: fk_projects_clients; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_projects_clients FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: fk_times_absences; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_absences FOREIGN KEY (absence_id) REFERENCES absences(id) ON DELETE CASCADE;


--
-- Name: fk_times_employees; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_employees FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;


--
-- Name: fk_times_projects; Type: FK CONSTRAINT; Schema: public; Owner: puzzle
--

ALTER TABLE ONLY worktimes
    ADD CONSTRAINT fk_times_projects FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_info (version) VALUES (2)