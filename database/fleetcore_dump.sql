--
-- PostgreSQL database dump
--


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

INSERT INTO public.maintenance_status_logs VALUES ('e1073416-72b0-46a4-a1e0-89a0b463d5d8', '2026-09-10 15:00:00+00', '2026-10-27 23:48:35.432652+00', NULL, '8b4ee8f1-7153-410e-8d9d-3735e44941ff', NULL, 'SCHEDULED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('3caa479c-483f-46e4-a6a3-d01ecf4c9a75', '2026-09-15 13:05:00+00', '2026-10-27 23:48:35.432652+00', NULL, '8b4ee8f1-7153-410e-8d9d-3735e44941ff', 'SCHEDULED', 'IN_PROGRESS', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('a52bd103-3f42-400a-8949-9bfb4d602eb0', '2026-09-15 16:30:00+00', '2026-10-27 23:48:35.432652+00', NULL, '8b4ee8f1-7153-410e-8d9d-3735e44941ff', 'IN_PROGRESS', 'COMPLETED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('79338ae7-8bca-49da-a364-bd10d0603f29', '2026-10-05 14:00:00+00', '2026-10-27 23:48:35.432652+00', NULL, '48431ac8-dded-4b1a-9d07-85cbf89737bb', NULL, 'SCHEDULED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('191afb38-4b48-48ce-8258-82bcb42dade8', '2026-10-10 12:10:00+00', '2026-10-27 23:48:35.432652+00', NULL, '48431ac8-dded-4b1a-9d07-85cbf89737bb', 'SCHEDULED', 'IN_PROGRESS', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('abcd8c39-dba7-4413-9ce0-59bf26248e13', '2026-10-10 14:00:00+00', '2026-10-27 23:48:35.432652+00', NULL, '48431ac8-dded-4b1a-9d07-85cbf89737bb', 'IN_PROGRESS', 'COMPLETED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('0d189a76-0e1f-49f5-ab9f-9f2c97771efb', '2026-10-26 20:00:00+00', '2026-10-27 23:48:35.432652+00', NULL, 'bf70d2de-d8f1-43ce-8f9c-e0b2e5f2b707', NULL, 'SCHEDULED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('0b9dd8e7-01c1-49af-a4b4-9b04f108827d', '2026-10-27 12:40:00+00', '2026-10-27 23:48:35.432652+00', NULL, 'bf70d2de-d8f1-43ce-8f9c-e0b2e5f2b707', 'SCHEDULED', 'IN_PROGRESS', 'b824078f-a403-4bd6-90cc-931a1c0a427e');
INSERT INTO public.maintenance_status_logs VALUES ('666ad02d-1710-4fef-95e2-6b8a4586e28f', '2026-10-27 15:00:00+00', '2026-10-27 23:48:35.432652+00', NULL, '6fb23576-1fca-4de1-9592-f46106aeb5c3', NULL, 'SCHEDULED', 'b824078f-a403-4bd6-90cc-931a1c0a427e');


--
-- Data for Name: maintenances; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.maintenances VALUES ('8b4ee8f1-7153-410e-8d9d-3735e44941ff', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'PREVENTIVE', 'Cambio de aceite y filtros', 45000, '2026-09-15 13:00:00+00', 180, '2026-09-15 16:00:00+00', 'COMPLETED', '2026-09-15 13:05:00+00', 'Cambio de aceite 15W40, filtro de aceite y filtro de aire', 350000.00, '2026-09-15 16:30:00+00', 45000, 'f99776de-f521-4a4b-9404-223c5143585d', 'f2835ef0-12e9-4a37-ba9f-67f626b60860', '7b102fea-43be-4329-a419-c75d45b83a63');
INSERT INTO public.maintenances VALUES ('48431ac8-dded-4b1a-9d07-85cbf89737bb', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'CORRECTIVE', 'Reemplazo de pastillas de freno', 52300, '2026-10-10 12:00:00+00', 120, '2026-10-10 14:00:00+00', 'COMPLETED', '2026-10-10 12:10:00+00', 'Reemplazo de pastillas delanteras y rectificación de discos', 480000.00, '2026-10-10 14:00:00+00', 52300, 'f99776de-f521-4a4b-9404-223c5143585d', '56236fec-c43f-4c4a-8fac-21e9c41e6dcb', '8fd01e52-a296-4c2c-a0d1-651bb22ec8ea');
INSERT INTO public.maintenances VALUES ('bf70d2de-d8f1-43ce-8f9c-e0b2e5f2b707', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'CORRECTIVE', 'Falla en el sistema de embrague', 80000, '2026-10-27 12:30:00+00', 240, '2026-10-27 16:30:00+00', 'IN_PROGRESS', '2026-10-27 12:40:00+00', NULL, NULL, NULL, NULL, 'f2af4508-06be-4d32-867b-91359cac7115', '56236fec-c43f-4c4a-8fac-21e9c41e6dcb', '8fd01e52-a296-4c2c-a0d1-651bb22ec8ea');
INSERT INTO public.maintenances VALUES ('6fb23576-1fca-4de1-9592-f46106aeb5c3', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'PREVENTIVE', 'Revisión de los 30.000 km', 30500, '2026-12-01 12:30:00+00', 90, '2026-12-01 14:00:00+00', 'SCHEDULED', NULL, NULL, NULL, NULL, NULL, 'ea6cf891-a56f-4d57-a28f-a6405be224e4', 'f2835ef0-12e9-4a37-ba9f-67f626b60860', '8fd01e52-a296-4c2c-a0d1-651bb22ec8ea');


--
-- Data for Name: mechanics; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mechanics VALUES ('f2835ef0-12e9-4a37-ba9f-67f626b60860', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Carlos Pérez', 'carlos.perez@fleetcore.com', 'Motor y transmisión', true, 'a14a113c-1a88-490b-b186-c22bede7410b');
INSERT INTO public.mechanics VALUES ('56236fec-c43f-4c4a-8fac-21e9c41e6dcb', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Laura Gómez', 'laura.gomez@fleetcore.com', 'Frenos y suspensión', true, '03df7336-281f-4ae6-85b4-36f9b60711ba');
INSERT INTO public.mechanics VALUES ('5dc926a3-8608-470e-8a36-f17f1075d7f0', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Pedro Ruiz', 'pedro.ruiz@fleetcore.com', 'Sistema eléctrico', false, NULL);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users VALUES ('b824078f-a403-4bd6-90cc-931a1c0a427e', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Administrador FleetCore', 'admin@fleetcore.com', '$2b$10$MPFv1A64lMG2I3Mdje6oO.g5qeKmlKwNygobet8A8wYBsDGw4Rdme', 'ADMIN');
INSERT INTO public.users VALUES ('a14a113c-1a88-490b-b186-c22bede7410b', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Carlos Pérez', 'carlos.perez@fleetcore.com', '$2b$10$LVeXig5xiOrr9FvZJakpJuK7roOD78rD9HGh.mvk/hB7UuOZy24oW', 'TECHNICIAN');
INSERT INTO public.users VALUES ('03df7336-281f-4ae6-85b4-36f9b60711ba', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Laura Gómez', 'laura.gomez@fleetcore.com', '$2b$10$KDVbPJwH1Lu0wBAIqTaCYOtq5qaJnNXtPK9wwS2duDK5KJZPb8eLG', 'TECHNICIAN');


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vehicles VALUES ('f99776de-f521-4a4b-9404-223c5143585d', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'ABC123', 'Chevrolet', 'NPR', 2020, 52300, 'AVAILABLE');
INSERT INTO public.vehicles VALUES ('ea6cf891-a56f-4d57-a28f-a6405be224e4', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'DEF456', 'Renault', 'Master', 2022, 30500, 'AVAILABLE');
INSERT INTO public.vehicles VALUES ('f2af4508-06be-4d32-867b-91359cac7115', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'GHI789', 'Hino', 'Dutro', 2019, 80000, 'IN_MAINTENANCE');
INSERT INTO public.vehicles VALUES ('fa72d751-dbc6-462f-a0ab-9ef25d20c020', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'JKL012', 'Foton', 'Aumark', 2015, 120000, 'INACTIVE');


--
-- Data for Name: workshops; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workshops VALUES ('8fd01e52-a296-4c2c-a0d1-651bb22ec8ea', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Taller Centro', 'Calle 50 # 45-20, Medellín', true);
INSERT INTO public.workshops VALUES ('7b102fea-43be-4329-a419-c75d45b83a63', '2026-10-27 23:48:35.432652+00', '2026-10-27 23:48:35.432652+00', NULL, 'Taller Norte', 'Carrera 65 # 98-10, Medellín', false);


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


