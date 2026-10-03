--
-- PostgreSQL database dump
--

\restrict Za5mlSAOmqAxqzDGgSP4T2FRFg9mbqtf7VbXHQlfz0tDFcqIgBkigjWpmIlmJeW

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-10-01 22:56:33

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
-- TOC entry 234 (class 1255 OID 58726)
-- Name: allocate_room(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.allocate_room(IN p_room_id integer, IN p_student_number character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_bed_spaces INTO v_available
    FROM hostel_rooms
    WHERE room_id = p_room_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        RAISE NOTICE 'Room does not exist.';
    ELSIF p_student_number IS NULL OR BTRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Invalid student number. Student number cannot be blank.';
    ELSIF v_available <= 0 THEN
        RAISE NOTICE 'Allocation rejected: room is full.';
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
            (student_number, room_id, allocation_status)
        VALUES
            (p_student_number, p_room_id, 'Allocated');

        RAISE NOTICE 'Student allocated successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.allocate_room(IN p_room_id integer, IN p_student_number character varying) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 58727)
-- Name: check_out(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.check_out(IN p_allocation_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT room_id, allocation_status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id
    FOR UPDATE;

    IF v_room_id IS NULL THEN
        RAISE NOTICE 'Allocation does not exist.';
    ELSIF v_status = 'Checked Out' THEN
        RAISE NOTICE 'Allocation % is already checked out. Bed space will not be released again.',
            p_allocation_id;
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET allocation_status = 'Checked Out'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.check_out(IN p_allocation_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 58711)
-- Name: allocations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocations (
    allocation_id integer NOT NULL,
    student_number character varying(30) NOT NULL,
    room_id integer,
    allocation_status character varying(20) DEFAULT 'Allocated'::character varying NOT NULL
);


ALTER TABLE public.allocations OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 58710)
-- Name: allocations_allocation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.allocations_allocation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allocations_allocation_id_seq OWNER TO postgres;

--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 221
-- Name: allocations_allocation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.allocations_allocation_id_seq OWNED BY public.allocations.allocation_id;


--
-- TOC entry 220 (class 1259 OID 58698)
-- Name: hostel_rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hostel_rooms (
    room_id integer NOT NULL,
    room_number character varying(20) NOT NULL,
    available_bed_spaces integer NOT NULL,
    CONSTRAINT hostel_rooms_available_bed_spaces_check CHECK ((available_bed_spaces >= 0))
);


ALTER TABLE public.hostel_rooms OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 58697)
-- Name: hostel_rooms_room_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hostel_rooms_room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hostel_rooms_room_id_seq OWNER TO postgres;

--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 219
-- Name: hostel_rooms_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hostel_rooms_room_id_seq OWNED BY public.hostel_rooms.room_id;


--
-- TOC entry 4817 (class 2604 OID 58714)
-- Name: allocations allocation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations ALTER COLUMN allocation_id SET DEFAULT nextval('public.allocations_allocation_id_seq'::regclass);


--
-- TOC entry 4816 (class 2604 OID 58701)
-- Name: hostel_rooms room_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hostel_rooms ALTER COLUMN room_id SET DEFAULT nextval('public.hostel_rooms_room_id_seq'::regclass);


--
-- TOC entry 4977 (class 0 OID 58711)
-- Dependencies: 222
-- Data for Name: allocations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocations (allocation_id, student_number, room_id, allocation_status) FROM stdin;
2	STU002	2	Allocated
1	STU001	1	Checked Out
\.


--
-- TOC entry 4975 (class 0 OID 58698)
-- Dependencies: 220
-- Data for Name: hostel_rooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hostel_rooms (room_id, room_number, available_bed_spaces) FROM stdin;
3	A103	0
2	A102	0
1	A101	4
\.


--
-- TOC entry 4985 (class 0 OID 0)
-- Dependencies: 221
-- Name: allocations_allocation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.allocations_allocation_id_seq', 2, true);


--
-- TOC entry 4986 (class 0 OID 0)
-- Dependencies: 219
-- Name: hostel_rooms_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hostel_rooms_room_id_seq', 3, true);


--
-- TOC entry 4825 (class 2606 OID 58720)
-- Name: allocations allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_pkey PRIMARY KEY (allocation_id);


--
-- TOC entry 4821 (class 2606 OID 58707)
-- Name: hostel_rooms hostel_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hostel_rooms
    ADD CONSTRAINT hostel_rooms_pkey PRIMARY KEY (room_id);


--
-- TOC entry 4823 (class 2606 OID 58709)
-- Name: hostel_rooms hostel_rooms_room_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hostel_rooms
    ADD CONSTRAINT hostel_rooms_room_number_key UNIQUE (room_number);


--
-- TOC entry 4826 (class 2606 OID 58721)
-- Name: allocations allocations_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.hostel_rooms(room_id);


-- Completed on 2026-10-01 22:56:34

--
-- PostgreSQL database dump complete
--

\unrestrict Za5mlSAOmqAxqzDGgSP4T2FRFg9mbqtf7VbXHQlfz0tDFcqIgBkigjWpmIlmJeW

