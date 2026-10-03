--
-- PostgreSQL database dump
--

\restrict xkEufe0pCQ7xrusTjfZgvZHoAagoxwccv23FE73qOF4EbuklrSZ8EXxHfPfZNIv

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-10-01 23:06:00

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
-- TOC entry 234 (class 1255 OID 59295)
-- Name: dispense_medicine(integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.dispense_medicine(IN p_medicine_id integer, IN p_student_number character varying, IN p_quantity integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_stock INTEGER;
BEGIN
    SELECT stock_quantity INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id
    FOR UPDATE;
    IF v_stock IS NULL THEN
        RAISE NOTICE 'Medicine does not exist.';
    ELSIF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid dispensing quantity. Quantity must be greater than zero.';
    ELSIF p_quantity > v_stock THEN
        RAISE NOTICE 'Dispensing rejected: only % units are available.', v_stock;
    ELSE
        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
            (medicine_id, student_number, quantity, dispensing_status)
        VALUES
            (p_medicine_id, p_student_number, p_quantity, 'Dispensed');

        RAISE NOTICE 'Medicine dispensed successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.dispense_medicine(IN p_medicine_id integer, IN p_student_number character varying, IN p_quantity integer) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 59296)
-- Name: reverse_dispensing(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.reverse_dispensing(IN p_dispensing_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_medicine_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT medicine_id, quantity, dispensing_status
    INTO v_medicine_id, v_quantity, v_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id
    FOR UPDATE;

    IF v_medicine_id IS NULL THEN
        RAISE NOTICE 'Dispensing record does not exist.';
    ELSIF v_status = 'Reversed' THEN
        RAISE NOTICE 'Dispensing record % is already reversed. Stock will not be restored again.',
            p_dispensing_id;
    ELSE
        UPDATE medicines
        SET stock_quantity = stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        UPDATE dispensing_records
        SET dispensing_status = 'Reversed'
        WHERE dispensing_id = p_dispensing_id;

        RAISE NOTICE 'Dispensing record reversed successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.reverse_dispensing(IN p_dispensing_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 59279)
-- Name: dispensing_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dispensing_records (
    dispensing_id integer NOT NULL,
    medicine_id integer,
    student_number character varying(30) NOT NULL,
    quantity integer NOT NULL,
    dispensing_status character varying(20) DEFAULT 'Dispensed'::character varying NOT NULL
);


ALTER TABLE public.dispensing_records OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 59278)
-- Name: dispensing_records_dispensing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dispensing_records_dispensing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dispensing_records_dispensing_id_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 221
-- Name: dispensing_records_dispensing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dispensing_records_dispensing_id_seq OWNED BY public.dispensing_records.dispensing_id;


--
-- TOC entry 220 (class 1259 OID 59268)
-- Name: medicines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicines (
    medicine_id integer NOT NULL,
    medicine_name character varying(100) NOT NULL,
    stock_quantity integer NOT NULL,
    CONSTRAINT medicines_stock_quantity_check CHECK ((stock_quantity >= 0))
);


ALTER TABLE public.medicines OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 59267)
-- Name: medicines_medicine_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicines_medicine_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.medicines_medicine_id_seq OWNER TO postgres;

--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 219
-- Name: medicines_medicine_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicines_medicine_id_seq OWNED BY public.medicines.medicine_id;


--
-- TOC entry 4817 (class 2604 OID 59282)
-- Name: dispensing_records dispensing_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispensing_records ALTER COLUMN dispensing_id SET DEFAULT nextval('public.dispensing_records_dispensing_id_seq'::regclass);


--
-- TOC entry 4816 (class 2604 OID 59271)
-- Name: medicines medicine_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicines ALTER COLUMN medicine_id SET DEFAULT nextval('public.medicines_medicine_id_seq'::regclass);


--
-- TOC entry 4975 (class 0 OID 59279)
-- Dependencies: 222
-- Data for Name: dispensing_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dispensing_records (dispensing_id, medicine_id, student_number, quantity, dispensing_status) FROM stdin;
2	2	STU002	4	Dispensed
1	1	STU001	5	Reversed
\.


--
-- TOC entry 4973 (class 0 OID 59268)
-- Dependencies: 220
-- Data for Name: medicines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicines (medicine_id, medicine_name, stock_quantity) FROM stdin;
3	Ibuprofen	2
2	Amoxicillin	6
1	Paracetamol	50
\.


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 221
-- Name: dispensing_records_dispensing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dispensing_records_dispensing_id_seq', 2, true);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 219
-- Name: medicines_medicine_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicines_medicine_id_seq', 3, true);


--
-- TOC entry 4823 (class 2606 OID 59289)
-- Name: dispensing_records dispensing_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispensing_records
    ADD CONSTRAINT dispensing_records_pkey PRIMARY KEY (dispensing_id);


--
-- TOC entry 4821 (class 2606 OID 59277)
-- Name: medicines medicines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicines
    ADD CONSTRAINT medicines_pkey PRIMARY KEY (medicine_id);


--
-- TOC entry 4824 (class 2606 OID 59290)
-- Name: dispensing_records dispensing_records_medicine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispensing_records
    ADD CONSTRAINT dispensing_records_medicine_id_fkey FOREIGN KEY (medicine_id) REFERENCES public.medicines(medicine_id);


-- Completed on 2026-10-01 23:06:01

--
-- PostgreSQL database dump complete
--

\unrestrict xkEufe0pCQ7xrusTjfZgvZHoAagoxwccv23FE73qOF4EbuklrSZ8EXxHfPfZNIv

