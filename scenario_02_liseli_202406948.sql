--
-- PostgreSQL database dump
--

\restrict NZPKVPnEd0PP2NEjuJgu6te8bTSdWdbL0YNuxSSBWBgMslGrWIyorN0U88McDZx

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-10-01 22:42:28

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
-- TOC entry 235 (class 1255 OID 58197)
-- Name: cancel_reservation(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cancel_reservation(IN p_reservation_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_id INTEGER;
    v_workstations INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT session_id, workstations, reservation_status
    INTO v_session_id, v_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id
    FOR UPDATE;

    IF v_session_id IS NULL THEN
        RAISE NOTICE 'Reservation does not exist.';
    ELSIF v_status = 'Cancelled' THEN
        RAISE NOTICE 'Reservation % is already cancelled. Workstations will not be released again.',
            p_reservation_id;
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations + v_workstations
        WHERE session_id = v_session_id;

        UPDATE reservations
        SET reservation_status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.cancel_reservation(IN p_reservation_id integer) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 58196)
-- Name: reserve_workstations(integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.reserve_workstations(IN p_session_id integer, IN p_lecturer character varying, IN p_workstations integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_workstations INTO v_available
    FROM lab_sessions
    WHERE session_id = p_session_id
    FOR UPDATE;
    IF v_available IS NULL THEN
        RAISE NOTICE 'Session does not exist.';
    ELSIF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Invalid number of workstations. Must be greater than zero.';
    ELSIF p_workstations > v_available THEN
        RAISE NOTICE 'Reservation rejected: only % workstations are available.', v_available;
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations - p_workstations
        WHERE session_id = p_session_id;
        INSERT INTO reservations
            (session_id, lecturer, workstations, reservation_status)
        VALUES
            (p_session_id, p_lecturer, p_workstations, 'Reserved');

        RAISE NOTICE 'Reservation recorded successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.reserve_workstations(IN p_session_id integer, IN p_lecturer character varying, IN p_workstations integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 58169)
-- Name: lab_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lab_sessions (
    session_id integer NOT NULL,
    session_name character varying(100) NOT NULL,
    available_workstations integer NOT NULL,
    CONSTRAINT lab_sessions_available_workstations_check CHECK ((available_workstations >= 0))
);


ALTER TABLE public.lab_sessions OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 58168)
-- Name: lab_sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lab_sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lab_sessions_session_id_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 219
-- Name: lab_sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lab_sessions_session_id_seq OWNED BY public.lab_sessions.session_id;


--
-- TOC entry 222 (class 1259 OID 58180)
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    reservation_id integer NOT NULL,
    session_id integer,
    lecturer character varying(100) NOT NULL,
    workstations integer NOT NULL,
    reservation_status character varying(20) DEFAULT 'Reserved'::character varying NOT NULL
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 58179)
-- Name: reservations_reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservations_reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reservations_reservation_id_seq OWNER TO postgres;

--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 221
-- Name: reservations_reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservations_reservation_id_seq OWNED BY public.reservations.reservation_id;


--
-- TOC entry 4816 (class 2604 OID 58172)
-- Name: lab_sessions session_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lab_sessions ALTER COLUMN session_id SET DEFAULT nextval('public.lab_sessions_session_id_seq'::regclass);


--
-- TOC entry 4817 (class 2604 OID 58183)
-- Name: reservations reservation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations ALTER COLUMN reservation_id SET DEFAULT nextval('public.reservations_reservation_id_seq'::regclass);


--
-- TOC entry 4973 (class 0 OID 58169)
-- Dependencies: 220
-- Data for Name: lab_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lab_sessions (session_id, session_name, available_workstations) FROM stdin;
3	Programming Practical	2
2	Networking Practical	2
1	Database Practical	20
\.


--
-- TOC entry 4975 (class 0 OID 58180)
-- Dependencies: 222
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservations (reservation_id, session_id, lecturer, workstations, reservation_status) FROM stdin;
2	2	Mr. Phiri	3	Reserved
1	1	Dr. Banda	5	Cancelled
\.


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 219
-- Name: lab_sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lab_sessions_session_id_seq', 3, true);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 221
-- Name: reservations_reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservations_reservation_id_seq', 2, true);


--
-- TOC entry 4821 (class 2606 OID 58178)
-- Name: lab_sessions lab_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lab_sessions
    ADD CONSTRAINT lab_sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 4823 (class 2606 OID 58190)
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (reservation_id);


--
-- TOC entry 4824 (class 2606 OID 58191)
-- Name: reservations reservations_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lab_sessions(session_id);


-- Completed on 2026-10-01 22:42:29

--
-- PostgreSQL database dump complete
--

\unrestrict NZPKVPnEd0PP2NEjuJgu6te8bTSdWdbL0YNuxSSBWBgMslGrWIyorN0U88McDZx

