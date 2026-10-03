--
-- PostgreSQL database dump
--

\restrict 1pZL2zeKri9iDK2qHbeZAQ7m7FphaLAYhaTzlbPJJ5O2fSa0jf4Xp0SdDbqjF9W

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-10-01 22:24:18

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
-- TOC entry 234 (class 1255 OID 49819)
-- Name: borrow_book(integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.borrow_book(IN p_book_id integer, IN p_student_number character varying, IN p_quantity integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_copies INTO v_available
    FROM books
    WHERE book_id = p_book_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        RAISE NOTICE 'Book does not exist.';
    ELSIF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity. Quantity must be greater than zero.';
    ELSIF p_quantity > v_available THEN
        RAISE NOTICE 'Loan rejected: only % copies are available.', v_available;
    ELSE
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans (book_id, student_number, quantity, loan_status)
        VALUES (p_book_id, p_student_number, p_quantity, 'Borrowed');

        RAISE NOTICE 'Loan recorded successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.borrow_book(IN p_book_id integer, IN p_student_number character varying, IN p_quantity integer) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 57690)
-- Name: return_book(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.return_book(IN p_loan_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_book_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id
    FOR UPDATE;

    IF v_book_id IS NULL THEN
        RAISE NOTICE 'Loan does not exist.';
    ELSIF v_status = 'Returned' THEN
        RAISE NOTICE 'Loan % has already been returned. Copies will not be restored again.', p_loan_id;
    ELSE
        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        UPDATE book_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Loan returned successfully.';
    END IF;
END $$;


ALTER PROCEDURE public.return_book(IN p_loan_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 57674)
-- Name: book_loans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_loans (
    loan_id integer NOT NULL,
    book_id integer,
    student_number character varying(30) NOT NULL,
    quantity integer NOT NULL,
    loan_status character varying(20) DEFAULT 'Borrowed'::character varying NOT NULL
);


ALTER TABLE public.book_loans OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 57673)
-- Name: book_loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.book_loans_loan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.book_loans_loan_id_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 221
-- Name: book_loans_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.book_loans_loan_id_seq OWNED BY public.book_loans.loan_id;


--
-- TOC entry 220 (class 1259 OID 57663)
-- Name: books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.books (
    book_id integer NOT NULL,
    title character varying(100) NOT NULL,
    available_copies integer NOT NULL,
    CONSTRAINT books_available_copies_check CHECK ((available_copies >= 0))
);


ALTER TABLE public.books OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 57662)
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.books_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.books_book_id_seq OWNER TO postgres;

--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 219
-- Name: books_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.books_book_id_seq OWNED BY public.books.book_id;


--
-- TOC entry 4817 (class 2604 OID 57677)
-- Name: book_loans loan_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_loans ALTER COLUMN loan_id SET DEFAULT nextval('public.book_loans_loan_id_seq'::regclass);


--
-- TOC entry 4816 (class 2604 OID 57666)
-- Name: books book_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books ALTER COLUMN book_id SET DEFAULT nextval('public.books_book_id_seq'::regclass);


--
-- TOC entry 4975 (class 0 OID 57674)
-- Dependencies: 222
-- Data for Name: book_loans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_loans (loan_id, book_id, student_number, quantity, loan_status) FROM stdin;
2	2	STU002	2	Borrowed
1	1	STU001	2	Returned
\.


--
-- TOC entry 4973 (class 0 OID 57663)
-- Dependencies: 220
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.books (book_id, title, available_copies) FROM stdin;
3	Programming in Java	1
2	Computer Networks	1
1	Database Systems	10
\.


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 221
-- Name: book_loans_loan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_loans_loan_id_seq', 2, true);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 219
-- Name: books_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.books_book_id_seq', 3, true);


--
-- TOC entry 4823 (class 2606 OID 57684)
-- Name: book_loans book_loans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_loans
    ADD CONSTRAINT book_loans_pkey PRIMARY KEY (loan_id);


--
-- TOC entry 4821 (class 2606 OID 57672)
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- TOC entry 4824 (class 2606 OID 57685)
-- Name: book_loans book_loans_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_loans
    ADD CONSTRAINT book_loans_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);


-- Completed on 2026-10-01 22:24:18

--
-- PostgreSQL database dump complete
--

\unrestrict 1pZL2zeKri9iDK2qHbeZAQ7m7FphaLAYhaTzlbPJJ5O2fSa0jf4Xp0SdDbqjF9W

