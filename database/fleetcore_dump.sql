--
-- PostgreSQL database dump
--

\restrict HXNrOluHtGbguj2OWvftpOzbb4uIiJvlPQ9TgTcbCedikB2KKiEvPuiut2fF8my

-- Dumped from database version 17.11
-- Dumped by pg_dump version 17.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: maintenance_status_logs_from_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.maintenance_status_logs_from_status_enum AS ENUM (
    'SCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);


--
-- Name: maintenance_status_logs_to_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.maintenance_status_logs_to_status_enum AS ENUM (
    'SCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);


--
-- Name: maintenances_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.maintenances_status_enum AS ENUM (
    'SCHEDULED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);


--
-- Name: maintenances_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.maintenances_type_enum AS ENUM (
    'PREVENTIVE',
    'CORRECTIVE'
);


--
-- Name: users_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.users_role_enum AS ENUM (
    'ADMIN',
    'TECHNICIAN'
);


--
-- Name: vehicles_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.vehicles_status_enum AS ENUM (
    'AVAILABLE',
    'IN_MAINTENANCE',
    'INACTIVE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: maintenance_status_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_status_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    maintenance_id uuid NOT NULL,
    from_status public.maintenance_status_logs_from_status_enum,
    to_status public.maintenance_status_logs_to_status_enum NOT NULL,
    changed_by_id uuid
);


--
-- Name: maintenances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenances (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    type public.maintenances_type_enum NOT NULL,
    description text NOT NULL,
    mileage integer NOT NULL,
    scheduled_at timestamp with time zone NOT NULL,
    duration_minutes integer NOT NULL,
    estimated_end_at timestamp with time zone NOT NULL,
    status public.maintenances_status_enum DEFAULT 'SCHEDULED'::public.maintenances_status_enum NOT NULL,
    started_at timestamp with time zone,
    work_performed text,
    final_cost numeric(12,2),
    finished_at timestamp with time zone,
    final_mileage integer,
    vehicle_id uuid NOT NULL,
    mechanic_id uuid NOT NULL,
    workshop_id uuid NOT NULL
);


--
-- Name: mechanics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mechanics (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    specialty character varying(80) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    user_id uuid
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password character varying NOT NULL,
    role public.users_role_enum DEFAULT 'TECHNICIAN'::public.users_role_enum NOT NULL
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    plate character varying(10) NOT NULL,
    brand character varying(60) NOT NULL,
    model character varying(60) NOT NULL,
    year integer NOT NULL,
    mileage integer DEFAULT 0 NOT NULL,
    status public.vehicles_status_enum DEFAULT 'AVAILABLE'::public.vehicles_status_enum NOT NULL
);


--
-- Name: workshops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workshops (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    name character varying(100) NOT NULL,
    address character varying(200) NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Data for Name: maintenance_status_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_status_logs (id, created_at, updated_at, deleted_at, maintenance_id, from_status, to_status, changed_by_id) FROM stdin;
8971606f-d2e9-4b2f-ab4b-a34e9a5dafb0	2026-09-10 15:00:00+00	2026-10-27 20:52:33.158344+00	\N	19607452-fc48-464b-bd88-03c19858feed	\N	SCHEDULED	d304129d-99b4-4d9a-a6ce-182cf86b0977
18ce5be9-680a-4646-a734-4460ddc4724f	2026-09-15 13:05:00+00	2026-10-27 20:52:33.158344+00	\N	19607452-fc48-464b-bd88-03c19858feed	SCHEDULED	IN_PROGRESS	d304129d-99b4-4d9a-a6ce-182cf86b0977
2a4454d0-276c-48aa-991f-bcfead7d58f9	2026-09-15 16:30:00+00	2026-10-27 20:52:33.158344+00	\N	19607452-fc48-464b-bd88-03c19858feed	IN_PROGRESS	COMPLETED	d304129d-99b4-4d9a-a6ce-182cf86b0977
aae6395f-7e5c-4837-8782-e2d45aa8abfb	2026-10-05 14:00:00+00	2026-10-27 20:52:33.158344+00	\N	3a6b6f06-b574-4d72-bdbf-be25f3b84caf	\N	SCHEDULED	d304129d-99b4-4d9a-a6ce-182cf86b0977
573677fe-a2d4-485a-8a66-59b587c2c2a1	2026-10-10 12:10:00+00	2026-10-27 20:52:33.158344+00	\N	3a6b6f06-b574-4d72-bdbf-be25f3b84caf	SCHEDULED	IN_PROGRESS	d304129d-99b4-4d9a-a6ce-182cf86b0977
cd18e236-c10d-433e-82ce-c302480ab74d	2026-10-10 14:00:00+00	2026-10-27 20:52:33.158344+00	\N	3a6b6f06-b574-4d72-bdbf-be25f3b84caf	IN_PROGRESS	COMPLETED	d304129d-99b4-4d9a-a6ce-182cf86b0977
6555d676-b290-4904-ac62-85be5c4777cc	2026-10-26 20:00:00+00	2026-10-27 20:52:33.158344+00	\N	06be9d3b-188c-4a26-816f-5f09d6ef2e39	\N	SCHEDULED	d304129d-99b4-4d9a-a6ce-182cf86b0977
62c023a8-c4c2-4f2d-9bd2-106083620c24	2026-10-27 12:40:00+00	2026-10-27 20:52:33.158344+00	\N	06be9d3b-188c-4a26-816f-5f09d6ef2e39	SCHEDULED	IN_PROGRESS	d304129d-99b4-4d9a-a6ce-182cf86b0977
10006e00-a22c-490c-8982-858d98c48f84	2026-10-27 15:00:00+00	2026-10-27 20:52:33.158344+00	\N	2937a71a-5714-4d55-9713-8a474527ebf3	\N	SCHEDULED	d304129d-99b4-4d9a-a6ce-182cf86b0977
\.


--
-- Data for Name: maintenances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenances (id, created_at, updated_at, deleted_at, type, description, mileage, scheduled_at, duration_minutes, estimated_end_at, status, started_at, work_performed, final_cost, finished_at, final_mileage, vehicle_id, mechanic_id, workshop_id) FROM stdin;
19607452-fc48-464b-bd88-03c19858feed	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	PREVENTIVE	Cambio de aceite y filtros	45000	2026-09-15 13:00:00+00	180	2026-09-15 16:00:00+00	COMPLETED	2026-09-15 13:05:00+00	Cambio de aceite 15W40, filtro de aceite y filtro de aire	350000.00	2026-09-15 16:30:00+00	45000	35e7db17-6841-4672-b39d-3770af3f8054	211ab1ad-fc35-4e04-9721-ce814766be58	3a701419-4860-4973-8f55-fb7d347c65bd
3a6b6f06-b574-4d72-bdbf-be25f3b84caf	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	CORRECTIVE	Reemplazo de pastillas de freno	52300	2026-10-10 12:00:00+00	120	2026-10-10 14:00:00+00	COMPLETED	2026-10-10 12:10:00+00	Reemplazo de pastillas delanteras y rectificación de discos	480000.00	2026-10-10 14:00:00+00	52300	35e7db17-6841-4672-b39d-3770af3f8054	e06f63de-4884-4879-b6c8-deebd04295f6	18fe98af-df31-4657-9979-d0d5e551f2b7
06be9d3b-188c-4a26-816f-5f09d6ef2e39	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	CORRECTIVE	Falla en el sistema de embrague	80000	2026-10-27 12:30:00+00	240	2026-10-27 16:30:00+00	IN_PROGRESS	2026-10-27 12:40:00+00	\N	\N	\N	\N	232ba6c0-8384-4128-856b-45a9c69ffc48	e06f63de-4884-4879-b6c8-deebd04295f6	18fe98af-df31-4657-9979-d0d5e551f2b7
2937a71a-5714-4d55-9713-8a474527ebf3	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	PREVENTIVE	Revisión de los 30.000 km	30500	2026-12-01 12:30:00+00	90	2026-12-01 14:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	bd799718-063a-4b81-9bf2-806b8ee9fb46	211ab1ad-fc35-4e04-9721-ce814766be58	18fe98af-df31-4657-9979-d0d5e551f2b7
\.


--
-- Data for Name: mechanics; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mechanics (id, created_at, updated_at, deleted_at, name, email, specialty, is_active, user_id) FROM stdin;
211ab1ad-fc35-4e04-9721-ce814766be58	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Carlos Pérez	carlos.perez@fleetcore.com	Motor y transmisión	t	d7faf955-225d-4713-bae2-2c806429600b
e06f63de-4884-4879-b6c8-deebd04295f6	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Laura Gómez	laura.gomez@fleetcore.com	Frenos y suspensión	t	93e7a782-f4e7-4d4e-bd82-eecfa002ff51
888f367d-4939-4c06-9cd8-a3d3f6636c30	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Pedro Ruiz	pedro.ruiz@fleetcore.com	Sistema eléctrico	f	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, created_at, updated_at, deleted_at, name, email, password, role) FROM stdin;
d304129d-99b4-4d9a-a6ce-182cf86b0977	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Administrador FleetCore	admin@fleetcore.com	$2b$10$2.x99mBQ9hlZuVDSYbYlke8k1NCLYo0PXQMGKrBks7S/ihvY8CqmW	ADMIN
d7faf955-225d-4713-bae2-2c806429600b	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Carlos Pérez	carlos.perez@fleetcore.com	$2b$10$r0Qj1wh4c/6WjJNXOp8yK.XSkLqdOYTK1vDutkFYUdSqKIQU9KEFO	TECHNICIAN
93e7a782-f4e7-4d4e-bd82-eecfa002ff51	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Laura Gómez	laura.gomez@fleetcore.com	$2b$10$p4RCuoAq/mUOPd7NJhW2nOut86fAv0mDty9CAgkVPdsscewnYiktu	TECHNICIAN
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicles (id, created_at, updated_at, deleted_at, plate, brand, model, year, mileage, status) FROM stdin;
35e7db17-6841-4672-b39d-3770af3f8054	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	ABC123	Chevrolet	NPR	2020	52300	AVAILABLE
bd799718-063a-4b81-9bf2-806b8ee9fb46	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	DEF456	Renault	Master	2022	30500	AVAILABLE
232ba6c0-8384-4128-856b-45a9c69ffc48	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	GHI789	Hino	Dutro	2019	80000	IN_MAINTENANCE
bd926aaa-4965-4e69-92e9-dfaddac10878	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	JKL012	Foton	Aumark	2015	120000	INACTIVE
\.


--
-- Data for Name: workshops; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workshops (id, created_at, updated_at, deleted_at, name, address, is_active) FROM stdin;
18fe98af-df31-4657-9979-d0d5e551f2b7	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Taller Centro	Calle 50 # 45-20, Medellín	t
3a701419-4860-4973-8f55-fb7d347c65bd	2026-10-27 20:52:33.158344+00	2026-10-27 20:52:33.158344+00	\N	Taller Norte	Carrera 65 # 98-10, Medellín	f
\.


--
-- Name: maintenance_status_logs PK_08d4922ce507b9f184dd302ba70; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_status_logs
    ADD CONSTRAINT "PK_08d4922ce507b9f184dd302ba70" PRIMARY KEY (id);


--
-- Name: vehicles PK_18d8646b59304dce4af3a9e35b6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT "PK_18d8646b59304dce4af3a9e35b6" PRIMARY KEY (id);


--
-- Name: mechanics PK_2c0ed23afc0cc7ff361c17e53df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mechanics
    ADD CONSTRAINT "PK_2c0ed23afc0cc7ff361c17e53df" PRIMARY KEY (id);


--
-- Name: maintenances PK_62403473bd524a42d58589aa78b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenances
    ADD CONSTRAINT "PK_62403473bd524a42d58589aa78b" PRIMARY KEY (id);


--
-- Name: workshops PK_6d0e82a124f5b53df91c8989848; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workshops
    ADD CONSTRAINT "PK_6d0e82a124f5b53df91c8989848" PRIMARY KEY (id);


--
-- Name: users PK_a3ffb1c0c8416b9fc6f907b7433; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);


--
-- Name: mechanics REL_4e69c5d1d5ef843a571535ccfd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mechanics
    ADD CONSTRAINT "REL_4e69c5d1d5ef843a571535ccfd" UNIQUE (user_id);


--
-- Name: mechanics UQ_301c3b5fa2d49aab65dcfda36a6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mechanics
    ADD CONSTRAINT "UQ_301c3b5fa2d49aab65dcfda36a6" UNIQUE (email);


--
-- Name: workshops UQ_84a8c763773a6482ba066f608c3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workshops
    ADD CONSTRAINT "UQ_84a8c763773a6482ba066f608c3" UNIQUE (name);


--
-- Name: users UQ_97672ac88f789774dd47f7c8be3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE (email);


--
-- Name: vehicles UQ_ec7181ebdab798d97070122a5bf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT "UQ_ec7181ebdab798d97070122a5bf" UNIQUE (plate);


--
-- Name: IDX_3c1b42caf9098095ac185eaaad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3c1b42caf9098095ac185eaaad" ON public.maintenances USING btree (mechanic_id, status);


--
-- Name: IDX_606e251feba3411998ceb13cd9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_606e251feba3411998ceb13cd9" ON public.maintenance_status_logs USING btree (maintenance_id);


--
-- Name: mechanics FK_4e69c5d1d5ef843a571535ccfde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mechanics
    ADD CONSTRAINT "FK_4e69c5d1d5ef843a571535ccfde" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: maintenance_status_logs FK_5a63b17992f948e108b002437d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_status_logs
    ADD CONSTRAINT "FK_5a63b17992f948e108b002437d1" FOREIGN KEY (changed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: maintenance_status_logs FK_606e251feba3411998ceb13cd95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_status_logs
    ADD CONSTRAINT "FK_606e251feba3411998ceb13cd95" FOREIGN KEY (maintenance_id) REFERENCES public.maintenances(id) ON DELETE CASCADE;


--
-- Name: maintenances FK_a47e3420d123ccf06ab72e1969c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenances
    ADD CONSTRAINT "FK_a47e3420d123ccf06ab72e1969c" FOREIGN KEY (workshop_id) REFERENCES public.workshops(id) ON DELETE RESTRICT;


--
-- Name: maintenances FK_d501088741618ca66074d85e411; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenances
    ADD CONSTRAINT "FK_d501088741618ca66074d85e411" FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE RESTRICT;


--
-- Name: maintenances FK_f92519be34af2de954da0bd4a47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenances
    ADD CONSTRAINT "FK_f92519be34af2de954da0bd4a47" FOREIGN KEY (mechanic_id) REFERENCES public.mechanics(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict HXNrOluHtGbguj2OWvftpOzbb4uIiJvlPQ9TgTcbCedikB2KKiEvPuiut2fF8my

