--
-- PostgreSQL database dump
--

\restrict seUJljC3L2gpDOkBlaafa3VeaKBrbDA8hiK4zk49Ld6Aj5cOvxXKIXUWqvQawwz

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

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
-- Name: cosine_similarity(real[], real[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cosine_similarity(a real[], b real[]) RETURNS real
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    dot_product real := 0;
    norm_a real := 0;
    norm_b real := 0;
    i int;
BEGIN
    FOR i IN 1..array_length(a, 1) LOOP
        dot_product := dot_product + (a[i] * b[i]);
        norm_a := norm_a + (a[i] * a[i]);
        norm_b := norm_b + (b[i] * b[i]);
    END LOOP;
    IF norm_a = 0 OR norm_b = 0 THEN
        RETURN 0;
    END IF;
    RETURN dot_product / (sqrt(norm_a) * sqrt(norm_b));
END;
$$;


ALTER FUNCTION public.cosine_similarity(a real[], b real[]) OWNER TO postgres;

--
-- Name: lower(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lower(bytea) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ 
    SELECT lower(convert_from($1, 'UTF8')); 
$_$;


ALTER FUNCTION public.lower(bytea) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_analyses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ai_analyses (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    summary text NOT NULL,
    domain character varying(100) NOT NULL,
    extracted_keywords text[],
    tech_stack text[],
    problem_statement text,
    ai_status character varying(20) DEFAULT 'COMPLETED'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.ai_analyses OWNER TO postgres;

--
-- Name: ai_analyses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ai_analyses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ai_analyses_id_seq OWNER TO postgres;

--
-- Name: ai_analyses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ai_analyses_id_seq OWNED BY public.ai_analyses.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    action character varying(100) NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint,
    details text,
    ip_address character varying(45),
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(20) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departments_id_seq OWNER TO postgres;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: keywords; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keywords (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    normalized_name character varying(100) NOT NULL
);


ALTER TABLE public.keywords OWNER TO postgres;

--
-- Name: keywords_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.keywords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.keywords_id_seq OWNER TO postgres;

--
-- Name: keywords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.keywords_id_seq OWNED BY public.keywords.id;


--
-- Name: project_embeddings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_embeddings (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    embedding_vector real[] NOT NULL,
    model_version character varying(50) DEFAULT 'sentence-transformers/all-MiniLM-L6-v2'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.project_embeddings OWNER TO postgres;

--
-- Name: project_embeddings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_embeddings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_embeddings_id_seq OWNER TO postgres;

--
-- Name: project_embeddings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_embeddings_id_seq OWNED BY public.project_embeddings.id;


--
-- Name: project_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_files (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(50) NOT NULL,
    file_size bigint NOT NULL,
    storage_path character varying(500),
    storage_type character varying(20) DEFAULT 'LOCAL'::character varying,
    uploaded_by_user_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    file_path character varying(500),
    uploaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.project_files OWNER TO postgres;

--
-- Name: project_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_files_id_seq OWNER TO postgres;

--
-- Name: project_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_files_id_seq OWNED BY public.project_files.id;


--
-- Name: project_keywords; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_keywords (
    project_id bigint NOT NULL,
    keyword_id bigint NOT NULL,
    is_ai_generated boolean DEFAULT false NOT NULL
);


ALTER TABLE public.project_keywords OWNER TO postgres;

--
-- Name: project_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_members (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    member_role character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.project_members OWNER TO postgres;

--
-- Name: project_members_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_members_id_seq OWNER TO postgres;

--
-- Name: project_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_members_id_seq OWNED BY public.project_members.id;


--
-- Name: project_workflow_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_workflow_history (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    from_status character varying(20) NOT NULL,
    to_status character varying(20) NOT NULL,
    changed_by_user_id bigint NOT NULL,
    project_id bigint NOT NULL,
    remarks text,
    CONSTRAINT project_workflow_history_from_status_check CHECK (((from_status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'UNDER_REVIEW'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'ARCHIVED'::character varying])::text[]))),
    CONSTRAINT project_workflow_history_to_status_check CHECK (((to_status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'UNDER_REVIEW'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'ARCHIVED'::character varying])::text[])))
);


ALTER TABLE public.project_workflow_history OWNER TO postgres;

--
-- Name: project_workflow_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_workflow_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_workflow_history_id_seq OWNER TO postgres;

--
-- Name: project_workflow_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_workflow_history_id_seq OWNED BY public.project_workflow_history.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    abstract text NOT NULL,
    academic_year character varying(10) NOT NULL,
    semester integer NOT NULL,
    project_type character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    visibility character varying(20) DEFAULT 'PUBLIC'::character varying NOT NULL,
    department_id bigint NOT NULL,
    created_by_user_id bigint NOT NULL,
    repository_url character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    guide_faculty_id bigint,
    plagiarism_score double precision,
    duplication_score double precision,
    plagiarism_report text,
    plagiarism_status character varying(50) DEFAULT 'NOT_SCANNED'::character varying,
    CONSTRAINT projects_semester_check CHECK (((semester >= 1) AND (semester <= 10))),
    CONSTRAINT projects_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'UNDER_REVIEW'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'ARCHIVED'::character varying])::text[]))),
    CONSTRAINT projects_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['PUBLIC'::character varying, 'DEPARTMENT_ONLY'::character varying, 'PRIVATE'::character varying])::text[])))
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_id_seq OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: student_roster; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_roster (
    id bigint NOT NULL,
    roll_no character varying(50) NOT NULL,
    name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    batch character varying(20) NOT NULL,
    department_id bigint,
    is_eligible boolean DEFAULT true,
    is_registered boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.student_roster OWNER TO postgres;

--
-- Name: student_roster_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_roster_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_roster_id_seq OWNER TO postgres;

--
-- Name: student_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_roster_id_seq OWNED BY public.student_roster.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    user_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    department_id bigint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(150) NOT NULL,
    roll_no character varying(50),
    must_change_password boolean DEFAULT false,
    otp_code character varying(10),
    otp_expiry timestamp without time zone,
    failed_login_attempts integer DEFAULT 0,
    lockout_until timestamp without time zone,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['ADMIN'::character varying, 'FACULTY'::character varying, 'STUDENT'::character varying])::text[]))),
    CONSTRAINT users_user_status_check CHECK (((user_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'PENDING'::character varying, 'ALUMNI'::character varying, 'INACTIVE'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: ai_analyses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_analyses ALTER COLUMN id SET DEFAULT nextval('public.ai_analyses_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: keywords id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords ALTER COLUMN id SET DEFAULT nextval('public.keywords_id_seq'::regclass);


--
-- Name: project_embeddings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_embeddings ALTER COLUMN id SET DEFAULT nextval('public.project_embeddings_id_seq'::regclass);


--
-- Name: project_files id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_files ALTER COLUMN id SET DEFAULT nextval('public.project_files_id_seq'::regclass);


--
-- Name: project_members id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members ALTER COLUMN id SET DEFAULT nextval('public.project_members_id_seq'::regclass);


--
-- Name: project_workflow_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_workflow_history ALTER COLUMN id SET DEFAULT nextval('public.project_workflow_history_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: student_roster id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_roster ALTER COLUMN id SET DEFAULT nextval('public.student_roster_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: ai_analyses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_analyses (id, project_id, summary, domain, extracted_keywords, tech_stack, problem_statement, ai_status, created_at, updated_at) FROM stdin;
2	2	Distress AI is an intelligent multi-modal video surveillance framework designed to detect emotional distress, suspicious physical postures, and immediate safety threats in real-time. By integrating deep learning facial emotion recognition with skeletal posture tracking via MediaPipe, the system continuously monitors camera feeds to identify violent altercations, distress calls, or sudden medical collapses. When a potential threat is identified, the system logs the incident, triggers low-latency dispatcher alerts, and provides campus or enterprise security personnel with contextual video snippets to accelerate emergency response.	Computer Vision & Public Safety	{"Computer Vision & Public Safety",Python,OpenCV,MediaPipe,FastAPI}	{Python,OpenCV,MediaPipe,FastAPI,React,SQLite}	Distress AI is an intelligent multi-modal video surveillance framework designed to detect emotional distress, suspicious physical postures, and immediate safety threats in real-time. By integrating deep learning facial emotion recognition with skeletal posture tracking via MediaPipe, the system cont	COMPLETED	2026-10-12 15:14:56.130594+05:30	2026-10-12 18:54:45.31449+05:30
4	4	Software Bug Assistant is an autonomous AI agent engineered to streamline the software defect resolution lifecycle using the Agent Development Kit (ADK) and large language model reasoning. The system ingests application crash traces, diagnostic logs, and issue tracker tickets to automatically isolate root causes within codebase repositories. By synthesizing reproduction test harnesses in sandboxed containers, the agent verifies defect existence, generates candidate code patches, runs regression unit tests, and submits formal Pull Requests with comprehensive technical summaries.	Agentic AI & Automated Software Engineering	{"Agentic AI & Automated Software Engineering",Python,"Google Cloud ADK","Gemini 1.5 Pro",Docker}	{Python,"Google Cloud ADK","Gemini 1.5 Pro",Docker,Git}	Software Bug Assistant is an autonomous AI agent engineered to streamline the software defect resolution lifecycle using the Agent Development Kit (ADK) and large language model reasoning. The system ingests application crash traces, diagnostic logs, and issue tracker tickets to automatically isolat	COMPLETED	2026-10-12 15:15:27.035387+05:30	2026-10-12 18:54:45.435052+05:30
5	5	QGenesis is an AI-powered academic question bank and examination paper workflow orchestration platform developed for higher educational institutions. The platform empowers faculty members to extract and synthesize rigorous examination questions from course syllabi, lecture slides, and reference materials across varying Bloom's taxonomy cognitive levels. QGenesis incorporates role-based approval pipelines routing draft question papers through Head of Department (HOD) review, dynamic paper randomization, and strict institutional confidentiality controls.	EdTech & Workflow Management	{"EdTech & Workflow Management",React,Node.js,"Firebase Firestore",Express}	{React,Node.js,"Firebase Firestore",Express,NLP}	QGenesis is an AI-powered academic question bank and examination paper workflow orchestration platform developed for higher educational institutions. The platform empowers faculty members to extract and synthesize rigorous examination questions from course syllabi, lecture slides, and reference mate	COMPLETED	2026-10-12 15:15:35.225357+05:30	2026-10-12 18:54:45.493426+05:30
7	7	This project implements a real-time cloud log anomaly detection framework featuring dynamic detector switching over distributed Kafka message streams. Addressing the challenge of concept drift and bursty cloud infrastructure logs, the architecture evaluates incoming log streams and adaptively toggles between lightweight Static thresholding, statistical Adaptive baselining, and deep-learning LSTM sequence detectors. Experimental evaluation demonstrates enhanced anomaly detection precision and reduced alert fatigue across heterogeneous cloud infrastructure logs.	Cloud Computing & Streaming Analytics	{"Cloud Computing & Streaming Analytics",Python,"Apache Kafka",LSTM,Scikit-Learn}	{Python,"Apache Kafka",LSTM,Scikit-Learn,FastAPI}	This project implements a real-time cloud log anomaly detection framework featuring dynamic detector switching over distributed Kafka message streams. Addressing the challenge of concept drift and bursty cloud infrastructure logs, the architecture evaluates incoming log streams and adaptively toggle	COMPLETED	2026-10-12 15:15:43.276405+05:30	2026-10-12 18:54:45.603253+05:30
8	8	SybilGuard is an interactive graph analytics and visualization platform for detecting Sybil accounts (fake, coordinated malicious nodes) within large-scale social network topologies. By implementing random walk-based trust propagation algorithms including SybilRank, SybilWalk, and SybilWalk-Var alongside an ensemble scoring model, the system identifies anomalous clusters where trust fails to propagate naturally. An interactive 3D graph visualization interface enables security analysts to inspect network communities, trace trust vectors, and isolate coordinated inauthentic behavior.	Graph Mining & Social Network Security	{"Graph Mining & Social Network Security",Python,NetworkX,Three.js,Flask}	{Python,NetworkX,Three.js,Flask,SciPy}	SybilGuard is an interactive graph analytics and visualization platform for detecting Sybil accounts (fake, coordinated malicious nodes) within large-scale social network topologies. By implementing random walk-based trust propagation algorithms including SybilRank, SybilWalk, and SybilWalk-Var alon	COMPLETED	2026-10-12 15:15:43.65818+05:30	2026-10-12 18:54:45.657823+05:30
9	9	This research introduces a hybrid machine learning and deep learning architecture for high-velocity online banking fraud detection. The framework pairs an optimized XGBoost gradient-boosted decision tree pipeline for evaluating tabular transaction features (amounts, geolocations, terminal IDs) with a recurrent LSTM neural network that models longitudinal customer spending sequences. The combined model achieves high precision and an 87.41% F1-score on skewed transaction benchmarks, significantly reducing false positive declines while detecting sophisticated financial fraud patterns.	FinTech & Deep Learning	{"FinTech & Deep Learning",Python,XGBoost,TensorFlow,Keras}	{Python,XGBoost,TensorFlow,Keras,Scikit-Learn}	This research introduces a hybrid machine learning and deep learning architecture for high-velocity online banking fraud detection. The framework pairs an optimized XGBoost gradient-boosted decision tree pipeline for evaluating tabular transaction features (amounts, geolocations, terminal IDs) with 	COMPLETED	2026-10-12 15:15:44.529263+05:30	2026-10-12 18:54:45.715594+05:30
12	12	Academic Integrity Checker is an automated research dissertation verification engine designed to uphold academic rigor in institutional project repositories. The platform evaluates submitted abstracts, technical reports, and source code against indexed institutional repositories and open web sources. By combining N-gram fingerprinting, semantic vector distance, and intelligent citation filtering (excluding references, datasets, and standard libraries), the system delivers an objective similarity score and an itemized originality audit report for academic review committees.	Natural Language Processing & Academic Auditing	{"Natural Language Processing & Academic Auditing",Python,FastAPI,NLTK,PyMuPDF}	{Python,FastAPI,NLTK,PyMuPDF,React}	Academic Integrity Checker is an automated research dissertation verification engine designed to uphold academic rigor in institutional project repositories. The platform evaluates submitted abstracts, technical reports, and source code against indexed institutional repositories and open web sources	COMPLETED	2026-10-12 15:16:28.998126+05:30	2026-10-12 18:54:45.961488+05:30
13	13	This research investigates vulnerabilities in deep Convolutional Neural Networks (CNNs) subjected to adversarial evasion attacks and introduces empirical defense mechanisms. The project benchmarks standard CNN models against Fast Gradient Sign Method (FGSM) and Projected Gradient Descent (PGD) perturbation attacks, demonstrating significant accuracy degradation under imperceptible noise. Through adversarial retraining, gradient regularization, and robust feature feature distillation, the proposed architecture substantially enhances classification robustness on perturbed vision datasets.	Deep Learning & AI Security	{"Deep Learning & AI Security",Python,PyTorch,Torchvision,NumPy}	{Python,PyTorch,Torchvision,NumPy,Matplotlib}	This research investigates vulnerabilities in deep Convolutional Neural Networks (CNNs) subjected to adversarial evasion attacks and introduces empirical defense mechanisms. The project benchmarks standard CNN models against Fast Gradient Sign Method (FGSM) and Projected Gradient Descent (PGD) pertu	COMPLETED	2026-10-12 15:16:33.354892+05:30	2026-10-12 18:54:46.031966+05:30
15	15	Innovest is a comprehensive platform bridging student entrepreneurs and venture investors with integrated AI feasibility analytics. The platform features an automated novelty checker that scans submitted business proposals against indexed startup repositories to prevent duplicated concepts and evaluate commercial viability. Innovest enforces structured feedback loops between mentors, investors, and founders, facilitating milestone-driven incubation within academic institutions.	FinTech & Venture Matchmaking	{"FinTech & Venture Matchmaking",React,Vite,Node.js,Express}	{React,Vite,Node.js,Express,Python,MongoDB}	Innovest is a comprehensive platform bridging student entrepreneurs and venture investors with integrated AI feasibility analytics. The platform features an automated novelty checker that scans submitted business proposals against indexed startup repositories to prevent duplicated concepts and evalu	COMPLETED	2026-10-12 15:16:34.562309+05:30	2026-10-12 18:54:46.169085+05:30
16	16	The Automated Outcome-Based Education (OBE) Mapping Tool is an institutional portal built to automate complex academic accreditation workflows in compliance with NBA and NAAC guidelines. The application maps course outcomes (COs) to program outcomes (POs) and program-specific outcomes (PSOs), processes multi-assessment student scores, and automatically computes direct and indirect attainment levels. The system replaces manual spreadsheets with verifiable analytics dashboards and exportable institutional accreditation reports.	EdTech & Academic Accreditation	{"EdTech & Academic Accreditation",React,Express,Node.js,MySQL}	{React,Express,Node.js,MySQL,ExcelJS}	The Automated Outcome-Based Education (OBE) Mapping Tool is an institutional portal built to automate complex academic accreditation workflows in compliance with NBA and NAAC guidelines. The application maps course outcomes (COs) to program outcomes (POs) and program-specific outcomes (PSOs), proces	COMPLETED	2026-10-12 15:16:38.662561+05:30	2026-10-12 18:54:46.225901+05:30
17	17	PreVue is a full-stack AI-driven mock interview preparation platform designed to enhance student placement readiness. Candidates undergo interactive simulated interviews featuring automated speech-to-text transcription, NLP semantic analysis of technical responses, and speech fluency evaluations. PreVue delivers personalized performance scorecards highlighting domain competency, pacing, vocabulary richness, and actionable recommendations to help students excel in corporate technical and HR interviews.	EdTech & Speech/NLP Analytics	{"EdTech & Speech/NLP Analytics",React,TypeScript,Python,FastAPI}	{React,TypeScript,Python,FastAPI,WebRTC,Supabase}	PreVue is a full-stack AI-driven mock interview preparation platform designed to enhance student placement readiness. Candidates undergo interactive simulated interviews featuring automated speech-to-text transcription, NLP semantic analysis of technical responses, and speech fluency evaluations. Pr	COMPLETED	2026-10-12 15:16:40.32863+05:30	2026-10-12 18:54:46.283419+05:30
19	19	CloudInsight is a comprehensive FinOps analytics platform for monitoring, forecasting, and optimizing multi-cloud expenditures across AWS, Microsoft Azure, and Google Cloud Platform. The system ingests billing logs and cost telemetry, applying time-series anomaly detection algorithms to identify sudden resource billing spikes, orphaned disk volumes, and underutilized instances. Interactive dashboards provide department budget allocations, automated slack notifications, and actionable cloud resource rightsizing recommendations.	Cloud Computing & Financial Operations (FinOps)	{"Cloud Computing & Financial Operations (FinOps)",React,Python,FastAPI,PostgreSQL}	{React,Python,FastAPI,PostgreSQL,Chart.js}	CloudInsight is a comprehensive FinOps analytics platform for monitoring, forecasting, and optimizing multi-cloud expenditures across AWS, Microsoft Azure, and Google Cloud Platform. The system ingests billing logs and cost telemetry, applying time-series anomaly detection algorithms to identify sud	COMPLETED	2026-10-12 15:16:42.159035+05:30	2026-10-12 18:54:46.397606+05:30
22	22	This project presents an empirical malware detection and classification engine analyzing Windows Portable Executable (PE) binaries. The framework extracts static feature vectors including PE header fields, section entropy levels, imported API functions, and byte n-gram frequencies. Machine learning classifiers (Random Forest, Support Vector Machines, and Gradient Boosting) are trained to distinguish benign software from ransomware, trojans, and spyware, achieving high classification accuracy with low false-alarm rates.	Malware Forensics & Threat Intelligence	{"Malware Forensics & Threat Intelligence",Python,Scikit-Learn,PEfile,"Random Forest"}	{Python,Scikit-Learn,PEfile,"Random Forest",Flask}	This project presents an empirical malware detection and classification engine analyzing Windows Portable Executable (PE) binaries. The framework extracts static feature vectors including PE header fields, section entropy levels, imported API functions, and byte n-gram frequencies. Machine learning 	COMPLETED	2026-10-12 15:16:48.025058+05:30	2026-10-12 18:54:46.61861+05:30
23	23	EduSlot is a centralized campus resource reservation and scheduling system developed for PSG College of Technology. The platform eliminates scheduling collisions by managing access to computing laboratories, specialized hardware kits, seminar auditoriums, and project incubation spaces. EduSlot features faculty approval workflows, automated email booking notifications, and QR-based reservation passes to optimize institutional infrastructure utilization.	Campus Automation & Scheduling	{"Campus Automation & Scheduling",React,Express,Node.js,MongoDB}	{React,Express,Node.js,MongoDB,"Tailwind CSS"}	EduSlot is a centralized campus resource reservation and scheduling system developed for PSG College of Technology. The platform eliminates scheduling collisions by managing access to computing laboratories, specialized hardware kits, seminar auditoriums, and project incubation spaces. EduSlot featu	COMPLETED	2026-10-12 15:16:53.608984+05:30	2026-10-12 18:54:46.690209+05:30
24	24	ThinkTwice is an intelligent browser extension for Google Chrome that assists users in reviewing and refining written correspondence prior to transmission. Compatible with Gmail, LinkedIn, and WhatsApp Web, the extension evaluates draft messages using sentiment analysis and tone classification. ThinkTwice highlights potential tone misalignments (such as unintended aggression, passive-aggressiveness, or unprofessional phrasing) and suggests context-appropriate rewrites tailored for colleagues, supervisors, or external clients.	Natural Language Processing & HCI	{"Natural Language Processing & HCI",JavaScript,"Chrome Extensions API",FastAPI,NLP}	{JavaScript,"Chrome Extensions API",FastAPI,NLP}	ThinkTwice is an intelligent browser extension for Google Chrome that assists users in reviewing and refining written correspondence prior to transmission. Compatible with Gmail, LinkedIn, and WhatsApp Web, the extension evaluates draft messages using sentiment analysis and tone classification. Thin	COMPLETED	2026-10-12 15:16:53.952981+05:30	2026-10-12 18:54:46.745114+05:30
26	26	Apartment Manager is a full-stack residential community management portal streamlining facility administration and resident communication. The platform automates monthly maintenance billing, provides digital payment tracking, and features an SLA-backed maintenance ticketing module for plumbing, electrical, and facility complaints. Role-based dashboards for residents, committee administrators, and security personnel ensure transparent residential society operations.	Smart Communities & Enterprise Web Systems	{"Smart Communities & Enterprise Web Systems",React,Node.js,Express,PostgreSQL}	{React,Node.js,Express,PostgreSQL,JWT}	Apartment Manager is a full-stack residential community management portal streamlining facility administration and resident communication. The platform automates monthly maintenance billing, provides digital payment tracking, and features an SLA-backed maintenance ticketing module for plumbing, elec	COMPLETED	2026-10-12 15:16:59.961955+05:30	2026-10-12 18:54:46.850314+05:30
27	27	KeySense is a continuous identity authentication system leveraging behavioral biometrics derived from user keystroke and mouse interaction dynamics. By capturing keystroke hold times, key flight intervals, and mouse curvature kinematics during natural computer interaction, KeySense trains personalized anomaly detection models to verify active user identity. The system provides non-intrusive secondary authentication, automatically locking sessions when anomalous typing behavior indicates unauthorized workstation takeover.	Biometric Security & Pattern Recognition	{"Biometric Security & Pattern Recognition",Python,FastAPI,Scikit-Learn,React}	{Python,FastAPI,Scikit-Learn,React,JavaScript}	KeySense is a continuous identity authentication system leveraging behavioral biometrics derived from user keystroke and mouse interaction dynamics. By capturing keystroke hold times, key flight intervals, and mouse curvature kinematics during natural computer interaction, KeySense trains personaliz	COMPLETED	2026-10-12 15:17:07.031847+05:30	2026-10-12 18:54:46.899129+05:30
29	29	TN SchemeBot is a conversational AI e-governance assistant built to help citizens discover and apply for Tamil Nadu state and central welfare schemes. Through intuitive natural language dialogue in English and Tamil, the chatbot collects applicant eligibility parameters (income, occupation, educational status, demographic category) and matches them against indexed government scheme repositories. The system details entitlement benefits, required documentation, and direct official application links to enhance public welfare access.	NLP & E-Governance Systems	{"NLP & E-Governance Systems",HTML5/JS,Python,Flask,spaCy}	{HTML5/JS,Python,Flask,spaCy,SQLite}	TN SchemeBot is a conversational AI e-governance assistant built to help citizens discover and apply for Tamil Nadu state and central welfare schemes. Through intuitive natural language dialogue in English and Tamil, the chatbot collects applicant eligibility parameters (income, occupation, educatio	COMPLETED	2026-10-12 15:17:07.591267+05:30	2026-10-12 18:54:47.01514+05:30
30	30	NextDoorConnect is a hyperlocal community platform designed to foster mutual assistance and resource sharing among verified neighborhood residents. The platform enables residents to lend household equipment, offer local tutoring or handyman skills, organize neighborhood clean-ups, and broadcast urgent local safety alerts. By restricting membership to geographic zones and verifying address credentials, NextDoorConnect creates a secure, trusted digital community network.	Distributed Social Networks & Civic Tech	{"Distributed Social Networks & Civic Tech",React,Node.js,Express,MongoDB}	{React,Node.js,Express,MongoDB,Socket.io}	NextDoorConnect is a hyperlocal community platform designed to foster mutual assistance and resource sharing among verified neighborhood residents. The platform enables residents to lend household equipment, offer local tutoring or handyman skills, organize neighborhood clean-ups, and broadcast urge	COMPLETED	2026-10-12 15:17:09.949971+05:30	2026-10-12 18:54:47.066726+05:30
32	32	LoraOffNet is a disaster-resilient off-grid communication and micro-transaction framework operating without cellular or internet infrastructure. The architecture connects smartphones via local Wi-Fi access points to ESP32 LoRa nodes, which form an ad-hoc long-range radio mesh network using the SX1276 transceiver. The system enables reliable text messaging, emergency SOS beaconing, and cryptographically verified offline store-and-forward digital payments during natural disasters and remote network blackouts.	Emergency Communications & IoT Networks	{"Emergency Communications & IoT Networks","ESP32 Heltec LoRa V2","C++ / Arduino",RadioLib,"Android / Java"}	{"ESP32 Heltec LoRa V2","C++ / Arduino",RadioLib,"Android / Java"}	LoraOffNet is a disaster-resilient off-grid communication and micro-transaction framework operating without cellular or internet infrastructure. The architecture connects smartphones via local Wi-Fi access points to ESP32 LoRa nodes, which form an ad-hoc long-range radio mesh network using the SX127	COMPLETED	2026-10-12 15:17:14.385227+05:30	2026-10-12 18:54:47.174565+05:30
33	33	Own Drive is an intelligent hybrid file storage solution that seamlessly unifies local disk storage with Google Drive cloud infrastructure. Operating through a 3-priority classification pipeline (user-defined rules, file access metadata, and predictive ML classification), Own Drive automatically tiers frequently accessed sensitive files to high-speed local storage while archiving cold backups to cloud storage. The system features JWT authentication, encrypted transfers, and transparent virtual filesystem access.	Cloud Storage & Intelligent Tiering	{"Cloud Storage & Intelligent Tiering",React,Node.js,Python,"Google Drive API"}	{React,Node.js,Python,"Google Drive API",MongoDB}	Own Drive is an intelligent hybrid file storage solution that seamlessly unifies local disk storage with Google Drive cloud infrastructure. Operating through a 3-priority classification pipeline (user-defined rules, file access metadata, and predictive ML classification), Own Drive automatically tie	COMPLETED	2026-10-12 15:17:14.48141+05:30	2026-10-12 18:54:47.233008+05:30
35	35	SpeakMate is an interactive web-based speech coaching platform tailored for postgraduate students to improve their English public speaking and presentation fluency. Through structured, level-based speaking challenges, SpeakMate analyzes live audio streams to evaluate speaking rate, pause frequency, filler-word repetition ('um', 'uh', 'like'), and grammatical clarity. Candidates receive visual analytics dashboards with targeted vocal drills to build confident professional communication skills.	Speech AI & Natural Language Processing	{"Speech AI & Natural Language Processing",React,Node.js,"Web Speech API",FastAPI}	{React,Node.js,"Web Speech API",FastAPI,MongoDB}	SpeakMate is an interactive web-based speech coaching platform tailored for postgraduate students to improve their English public speaking and presentation fluency. Through structured, level-based speaking challenges, SpeakMate analyzes live audio streams to evaluate speaking rate, pause frequency, 	COMPLETED	2026-10-12 15:17:19.600885+05:30	2026-10-12 18:54:47.330724+05:30
36	36	ThinkInLogic is an adaptive programming education platform designed by Jawahar Paisal P (24MX320) that personalizes coding problem recommendations using a Reinforcement Learning (Q-learning) engine. The system continuously evaluates student submission success rates, time-to-solve metrics, and code efficiency across difficulty levels, dynamically adapting the learning curve to address individual algorithmic weaknesses and maximize campus placement readiness.	Reinforcement Learning & EdTech	{"Reinforcement Learning & EdTech",React,Node.js,Express,Python}	{React,Node.js,Express,Python,Q-Learning,MongoDB}	ThinkInLogic is an adaptive programming education platform designed by Jawahar Paisal P (24MX320) that personalizes coding problem recommendations using a Reinforcement Learning (Q-learning) engine. The system continuously evaluates student submission success rates, time-to-solve metrics, and code e	COMPLETED	2026-10-12 15:17:19.681195+05:30	2026-10-12 18:54:47.384042+05:30
38	38	Dubbify is an automated multimedia localization engine that dubs video recordings into regional Indian and international languages while preserving natural speaker pacing. The pipeline utilizes OpenAI Whisper for speech-to-text diarization, neural machine translation for semantic cross-lingual mapping, and neural text-to-speech models to synthesize localized audio tracks. FFmpeg dynamically adjusts speech timing and overlays the synthesized audio onto the original video with lip-sync alignment.	Generative AI & Audio-Visual Localization	{"Generative AI & Audio-Visual Localization",React,Python,FastAPI,Whisper}	{React,Python,FastAPI,Whisper,"Coqui TTS",FFmpeg}	Dubbify is an automated multimedia localization engine that dubs video recordings into regional Indian and international languages while preserving natural speaker pacing. The pipeline utilizes OpenAI Whisper for speech-to-text diarization, neural machine translation for semantic cross-lingual mappi	COMPLETED	2026-10-12 15:17:31.491383+05:30	2026-10-12 18:54:47.482264+05:30
1	1	NexusLOS is an advanced AI-driven Loan Origination System designed to provide high-accuracy credit scoring while prioritizing borrower transparency and regulatory compliance. Unlike traditional black-box machine learning models that reject loan applicants without clear justification, NexusLOS utilizes Explainable AI (XAI) with SHAP and LIME to generate specific reason codes and actionable rejection roadmaps for borrowers. The system implements a dual lending path evaluating both income-based repayment capacity from banking telemetry and asset-based lending collateral, providing a transparent, auditable, and equitable digital lending infrastructure.	FinTech & Explainable AI	{"FinTech & Explainable AI",Python,FastAPI,React,PyTorch}	{Python,FastAPI,React,PyTorch,SHAP,PostgreSQL}	NexusLOS is an advanced AI-driven Loan Origination System designed to provide high-accuracy credit scoring while prioritizing borrower transparency and regulatory compliance. Unlike traditional black-box machine learning models that reject loan applicants without clear justification, NexusLOS utiliz	COMPLETED	2026-10-12 15:14:43.224497+05:30	2026-10-12 18:54:45.072414+05:30
3	3	SC-GUARD is an automated smart contract vulnerability detection and security audit platform targeting Ethereum Solidity contracts. The system performs comprehensive Abstract Syntax Tree (AST) static analysis and symbolic execution to identify critical security flaws such as reentrancy vulnerabilities, arithmetic overflows, unchecked external calls, and front-running exposures. Based on detected vulnerability signatures, SC-GUARD calculates a composite security risk index and enforces automated deployment decisions (ALLOW, WARN, or BLOCK), generating detailed diagnostic reports in JSON, HTML, and PDF formats for smart contract developers.	Blockchain Security & Static Analysis	{"Blockchain Security & Static Analysis",Solidity,Python,Slither,PyInstaller}	{Solidity,Python,Slither,PyInstaller,PowerShell}	SC-GUARD is an automated smart contract vulnerability detection and security audit platform targeting Ethereum Solidity contracts. The system performs comprehensive Abstract Syntax Tree (AST) static analysis and symbolic execution to identify critical security flaws such as reentrancy vulnerabilitie	COMPLETED	2026-10-12 15:14:57.445625+05:30	2026-10-12 18:54:45.376223+05:30
6	6	PII Shield is an automated sensitive data discovery and redaction platform designed to ensure compliance with institutional and regulatory data privacy mandates (such as GDPR and HIPAA). The system scans unstructured enterprise documents (PDF, DOCX, TXT) using specialized Named Entity Recognition (NER) models and deterministic regular expressions to detect Personally Identifiable Information (PII) including Aadhaar numbers, PAN cards, credit details, email addresses, and phone numbers, permanently redacting sensitive coordinates while preserving document structural readability.	Privacy Engineering & Natural Language Processing	{"Privacy Engineering & Natural Language Processing",Python,spaCy,PyMuPDF,Regex}	{Python,spaCy,PyMuPDF,Regex,ReportLab}	PII Shield is an automated sensitive data discovery and redaction platform designed to ensure compliance with institutional and regulatory data privacy mandates (such as GDPR and HIPAA). The system scans unstructured enterprise documents (PDF, DOCX, TXT) using specialized Named Entity Recognition (N	COMPLETED	2026-10-12 15:15:35.338476+05:30	2026-10-12 18:54:45.545283+05:30
10	10	TRUSTLES is a lightweight enterprise zero-trust endpoint monitoring and continuous posture evaluation system. Operating under the 'never trust, always verify' paradigm, background monitoring agents track process creation, network socket bindings, privilege escalation, and file system anomalies on client machines. Telemetry is streamed to a central risk engine that dynamically computes an endpoint health index, automatically revoking session tokens and isolating endpoints when suspicious behavior or integrity degradation is observed.	Cybersecurity & Zero Trust Architecture	{"Cybersecurity & Zero Trust Architecture",Python,C++,FastAPI,SQLite}	{Python,C++,FastAPI,SQLite,React}	TRUSTLES is a lightweight enterprise zero-trust endpoint monitoring and continuous posture evaluation system. Operating under the 'never trust, always verify' paradigm, background monitoring agents track process creation, network socket bindings, privilege escalation, and file system anomalies on cl	COMPLETED	2026-10-12 15:15:44.642762+05:30	2026-10-12 18:54:45.804505+05:30
11	11	Secure Image System is a high-security multimedia encryption and transfer framework combining Chen hyperchaotic systems with hybrid asymmetric-symmetric cryptography. The pipeline utilizes the high-dimensional pseudo-random entropy of Chen chaotic attractors to perform pixel-level position scrambling and diffusion, followed by AES-256-CBC cipher block chaining. Session keys are secured via RSA-2048/OAEP asymmetric key exchange, ensuring resilience against differential cryptanalysis, statistical pixel distribution attacks, and eavesdropping during high-speed image transmission.	Applied Cryptography & Multimedia Security	{"Applied Cryptography & Multimedia Security",Python,OpenCV,Cryptography,AES-256}	{Python,OpenCV,Cryptography,AES-256,RSA-2048}	Secure Image System is a high-security multimedia encryption and transfer framework combining Chen hyperchaotic systems with hybrid asymmetric-symmetric cryptography. The pipeline utilizes the high-dimensional pseudo-random entropy of Chen chaotic attractors to perform pixel-level position scramblin	COMPLETED	2026-10-12 15:15:44.719253+05:30	2026-10-12 18:54:45.886594+05:30
14	14	DPDE (Decentralized Patient Data Exchange) is a patient-centric Electronic Health Record (EHR) management system giving individuals full sovereignty over medical record sharing. Patient medical records are encrypted on the client device prior to network egress and pinned to decentralized InterPlanetary File System (IPFS) storage. Granular data access consent (request, approve, revoke) is managed via smart contracts deployed on the Ethereum testnet, while a Node.js backend maintains auditable access logs and cryptographically enforces on-chain patient permission.	HealthTech & Web3 Decentralized Systems	{"HealthTech & Web3 Decentralized Systems",Solidity,IPFS,React,Vite}	{Solidity,IPFS,React,Vite,Node.js,MongoDB}	DPDE (Decentralized Patient Data Exchange) is a patient-centric Electronic Health Record (EHR) management system giving individuals full sovereignty over medical record sharing. Patient medical records are encrypted on the client device prior to network egress and pinned to decentralized InterPlanet	COMPLETED	2026-10-12 15:16:34.436972+05:30	2026-10-12 18:54:46.104165+05:30
18	18	Smart Toll is an intelligent highway travel planning and cost estimation web platform designed for Indian national highways. Users input trip origin and destination points to compute real-time route alternatives, calculate cumulative FASTag toll expenditures across toll plazas, and verify prepaid balance sufficiency before travel. The system incorporates a pre-trip alert notification engine and distance-optimized routing to minimize travel delays and unforeseen highway transit costs.	Intelligent Transportation & Geospatial Analytics	{"Intelligent Transportation & Geospatial Analytics",React,Node.js,Leaflet,"OpenStreetMap API"}	{React,Node.js,Leaflet,"OpenStreetMap API",Express}	Smart Toll is an intelligent highway travel planning and cost estimation web platform designed for Indian national highways. Users input trip origin and destination points to compute real-time route alternatives, calculate cumulative FASTag toll expenditures across toll plazas, and verify prepaid ba	COMPLETED	2026-10-12 15:16:40.457906+05:30	2026-10-12 18:54:46.337788+05:30
20	20	EdgeVerify is a distributed security framework focused on validating firmware integrity and message authenticity across resource-constrained Edge IoT nodes. Operating without continuous cloud connectivity, edge gateways exchange cryptographic attestation tokens and verify sensor payload hash trees to detect compromised or rogue edge sensors. The system ensures high fault-tolerance, low verification latency, and end-to-end data integrity for critical industrial and smart city IoT deployments.	Edge Computing & IoT Security	{"Edge Computing & IoT Security",React,Node.js,Python,Cryptography}	{React,Node.js,Python,Cryptography,MQTT}	EdgeVerify is a distributed security framework focused on validating firmware integrity and message authenticity across resource-constrained Edge IoT nodes. Operating without continuous cloud connectivity, edge gateways exchange cryptographic attestation tokens and verify sensor payload hash trees t	COMPLETED	2026-10-12 15:16:47.861738+05:30	2026-10-12 18:54:46.468803+05:30
21	21	EvoDoc is an intelligent developer assistant integrated into Visual Studio Code that automates codebase documentation generation and continuous documentation validation. Operating in watch mode, EvoDoc parses Abstract Syntax Trees (ASTs) on file saves to synchronize inline documentation, class diagrams, and API specifications with evolving code changes. Built-in coverage audits identify undocumented functions and stale comments, ensuring codebase maintainability in agile development environments.	Developer Tooling & Software Engineering	{"Developer Tooling & Software Engineering",TypeScript,"VS Code Extension API",Node.js,"OpenAI API"}	{TypeScript,"VS Code Extension API",Node.js,"OpenAI API"}	EvoDoc is an intelligent developer assistant integrated into Visual Studio Code that automates codebase documentation generation and continuous documentation validation. Operating in watch mode, EvoDoc parses Abstract Syntax Trees (ASTs) on file saves to synchronize inline documentation, class diagr	COMPLETED	2026-10-12 15:16:47.937936+05:30	2026-10-12 18:54:46.543326+05:30
25	25	This project develops a hybrid personalized music recommendation engine combining acoustic audio feature extraction with collaborative filtering algorithms. Using Librosa, the system extracts spectral contrast, tempo, and MFCC features from audio waveforms to quantify acoustic similarity, while matrix factorization models user listening histories. The hybrid approach mitigates the cold-start problem for newly released tracks and delivers tailored music discovery playlists aligned with user preference profiles.	Recommender Systems & Audio Signal Processing	{"Recommender Systems & Audio Signal Processing",Python,Librosa,PyTorch,FastAPI}	{Python,Librosa,PyTorch,FastAPI,React}	This project develops a hybrid personalized music recommendation engine combining acoustic audio feature extraction with collaborative filtering algorithms. Using Librosa, the system extracts spectral contrast, tempo, and MFCC features from audio waveforms to quantify acoustic similarity, while matr	COMPLETED	2026-10-12 15:16:58.294057+05:30	2026-10-12 18:54:46.801164+05:30
28	28	Segro is an embedded IoT and computer vision waste segregation system engineered to automate solid waste sorting at the point of disposal. The hardware apparatus utilizes inductive proximity sensors, capacitive moisture probes, and camera feeds to classify waste into biodegradable, metallic, and recyclable categories. Motorized servo actuators steer waste into designated bins, while telemetry logged over MQTT provides municipal administrators with real-time bin fill-level notifications and waste generation statistics.	IoT & Environmental Robotics	{"IoT & Environmental Robotics","Arduino / ESP32",C++,Python,OpenCV}	{"Arduino / ESP32",C++,Python,OpenCV,MQTT}	Segro is an embedded IoT and computer vision waste segregation system engineered to automate solid waste sorting at the point of disposal. The hardware apparatus utilizes inductive proximity sensors, capacitive moisture probes, and camera feeds to classify waste into biodegradable, metallic, and rec	COMPLETED	2026-10-12 15:17:07.106195+05:30	2026-10-12 18:54:46.954458+05:30
31	31	TechPack Analyzer is an apparel enterprise web application designed to automate Bill of Materials (BOM) generation and costing estimation from technical garment specification sheets. The application parses client tech pack PDFs, extracting fabric compositions, garment dimensions, trim requirements, and colorway codes. Merchandisers can configure unit material pricing to instantly generate accurate production costing sheets and export professional Excel BOM reports for textile manufacturing export houses.	Enterprise ERP & Textile Technology	{"Enterprise ERP & Textile Technology",React,Node.js,Express,"MongoDB Atlas"}	{React,Node.js,Express,"MongoDB Atlas",PDF-Parse}	TechPack Analyzer is an apparel enterprise web application designed to automate Bill of Materials (BOM) generation and costing estimation from technical garment specification sheets. The application parses client tech pack PDFs, extracting fabric compositions, garment dimensions, trim requirements, 	COMPLETED	2026-10-12 15:17:13.948048+05:30	2026-10-12 18:54:47.119967+05:30
34	34	Bulkify is a high-throughput, fault-tolerant batch data processing pipeline engineered to ingest, validate, and transform massive enterprise datasets without service degradation. Implementing stream-based chunking, Redis-backed job queues, and dead-letter error queues, Bulkify processes millions of records with strict schema validation and real-time ingestion monitoring dashboards, ensuring robust data loading for enterprise analytics warehouses.	Big Data Pipelines & Distributed Systems	{"Big Data Pipelines & Distributed Systems",Node.js,TypeScript,BullMQ,Redis}	{Node.js,TypeScript,BullMQ,Redis,PostgreSQL}	Bulkify is a high-throughput, fault-tolerant batch data processing pipeline engineered to ingest, validate, and transform massive enterprise datasets without service degradation. Implementing stream-based chunking, Redis-backed job queues, and dead-letter error queues, Bulkify processes millions of 	COMPLETED	2026-10-12 15:17:17.013805+05:30	2026-10-12 18:54:47.281479+05:30
37	37	NIPDS (Network Intrusion Prevention and Detection System) is a high-speed network monitoring engine designed to safeguard enterprise local area networks against malicious traffic. Utilizing raw socket packet capture and deep packet inspection (DPI), NIPDS detects signature patterns of SYN flood attacks, port scans, DNS poisoning, and unauthorized shellcode payloads. The system logs security events to a centralized SIEM dashboard and automatically updates local firewall tables to drop malicious source IPs.	Network Security & Threat Detection	{"Network Security & Threat Detection",Python,Scapy,"Snort Rules",Flask}	{Python,Scapy,"Snort Rules",Flask,SQLite}	NIPDS (Network Intrusion Prevention and Detection System) is a high-speed network monitoring engine designed to safeguard enterprise local area networks against malicious traffic. Utilizing raw socket packet capture and deep packet inspection (DPI), NIPDS detects signature patterns of SYN flood atta	COMPLETED	2026-10-12 15:17:27.927939+05:30	2026-10-12 18:54:47.43291+05:30
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, action, entity_type, entity_id, details, ip_address, "timestamp") FROM stdin;
1	\N	USER_REGISTER	USER	90	Student registered account: 25mx102@psgtech.ac.in [Roll: 25MX101]	\N	2026-10-12 19:17:19.358667+05:30
2	\N	USER_REGISTER	USER	91	Student registered account: 25mx102@psgtech.ac.in [Roll: 25MX101]	\N	2026-10-12 19:17:55.854268+05:30
3	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-12 22:33:47.426108+05:30
4	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-12 22:34:12.954195+05:30
5	19	ROSTER_STATUS_CHANGE	ROSTER	1	Toggled student roster eligibility for 25MX101 (BALAJI K) to DISCONTINUED	\N	2026-10-12 22:34:12.977145+05:30
6	19	ROSTER_STATUS_CHANGE	ROSTER	1	Toggled student roster eligibility for 25MX101 (BALAJI K) to ELIGIBLE	\N	2026-10-12 22:34:13.028845+05:30
7	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-12 22:35:51.759465+05:30
8	19	ROSTER_INGEST	ROSTER	\N	Bulk ingested student roster: 1 created, 0 updated, 0 errors	\N	2026-10-12 22:35:51.794928+05:30
9	19	ROSTER_DELETE	ROSTER	120	Removed roll number 25MX999 (TEST STUDENT BULK) from nominal roll whitelist	\N	2026-10-12 22:35:51.832066+05:30
10	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-12 22:45:11.714791+05:30
11	39	USER_LOGIN	USER	39	User successfully authenticated	\N	2026-10-12 22:48:02.739967+05:30
12	34	USER_LOGIN	USER	34	User successfully authenticated	\N	2026-10-13 08:18:03.821327+05:30
13	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-13 08:19:46.280813+05:30
14	34	USER_LOGIN	USER	34	User successfully authenticated	\N	2026-10-13 08:19:46.381053+05:30
15	71	USER_LOGIN	USER	71	User successfully authenticated	\N	2026-10-13 08:19:46.494416+05:30
16	89	USER_LOGIN	USER	89	User successfully authenticated	\N	2026-10-13 08:23:46.346215+05:30
17	210	USER_LOGIN	USER	210	User successfully authenticated	\N	2026-10-13 08:23:59.377208+05:30
18	210	OTP_REQUESTED	USER	210	Verification OTP generated and dispatched for: 25mx101@psgtech.ac.in (STUDENT)	\N	2026-10-13 08:23:59.49843+05:30
19	210	ACCOUNT_ACTIVATED_VIA_OTP	USER	210	Account successfully activated with private password: 25mx101@psgtech.ac.in (STUDENT)	\N	2026-10-13 08:23:59.736373+05:30
20	210	USER_LOGIN	USER	210	User successfully authenticated	\N	2026-10-13 08:23:59.833835+05:30
21	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-13 08:42:12.236096+05:30
22	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-13 08:43:36.276938+05:30
23	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-13 08:44:05.672896+05:30
24	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-13 08:58:43.596931+05:30
25	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-13 10:00:34.563412+05:30
26	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-13 10:06:34.882309+05:30
27	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-13 10:06:45.399883+05:30
28	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 18:09:21.666477+05:30
29	34	USER_LOGIN	USER	34	User successfully authenticated	\N	2026-10-23 18:09:21.903172+05:30
30	71	USER_LOGIN	USER	71	User successfully authenticated	\N	2026-10-23 18:09:22.015064+05:30
31	210	USER_LOGIN	USER	210	User successfully authenticated	\N	2026-10-23 18:10:07.640948+05:30
32	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-23 18:10:31.52394+05:30
33	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-23 18:42:38.559893+05:30
34	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-23 18:45:05.043113+05:30
35	92	ACCOUNT_ACTIVATED_VIA_OTP	USER	92	Account successfully activated with private password: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-23 18:46:06.956071+05:30
36	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-23 18:46:26.131836+05:30
37	210	USER_LOGIN	USER	210	User successfully authenticated	\N	2026-10-23 19:50:40.839258+05:30
38	210	USER_LOGIN	USER	210	User successfully authenticated	\N	2026-10-23 19:52:11.474307+05:30
39	210	PROJECT_CREATED	PROJECT	39	Created project draft: 'Edge-Assisted Autonomous Drone Fleet Coordination for Disaster Relief'	\N	2026-10-23 19:52:11.689907+05:30
40	210	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from DRAFT to SUBMITTED | Feedback: Submitting capstone draft for faculty guide review.	\N	2026-10-23 19:52:12.015768+05:30
41	39	USER_LOGIN	USER	39	User successfully authenticated	\N	2026-10-23 19:52:12.11499+05:30
42	39	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from SUBMITTED to UNDER_REVIEW | Feedback: Reviewing drone swarm architecture and simulation parameters.	\N	2026-10-23 19:52:12.152138+05:30
43	39	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from UNDER_REVIEW to REJECTED | Feedback: Please add hardware-in-the-loop (HIL) simulation test results and clarify battery fail-safe protocols before final approval.	\N	2026-10-23 19:52:12.190588+05:30
44	210	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from REJECTED to DRAFT | Feedback: Revised with HIL simulation details.	\N	2026-10-23 19:52:12.261076+05:30
45	210	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from DRAFT to SUBMITTED | Feedback: Re-submitting revised version.	\N	2026-10-23 19:52:12.324596+05:30
46	39	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from SUBMITTED to UNDER_REVIEW | Feedback: Re-evaluation.	\N	2026-10-23 19:52:12.372702+05:30
47	39	PROJECT_STATUS_TRANSITION	PROJECT	39	Status transitioned from UNDER_REVIEW to APPROVED | Feedback: Excellent revisions. Approved for public repository.	\N	2026-10-23 19:52:12.413806+05:30
48	92	OTP_REQUESTED	USER	92	Verification OTP generated and dispatched for: 25mx102@psgtech.ac.in (STUDENT)	\N	2026-10-23 19:56:24.375573+05:30
49	92	PASSWORD_CHANGED_WITH_OTP	USER	92	Password successfully updated via OTP for: 25mx102@psgtech.ac.in	\N	2026-10-23 19:56:52.541994+05:30
50	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:02:31.94743+05:30
51	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:27:54.624793+05:30
52	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:35:28.667073+05:30
53	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:35:57.236378+05:30
54	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:36:08.24856+05:30
55	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 20:51:36.389248+05:30
56	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-23 21:04:24.468713+05:30
57	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-23 21:44:31.588931+05:30
58	19	PROJECT_CREATED	PROJECT	40	Created project draft: 'Autonomous Edge IoT Gateway for Smart Agriculture'	\N	2026-10-23 21:44:31.792997+05:30
59	19	PROJECT_FILE_UPLOADED	PROJECT_FILE	77	Uploaded file 'Synopsis_Edge_IoT.pdf' (0 KB) for project #40	\N	2026-10-23 21:44:32.010853+05:30
60	19	PROJECT_DELETED	PROJECT	40	Project entry #40 was deleted	\N	2026-10-23 21:44:32.077218+05:30
61	92	USER_LOGIN	USER	92	User successfully authenticated	\N	2026-10-24 10:03:24.809962+05:30
62	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:04:25.377525+05:30
63	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:09:21.815321+05:30
64	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:10:17.17691+05:30
65	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:14:29.783448+05:30
66	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:15:19.785096+05:30
67	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-24 10:18:31.193715+05:30
68	19	USER_LOGIN	USER	19	User successfully authenticated	\N	2026-10-25 19:16:49.037286+05:30
69	19	ROSTER_SYNC_INGEST	ROSTER	\N	Bulk roster processed: 20 created, 0 updated, 0 deleted (syncMode=true), 0 errors	\N	2026-10-25 19:17:44.526779+05:30
70	19	ROSTER_PURGE_BATCH	ROSTER	\N	Purged nominal roll for batch '26MX': 0 deleted, 0 active accounts preserved	\N	2026-10-25 19:18:49.581098+05:30
71	19	ROSTER_PURGE_BATCH	ROSTER	\N	Purged nominal roll for batch '26MX': 20 deleted, 0 active accounts preserved	\N	2026-10-25 19:29:46.879661+05:30
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (id, name, code, description, created_at, updated_at) FROM stdin;
2	Computer Science & Engineering	CSE	Department of Computer Science and Engineering	2026-08-02 17:13:11.350956+05:30	2026-08-02 17:13:11.350956+05:30
3	Information Technology	IT	Department of Information Technology	2026-08-02 17:13:11.350956+05:30	2026-08-02 17:13:11.350956+05:30
7	Data Science & Artificial Intelligence	DSAI	Department of Data Science and AI	2026-08-02 17:52:59.004153+05:30	2026-08-02 17:52:59.004153+05:30
1	Master of Computer Applications	MCA	Master of Computer Applications Department	2026-08-02 17:13:11.350956+05:30	2026-08-02 17:13:11.350956+05:30
\.


--
-- Data for Name: keywords; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keywords (id, name, normalized_name) FROM stdin;
\.


--
-- Data for Name: project_embeddings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_embeddings (id, project_id, embedding_vector, model_version, created_at, updated_at) FROM stdin;
2	2	{-0.062705986,-0.037694864,-0.019534804,-0.025161939,0.12859543,0.0042076884,-0.02067724,0.047592178,-0.004054316,-0.07219447,-0.009593849,-0.10457909,-0.009838038,0.043497626,-0.053745627,0.005385793,-0.021499647,0.04218242,-0.08445666,0.03692294,0.05009,0.055890325,0.03191325,-0.028770398,-0.04981847,0.060152438,0.026667219,-0.030504707,-0.00090442755,-0.018398926,0.08325726,-0.109904885,0.069334775,0.07101469,-0.02275805,0.028178273,0.01084108,-0.017778322,-0.08209362,-0.02376394,-0.07864068,0.0015681734,0.0067488165,-0.041509688,0.0009200895,0.049722966,-0.02946937,-0.041128565,0.06657873,-0.06683495,-0.078477144,-0.012747052,0.043967415,0.07066201,-0.051824916,-0.04649361,0.005447531,-0.03579109,-0.008938316,-0.0031326648,0.036962993,-0.043203115,0.118097425,-0.015652576,0.008500983,0.07734298,0.003484504,-0.059511222,0.07616341,-0.07010758,-0.0619481,0.03744999,0.013740893,0.04726809,-0.10079801,-0.0019769662,0.08545899,-0.04119074,0.08494911,-0.019256417,0.044811524,-0.046098813,0.026070673,0.008557588,0.066171065,-0.040890798,-0.078265436,0.040077064,-0.038076613,0.049474396,-0.03555689,0.001124623,0.096369125,3.8229056e-05,0.012115357,-0.009858143,-0.06409765,-0.054819457,-0.03937266,0.04410925,-0.016693158,-0.062985264,-0.02739073,0.038053513,0.038734112,-0.076315984,0.029678175,-0.03645239,0.04697518,-0.007703164,-0.0130550405,0.01056437,0.0012098283,-0.082203194,0.037132215,0.026338471,-0.11738049,0.02780705,0.0046129026,0.03726277,0.03368477,-0.0649628,-0.07973245,-0.028979165,0.11857897,0.017066492,-0.055769917,2.1703925e-33,0.08000706,0.03280234,0.023897087,-0.028226286,0.03710498,0.0039427695,-0.05755229,0.01957846,-0.049046066,0.05254193,-0.06273187,0.031132989,-0.0069349366,0.07310798,-0.049642675,-0.0405041,-0.022668894,0.017848702,-0.00074847275,-0.025957435,-0.04615347,-0.08447764,0.019766519,0.09189039,-0.0013891004,0.034343954,0.08904708,0.034639902,0.10358035,-0.017393326,-0.11842676,0.0063225348,0.004475474,-0.080599375,0.07292555,-0.011828193,-0.08852659,0.015607594,-0.05401014,0.0040785633,-0.03081698,0.016880509,-0.052913193,-0.0315762,-0.014991452,-0.026466288,-0.020632142,0.0049948664,-0.0866727,-0.015477954,0.011424672,0.01359651,-0.010283613,-0.06004739,-0.09381487,0.04903862,0.018780783,0.0038314378,0.059251476,-0.03781826,-0.033509996,-0.0113158645,-0.008440224,0.0022051355,0.028171796,-0.0065522,0.09666585,0.058596194,0.08009959,0.05634811,-0.016207382,0.09057752,0.044406682,-0.07891165,-0.04003192,0.029423349,0.023966141,-0.051695257,-0.022217523,0.015783193,-0.007934116,-0.008034013,0.072969764,0.066254646,0.03939169,-0.02313049,-0.06744025,-0.019220363,-0.08913846,0.08697971,-0.0671143,0.016336191,0.013552841,0.056268033,-0.04471964,-1.43099705e-33,0.09539081,0.014622287,-0.116111465,-0.020674646,0.06259701,0.00545071,0.0086147385,0.020808578,0.0023448279,0.02192131,0.06627024,-0.09259304,0.00801682,0.021139218,0.033234034,0.042453237,-0.014953118,-0.021563774,-0.08065132,-0.008874204,8.761264e-06,0.07444899,-0.047928676,-0.0064321076,-0.06721072,-0.019918233,-0.03483889,0.0429299,0.008709216,-0.009256788,0.0032637639,-0.030705472,-0.0066062333,0.06723142,-0.02694463,0.06368039,0.03757635,-0.08312709,-0.04004308,0.0028838597,0.11312883,0.08453259,-0.07782876,0.037110105,-0.04347506,-0.038067028,-0.015082664,0.029753825,-0.09100587,0.0089640785,-0.03075428,-0.026035897,-0.05958734,0.03255101,0.028560622,0.013813685,-0.034780048,-0.0028453243,-0.07236637,-0.00192948,-0.026707314,-0.040448,-0.067034796,0.016494408,0.024555927,0.027064597,-0.025579397,-0.04383963,-0.052662186,-0.02252069,0.12066218,0.011966826,0.047661413,0.0601796,-0.00855405,-0.038763896,-0.04008178,0.014394491,-0.02299472,-0.01665504,0.06431267,-0.13162333,0.07322862,0.106587805,0.014584195,0.10365588,0.08694585,0.07898624,0.055950683,0.04840421,-0.116366774,0.12558606,-0.0024721867,0.007586707,0.021996934,-3.6131915e-08,-0.08841561,0.023088353,-0.03800137,-0.036649622,0.0077887466,0.0012982355,0.064857624,0.04548329,-0.024334809,-0.037971146,0.061511304,-0.010480959,-0.01350313,-0.0145388665,-0.023353158,0.025207907,0.013194924,0.059905123,0.024427231,0.041132122,0.047315206,-0.028195934,0.041527677,0.021793008,-0.00020406769,-0.051038966,-0.029560989,0.014488527,-0.06444362,0.015221424,-0.042967036,0.01528872,0.02188086,-0.06911921,0.023206249,0.12676388,0.037502795,-0.06526278,0.029844964,0.021616697,-0.0030524337,0.028364608,-0.011267018,-0.0061500235,0.0070065344,0.018840402,0.008710322,-0.07030041,0.07244938,0.03881286,-0.0037293558,-0.020635588,0.010369621,0.16250256,0.07595952,0.01959074,0.049346168,-0.03996385,0.0022759435,0.09639264,0.082407884,-0.0012633029,-0.0006288935,-0.028352348}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:14:56.127713+05:30	2026-10-12 18:54:45.360467+05:30
4	4	{-0.07988214,0.0020822468,0.0036145248,0.013747033,0.02640677,-0.118765466,-0.005176811,0.019989379,-0.08425927,0.026128441,-0.034833148,-0.062652305,0.060360335,-0.040196896,-0.009501911,0.041801944,0.024122823,0.0436439,-0.016054427,-0.05950994,-0.08227444,0.07553858,-0.07445035,0.02002381,-0.049245182,0.02325312,0.022740193,-0.05707349,-0.05290043,-0.027185926,0.050090604,0.017637713,0.030480148,0.035971455,0.12778449,0.06663522,-0.050500076,-0.007148477,-0.0050459127,-0.0005440678,-0.02084058,-0.014897505,-0.023358561,-0.06683962,0.015666232,-0.05490842,-0.055897385,-0.0142968055,0.04175545,-0.028913792,-0.045388892,-0.023281287,0.01092786,0.021255696,-0.027873332,0.042576212,0.08677211,0.016710294,-0.005288398,0.028041583,0.033224717,0.020538116,-0.015772093,-0.0108627975,0.025544723,-0.0051599904,0.012588339,0.014613756,0.040387258,-0.047936793,-0.06261077,0.04047177,-0.016437706,0.02746601,0.009292859,0.019509174,-0.061331768,0.033703834,0.042525485,-0.042008746,-0.044409633,-0.04336858,0.0017286595,0.08975246,-0.027285492,0.03518432,0.048690986,0.088789344,0.09039162,0.06811474,0.025625093,-0.028625546,0.13315144,0.011280627,0.05935352,0.04260612,0.023804134,-0.1052973,-0.06634841,0.07258125,-0.054309107,-0.0032847417,0.0018373417,-0.087464325,0.052208144,0.026314909,0.09057162,-0.03507144,0.084114954,-0.08524056,-0.042771433,-0.0289711,0.013296627,-0.0651344,0.058297038,0.022403209,-0.029314013,0.04668415,-0.012296613,-0.0359092,0.12838568,0.0011113517,-0.0113708,-0.0077739977,0.12818284,0.05753817,-0.040380467,5.1522237e-33,0.05033628,0.02654414,0.016064527,0.048563816,0.10130762,-0.056230623,0.017570779,0.0051779044,-0.017089805,-0.03952097,-0.010071949,0.01928625,-0.09530287,0.013521243,-0.035178814,0.0057566254,-0.1036504,0.064553805,-0.053044837,0.03461041,-0.006599572,-0.09661995,0.003292258,-0.062216498,0.06692272,0.021682851,0.024377292,-0.023166114,0.06388152,0.019214194,-0.01763277,0.012154761,-0.004155501,0.08510651,-0.035413466,-0.050545573,-0.09743058,-0.06639412,-0.035982314,0.08174365,-0.05505345,-0.008475737,0.014324575,-0.014787097,0.0890973,-0.06603099,-0.00028686624,-0.049284585,0.05282902,-0.00090856955,0.07061258,0.031423964,0.032548867,0.012011359,-0.03655443,-0.015931258,0.05491222,-0.051908966,0.026474416,0.04264977,-0.046487924,-0.011585452,-0.0067691775,0.019434337,0.013252402,-0.01640478,0.056049645,0.060893122,0.063632205,0.046041586,-0.02529843,0.0487329,0.009331308,0.0338075,-0.087324865,-0.047541134,0.040516697,-0.049694523,0.017154587,-0.08596362,-0.06270311,-0.0798814,0.028321797,-0.009065005,-0.0056532836,-0.010152216,-0.035596497,0.04328026,0.0027083114,0.00690711,-0.037556995,0.037034657,-0.026491052,0.037781425,0.008852674,-4.8908118e-33,-0.08621848,-0.05679597,-0.10865915,0.08830568,-0.010083462,-0.05294941,-0.0014566688,0.0117361285,0.054943755,-0.0108305905,-0.08827692,-0.007996155,-0.018264933,0.02404861,-0.016722016,-0.0041594976,-0.00233133,-0.09793743,0.029853355,0.019211255,0.043712545,0.065819465,0.009527532,-0.095674895,-0.04987921,-0.035988532,0.04028517,0.046708353,0.08275885,-0.0047146324,0.08790981,0.09354127,-0.070944734,0.01710873,0.054764956,0.0109969955,-0.0070339646,-0.040937092,-0.052853916,0.04488747,0.085037716,-0.039320476,-0.04571088,-0.03462351,0.0008087049,0.06711192,-0.021721479,0.0757479,-0.007896331,-0.062643915,-0.026505882,-0.030470511,0.0074717365,-0.018482156,-0.06752115,0.04408542,0.0528736,0.06452275,-0.058922175,0.036959123,-0.024050748,-0.03244508,0.07386874,0.015798852,-0.06626738,0.011574104,-0.011992321,0.06894106,-0.109066196,0.0037041854,0.13316724,-0.076064646,-0.07772692,0.014187557,0.025011087,0.0010658673,-0.073388994,-0.07414952,0.019428454,-0.045381974,-0.058035526,0.03900761,0.005076101,0.033656284,-0.05526495,0.056869432,-0.028932,0.09488384,0.06706217,0.02147918,-0.087965004,0.031245306,-0.026141591,0.004890093,-0.05624302,-3.9512535e-08,0.02381317,0.034095235,-0.021216637,0.02841744,0.04056985,-0.03665711,-0.03457353,0.08086142,-0.032766055,-0.037240993,-0.04390262,-0.028919838,-0.0625645,0.03540212,0.013257573,0.0668298,-0.051520932,0.08329134,-0.030672839,-0.114260614,0.05082963,0.029950617,0.074344166,-0.009973413,-0.07400058,-0.041266125,0.08356855,0.11194869,-0.0065001934,-0.01950405,0.07751145,0.016263772,0.0017656768,-0.04702811,0.06365103,0.106726885,-0.017332694,-0.05391999,0.06393563,-0.014025176,-0.07189742,-0.014289595,0.04913894,-0.07664867,-0.016690515,-0.050784342,0.0048563858,-0.062103637,0.061236102,-0.069698274,-0.01191952,-0.029263668,-0.078154616,0.052412227,0.09027064,0.053307086,-0.00075408287,-0.060817264,0.06850204,0.029591575,0.0032261785,0.043504566,0.051152695,0.0016060299}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:27.033021+05:30	2026-10-12 18:54:45.477993+05:30
6	6	{-0.13388883,0.06324316,-0.055549733,-0.048352756,-0.0172013,-0.034693286,0.0012536612,-0.055570226,0.036990978,-0.054522425,0.02592313,0.016107047,0.059110515,-0.00013135675,-0.008782501,-0.03031229,-0.014947926,0.0019602524,-0.031325825,-0.03973836,-0.060294904,0.093649335,0.0049259826,-0.0361451,-0.12838268,0.008528054,-0.002690441,-0.05052166,-0.057942547,-0.033209037,0.0888961,0.037950724,0.08096368,0.06192204,0.03166549,0.0051894127,-0.015236915,-0.0062938845,0.034468897,-0.033587113,0.012548053,-0.15515439,-0.017887592,-0.022210004,0.09841121,0.024323044,-0.04969718,0.036146026,0.037673876,0.00059875014,-0.10656356,-0.00048353165,-0.0053980164,0.057647042,-0.024449723,-0.013886704,-0.005227054,-0.069098756,-0.04107397,-0.04737743,-0.03604904,0.0015666472,-0.012003325,0.024814673,-0.060795937,0.06975845,-0.01661144,-0.028363543,0.07103085,-0.04040941,-0.060742576,0.032200012,-0.06985861,0.0762504,0.0049322103,0.03434901,-0.09760523,0.0028638353,0.021190837,-0.05283779,-0.00748215,-0.036285326,0.07322404,0.08304379,0.0002709344,-0.008543649,0.051513065,-0.0085996585,0.029228669,0.014761666,0.052247405,-0.017914144,0.13206932,0.002455987,-0.080526,-0.0793874,-0.044525042,-0.042884808,-0.012887364,0.05358586,-0.0039092703,0.039075665,-0.023209237,-0.0730293,-0.0753214,-0.05987029,0.05916649,-0.080910064,0.047552593,0.05027883,0.014900239,-0.027108002,-0.077712886,-0.14201772,0.011591655,0.035040285,-0.040695705,0.049415026,0.048176948,-0.005083438,0.01753382,-0.004068503,-0.04075401,-0.007873687,0.057648923,-0.050783645,-0.093704484,4.2968282e-33,-0.014433541,0.06162759,-0.008606914,0.019460522,-0.04183395,-0.0013877902,-0.08944905,-0.054463405,-0.02404093,0.011498906,-0.003742016,0.1367287,-0.0038139415,0.060677852,0.04996759,0.032129057,-0.0009745135,0.068051234,0.06614862,0.010822053,0.082198754,-0.026269726,0.087122366,-0.022289101,0.065741405,0.027557222,-0.007616554,-0.08937801,0.037843782,0.0047645457,-0.01375701,-0.07531868,0.077849545,0.04874629,0.049608704,0.033031937,-0.0025717588,-0.079924904,0.014627342,0.03901259,-0.092505075,0.01615142,0.047052357,0.015640395,-0.030241305,0.022920009,-0.010048919,0.0010263316,0.05495626,0.058842998,0.03315961,0.02726347,-0.012068199,-0.021887237,-0.07027311,-0.036521792,0.013778591,-0.016160332,0.025080748,-0.020647567,0.014861871,0.063288756,0.017805941,0.003635814,-0.01168715,-0.013809965,0.040287193,0.014044096,0.035189066,0.058832992,0.0037831245,0.050519973,0.050410707,0.033251196,0.024339298,-0.06408288,0.03815465,0.036109272,-0.012917265,0.0010966398,-0.025824198,-0.011891042,0.041719783,0.02338623,-0.10284236,-0.010934051,0.0739631,0.07752407,-0.04980549,-0.04620172,0.062044047,-0.031315982,-0.03206376,0.06823413,0.011173672,-4.6633352e-33,-0.02325558,-0.09198777,-0.039250527,-0.048282847,-0.012365204,-0.06306,0.013823902,0.05277326,0.06376489,-0.0035247826,-0.033659447,-0.056053318,0.06594141,-0.007980266,0.023849212,0.06551035,-0.02150075,0.01079312,-0.09439693,0.05025897,-0.06678604,0.055818107,-0.036366872,0.082212396,-0.0043169074,0.029943611,-0.0036584416,-0.05567101,0.052850917,-0.044731334,-0.08652995,0.031083982,-0.0861555,0.01588181,-0.042724457,-0.04757072,0.037893206,0.07106715,0.006528756,-0.06756479,0.043540746,0.10009363,-0.116471335,0.019440683,0.0046365676,-0.026388243,-0.07936358,0.09534734,-0.013106592,-0.003229584,-0.030935086,0.00044812457,0.0574339,-0.06888975,-0.008154956,0.043887746,0.027068598,-0.010716412,-0.082764186,0.041186724,-0.04043143,0.0049791345,-0.009588353,0.086091556,0.027670162,0.02882899,0.0031410896,-0.049485363,-0.07446034,-0.058110934,0.10268413,-0.0654136,-0.04912513,-0.031697754,0.018531442,-0.043736394,-0.0034088348,-0.0066551203,-0.091791734,0.14185733,0.08417208,-0.050458517,-0.04674128,0.043265335,0.048857052,-0.019346429,0.00452711,-0.039876092,0.026594464,0.005528903,-0.022012474,0.027383853,-0.052157197,0.056490682,-0.061372366,-3.872706e-08,0.04933697,-0.04413038,-0.037267055,0.007977375,-0.0080152685,0.024922721,-0.02599723,-0.01119763,-0.080202065,-0.08519508,0.11757195,-0.076358795,-0.06544751,-0.06947552,0.057672903,0.092391424,0.0027216421,-0.0016298001,-0.008948229,0.013632248,0.015276001,0.020320538,-0.014053127,0.002745977,-0.00059032365,0.031138906,0.015879696,-0.0035508052,0.003017466,-0.0107423505,0.039429516,-0.0122514,0.03007687,0.022888232,0.014504665,0.068956725,0.0799374,-0.04483038,0.009214237,0.07361687,0.004643626,-0.01100235,-0.07402188,-0.0027608976,0.005693697,-0.011260735,-0.021700177,-0.1313726,0.10963629,-0.046325117,0.011299711,-0.0040509584,0.0770342,0.06495347,-0.009698684,0.04962165,0.050592087,-0.0063693128,0.059551463,0.06863853,0.09754444,-0.027968086,0.079618216,0.06353498}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:35.336328+05:30	2026-10-12 18:54:45.588168+05:30
8	8	{-0.026976218,-0.04267173,-0.06515018,0.0068412083,0.10897072,-0.103281446,0.03221586,-0.04944966,-0.04302286,0.039886676,0.013104795,0.029437581,0.111612335,0.032609496,-0.024397446,0.06431634,-0.02977534,0.003935672,0.0647565,-0.055526003,-0.038781866,-0.091342814,-0.05511099,0.020259859,0.03636532,-0.03527421,-0.024299726,0.015319,-0.04831395,-0.033358674,0.013526876,-0.034518607,0.015842192,0.009147317,-0.04278667,0.0026233098,0.055519734,0.04257232,0.01188753,0.016319958,0.039128374,-0.0042030253,0.04283753,-0.0063570184,-0.068767235,0.010843787,-0.11467051,0.033176202,-0.006099535,-0.0062174867,-0.06527989,-0.05412977,-0.011049993,-0.0066262307,-0.044718713,-0.024764232,0.041761603,-0.055942766,0.014277762,0.0048777643,0.07129139,0.028408932,0.048304163,-0.010351681,0.04266717,0.023408651,0.0056957365,0.08697923,0.051389363,0.017492615,0.0022114038,0.03410172,-0.07839233,-0.00079715886,0.018452263,0.026063465,-0.039586052,-0.026814045,0.0065357382,-0.06347624,-0.045951717,0.04159904,0.007690862,0.046502672,-0.041604362,0.028077794,-0.007356162,-0.03208209,0.03678574,0.07571271,-0.061567985,0.13235807,0.023311099,0.018367816,-0.0014446694,0.045194313,-0.007673159,-0.03904166,0.0035428056,0.048212893,6.195166e-05,-0.06493862,0.06692131,-0.0926453,0.12638277,0.021111023,0.02170042,-0.05089463,0.045150667,0.045331784,-0.071016304,0.06583864,0.02541882,0.0036967397,0.028071987,0.06234021,-0.029563474,0.03129663,0.010881766,0.04178858,0.09033783,0.07526182,0.064869314,-0.08595422,0.09093651,0.017572988,-0.026145827,2.366841e-33,0.007924559,0.014845344,-0.021465598,0.029038966,0.06637643,0.0034482211,-0.07335491,-0.054836176,-0.09331802,0.0016608649,-0.11424237,0.062361367,0.08135966,0.04476695,0.018988505,-0.058614448,0.068395235,0.020467687,0.022997707,-0.059025694,0.03919018,-0.07421238,0.014108284,0.06951295,0.059263356,-0.0032099797,-0.013628663,0.077640004,0.09588408,0.01615627,-0.01953516,0.019900506,-0.0048720534,-0.008686488,0.03792176,-0.008228769,0.01657547,-0.120482445,-0.000531868,-0.074928194,-0.0005258525,-0.04281324,0.027750496,-0.009936676,-0.066664346,0.06877851,-0.074827634,0.0022611115,0.022023465,-0.03626951,-0.034301247,-0.04918425,0.013690414,0.057692718,-0.055225544,-0.026003307,-0.0044942694,0.04833463,0.012779937,0.013216408,0.011246556,0.004126573,-0.051587217,-0.06100946,-0.034240637,0.0013796892,0.007710954,0.019991588,0.0005946488,0.046148278,-0.039351754,0.123097256,-0.04560422,0.053128768,-0.0665662,-0.08059759,-0.05457366,0.00899957,-0.05266141,0.0070858435,-0.077795066,-0.12135994,-0.007582282,0.0022259268,-0.041246317,-0.06973975,0.0344257,0.009636725,-0.051285896,-0.049539458,-0.0055429037,-0.04401398,0.07062044,0.08105488,-0.043655846,-2.7381256e-33,-0.09966373,0.054955713,0.12939708,0.036757346,0.02473657,-0.030407684,-0.010882301,0.033730153,-0.021357788,0.05935685,-0.033294015,-0.05392966,0.07587218,-0.02980067,0.03285728,0.01119071,0.015376845,-0.017958894,-0.099713355,-0.04082201,-0.0388432,0.040054776,-0.07124754,-0.04412628,0.08321939,0.038174678,-0.0039547025,-0.043655105,0.01419056,0.047744546,0.0031601451,0.039387155,-0.014264428,-0.037670594,0.020399807,0.018851262,0.028910017,-0.060272798,0.029293701,-0.069649495,0.001556984,0.019106438,-0.059117313,-0.035825875,-0.023264648,0.12677693,0.02666073,0.09537865,-0.0448496,-0.008506875,0.007789874,0.03756924,0.08459122,0.0153661035,-0.020258732,0.029682783,-0.007960274,0.10388248,0.028099265,-0.02963749,-0.056010596,-0.06863725,-0.07339596,0.061633825,-0.039303888,0.016793227,-0.00042310462,0.01922392,-0.022610607,0.047975224,0.12614128,0.047263965,-0.08007018,-0.05556513,0.00824096,-0.016629389,0.020719739,0.05018521,-0.064543955,0.039836444,0.1041043,0.005611582,0.039719213,-0.024079185,0.07664107,0.0043393457,0.035133548,0.07855853,0.04183685,0.054059356,-0.049967118,-0.027941452,-0.078302674,0.018212168,0.03641261,-3.2327332e-08,-0.001506339,-0.007615988,-0.009418934,0.007176,0.048719727,0.12637946,0.014668283,0.0040800846,-0.10548345,0.087542154,-0.007250308,-0.048982944,-0.05846107,-0.07754426,0.022169685,0.0046680165,-0.028444221,0.022200948,-0.0053736414,-0.03795495,-0.051328525,-0.035211526,-0.09670986,0.0889514,-0.03269787,-0.04002993,-0.029744696,-0.0041545876,-0.013332976,-0.014606257,-0.04412075,-0.022909682,0.008393965,0.008604619,-0.0829328,0.17901158,-0.07961411,-0.018659001,0.05705806,0.06630893,-0.001621273,0.03274893,0.020580335,-0.033997707,-0.069304205,0.011837581,-0.06488642,-0.029237747,0.06555451,-0.06556275,-0.018908236,-0.078034334,-0.040245745,0.032236475,0.010499981,0.051115133,-0.08508923,-0.05344604,0.051786356,0.062649176,0.0028289487,-0.07218472,0.04274585,-0.042779047}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:43.656237+05:30	2026-10-12 18:54:45.699016+05:30
10	10	{-0.050580103,0.0078053325,-0.07092217,-0.026759807,0.009243678,-0.08306449,0.053905062,0.023362828,0.03677325,-0.0056590945,-0.009016928,-0.034874015,0.04933858,0.008891217,-0.071932204,0.007214402,0.03744728,-0.0456558,0.012713494,0.002440637,-0.06869159,-0.0019791834,-0.02816765,0.014285784,-0.063521996,-0.04637257,-0.029905822,-0.03481075,-0.10168452,-0.07485095,0.053156063,-0.027664889,-0.06978464,0.017206268,-0.019985039,0.0029809643,0.075498864,-0.029388746,-0.07690315,-0.042292193,0.02122074,-0.02720322,-0.04351009,0.059615057,-0.01900815,0.012450806,-0.019682666,-0.085967824,-0.007873692,-0.043682985,-0.032425594,-0.034457613,-0.028649477,0.058165614,-0.04972404,0.0055020144,0.0066831573,-0.020412324,-0.015804324,0.029133337,0.040040936,0.004182133,0.036436904,0.015610168,0.01711438,0.08634969,-0.0055138054,0.004740349,0.08345849,-0.09636655,-0.076892845,-0.0079584215,-0.03190932,0.004377203,-0.052521456,0.036727287,-0.03911466,-0.07960773,0.098782815,-0.07716435,-0.023059668,-0.014985044,0.01830244,0.067356706,-0.0040417095,0.017629456,0.04112779,0.02018878,0.052010484,0.028993376,0.052152272,0.059094,0.008260771,0.018414333,0.017455919,0.006145219,-0.021246877,-0.06664685,-0.090799905,0.031199528,0.019533183,-0.053907536,0.008079138,0.0011127375,0.07516278,0.04987854,0.03932792,-0.08248212,0.0407155,-0.0036118268,-0.054271344,0.00034283366,0.007251213,-0.06293243,0.03545877,0.08447925,-0.038904034,0.05984466,0.035033196,0.024347717,0.056234926,-0.035651397,0.04547843,-0.009661271,0.03544632,0.04253112,0.040612962,5.4732417e-33,-0.0034338848,0.06062606,0.0360899,-0.022331545,-0.0023444472,-0.006453016,0.016495636,0.064746805,-0.11436934,-0.042743098,-0.06449084,0.10120338,-0.013165411,0.0036654952,0.12076219,-0.04987126,-0.015504073,0.0946442,0.08959868,-0.0490214,0.009978404,-0.07020797,0.018786099,-0.002275354,0.10857608,-0.014927355,0.0088547245,0.05479513,0.059714343,0.015186373,-0.06397349,0.0018510598,0.04535617,-0.023209682,0.042306848,0.024245588,-0.053746663,-0.027569452,0.019807225,-0.10206225,-0.0003136789,-0.05149652,-0.0078067994,-0.0070654945,-0.046295818,-0.06332866,-0.07573087,-0.003988722,0.028905742,-0.035363466,-0.059231784,0.008103122,0.028140454,-0.0009798914,-0.12630327,-0.007403318,0.056407355,-0.007582182,-0.022390608,-0.010182496,0.014986067,0.046056677,-0.08756667,-0.10143341,0.02631161,0.015352801,0.038686745,-0.024100767,0.006313652,0.06774317,-0.08589091,0.0591525,0.05001142,-0.020721698,-0.056515962,0.00036601894,-0.040037252,0.03960351,0.0037294207,0.0021991506,-0.040988397,-0.025160866,0.010190345,0.044238042,0.044851184,-0.105634004,-0.063948065,3.7184553e-05,-0.11711129,0.0825364,0.015160909,0.014560581,0.07310661,0.12711856,-0.10119641,-4.8211123e-33,-0.076036595,-0.054143507,-0.022275709,0.124249086,0.029808419,-0.037702918,-0.0491838,0.015845168,0.027712435,0.08771809,0.00919486,-0.07126543,0.10311608,-0.043873284,0.07654575,-0.036155723,-0.0017263923,-0.03344171,-0.050340828,-0.024437603,0.08235956,0.076577336,-0.08305572,0.02200233,0.03501025,0.06264422,-0.042073637,-0.029928945,-0.0049227607,0.013582498,0.03700074,0.04474543,0.048414797,0.007901933,0.014374673,-0.03057846,0.07318486,0.010874806,0.108090214,-0.05173904,0.1231242,0.02971169,-0.038430285,-0.01771298,-0.0013669585,-0.017231371,-0.06652936,0.06081441,-0.07992794,-0.06223047,0.01020722,0.0052647972,-0.02487096,0.034475796,-0.0026773664,0.054469325,-0.009135751,0.017928496,-0.038993984,-0.00023668598,0.04737054,-0.037213057,-0.024949113,0.037692215,0.011664626,0.045313507,-0.0323439,0.046813738,-0.067776926,-0.009054922,0.14115846,0.01878103,-0.07178912,-0.056523874,-0.015855288,-0.016369645,-0.030918514,-0.101676196,-0.031113194,0.030176682,0.030608794,-0.003741595,0.047214136,-0.00081308594,0.057855397,0.031732146,0.04659869,0.021834794,0.021190338,0.041410457,-0.076930836,-0.010567994,-0.04993042,0.019468559,-0.03949559,-4.0640142e-08,0.020127693,-0.0077594323,0.036768254,0.04676624,0.016177611,0.0063745473,-0.010279033,-0.02910644,-0.04936901,0.058944326,0.02813492,-0.13741522,-0.11817291,-0.024597863,0.049972437,0.06790594,-0.043256562,0.041412696,-0.026119351,-0.027222153,0.017771319,0.020605773,-0.077018365,-0.002821026,-0.003126669,0.009548371,0.09648584,0.10316871,0.066497296,-0.019640349,-0.026661146,-0.03232253,0.011022383,0.009740539,-0.07044886,0.17930098,0.025610078,0.0033805182,0.003986523,0.0835034,-0.043561805,0.033737723,-0.03304558,0.015332126,-0.05626662,-0.016147114,-0.032538358,0.0036331627,0.008994125,-0.046340957,0.05444423,-0.06483502,-0.03926435,0.10282339,-0.031374533,0.033277206,0.03519883,-0.0524909,0.03748094,0.10385226,0.09548864,-0.07399106,0.035450276,0.05064305}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:44.640967+05:30	2026-10-12 18:54:45.865126+05:30
12	12	{-0.10889657,0.014734605,-0.0777299,-0.031264286,0.06918339,-0.0744074,-0.013517295,-0.06550137,0.020309696,0.04268892,0.05984938,0.022861194,-1.9797633e-05,-0.034652386,-0.1265906,0.0509192,-0.021947427,0.008119285,0.0051690093,-0.058759455,-0.01767072,0.07044923,0.08069255,0.019192005,-0.008107617,0.046110414,-0.02956408,0.0023666935,-0.018404685,-0.06555888,0.0025665227,0.053117245,0.038679074,0.052991867,-0.013869498,0.058799136,0.00018232496,0.049364872,0.013854935,-0.021119801,-0.11252455,-0.056710266,0.011404361,-0.0029041271,-0.051938895,-0.035319194,-0.089663565,-0.025792096,0.06131774,0.05502846,-0.090895444,-0.028267218,0.03187306,-0.019638104,-0.016367441,0.006465474,0.0015019114,0.020769771,-0.062596776,-0.059216827,0.001990389,0.062119078,-0.025981443,0.04415368,0.032429215,0.064318255,-0.051635716,0.028590871,0.0221975,-0.0075005447,-0.062292222,0.016625438,0.013332606,0.10817431,-0.03324918,0.08561239,-0.0055667087,0.026821502,0.068171345,-0.041528393,-0.021630859,-0.010311354,0.05596781,0.08041409,-0.04082431,-0.034901775,0.051469833,0.0025012868,0.07288459,4.0826424e-05,0.05886351,-0.045175184,0.17419042,-0.0837222,0.02514553,-0.020009585,-0.057588607,-0.042108506,0.04473407,0.04306426,-0.02877165,0.009403385,-0.0057956357,-0.085032515,-0.0129826395,0.03127245,0.061679937,-0.0033149382,0.059500292,0.00044747908,0.039824396,0.029551685,0.0033366885,-0.025778597,0.08267094,-0.009990748,0.024150243,0.03143003,0.0075425827,0.034488704,-0.010518468,-0.004039954,0.00579495,-0.07696517,0.008399488,-0.0848445,-0.0029679267,2.3680422e-33,0.008513971,0.09232433,-0.000864339,-0.038730484,-0.052813884,-0.04275154,-0.014264201,0.038347933,-0.11127604,-0.05933814,-0.021820586,0.13421166,-0.03930003,0.049138125,-0.013119621,-0.016273797,-0.04095079,0.11800535,0.011901316,-0.027241686,0.047695294,-0.13262473,0.090709925,-0.05970504,0.015414712,-0.06664949,-0.04142112,0.008579245,-0.026601607,0.0039661853,-0.037855398,-0.04677518,-0.01758336,-0.013626464,-0.009299973,0.0075522615,0.0043299603,-0.053578995,0.0055317967,-0.012644361,-0.014517861,-0.027747784,0.03162592,0.05441112,0.037117694,0.028485931,-0.044227734,0.022586089,0.13477331,0.008085579,0.057894446,-0.009768358,0.025238523,0.023058465,-0.0561807,0.04601089,0.021889476,-0.0038787983,0.030515734,-0.0036756247,0.05142766,0.09664462,-0.085800685,-0.0315497,0.0060869716,0.023804694,-0.043746416,0.047967795,0.13004002,0.057780955,-0.004150655,-0.03210781,-0.0037621518,0.06866159,-0.005397594,-0.026712772,-0.031877868,0.028675722,0.02168173,0.01842436,-0.06874859,-0.032128945,-0.030342918,-0.11511096,-0.0757078,-0.04185196,0.0025572118,0.028186824,0.02045454,0.00674365,0.068699494,-0.024781942,-0.06197276,0.0380052,0.006163672,-2.8464699e-33,-0.015532881,-0.11050891,0.0624389,0.08652407,0.009456782,-0.031110462,-0.07862766,0.009332669,0.041372035,-0.022421567,-0.024624221,-0.12672487,0.056315668,-0.065863624,0.06334583,-0.017179266,-0.03401997,-0.00043466443,-0.09318079,0.06854575,0.07680431,0.07669861,0.0073279995,0.036208127,-0.037441626,-0.0126154255,0.0012511268,-0.1033858,0.039564695,0.01444061,0.04340332,0.11590771,-0.08164714,0.0067043095,-0.010451254,-0.04132777,0.042809524,0.034046087,-0.0010527838,-0.012535671,0.048524134,0.095218815,-0.04317674,-0.035820175,-0.028725095,0.0031787625,-0.08268084,0.08454927,-0.012285812,-0.06528762,-0.020421557,-0.019307679,0.006959039,-0.034558665,0.05614437,0.033906743,-0.030747062,0.022026563,-0.029028654,0.08131566,-0.04283747,-0.059583336,-0.05742751,0.04356038,0.044384766,-0.055424258,0.015689932,0.103201434,-0.05790618,0.053735003,0.0792868,-0.09176028,0.021338258,-0.0025403404,-0.0054585426,0.006682279,0.05940478,-0.040157065,-0.0264685,0.024921866,0.03866435,-0.02340662,0.061356273,0.044883747,-0.0059092506,-0.0063147414,0.031616792,-0.0053122845,0.011859033,0.026997717,-0.019113686,-0.09784042,-0.019107234,-0.041677263,0.028687175,-3.7455745e-08,0.04586307,0.042439137,-0.06787888,0.09664786,-0.010609806,-0.06977416,-0.05849158,-0.020513417,-0.06889619,-0.060852353,0.032994766,-0.016518973,-0.08440196,-0.034142863,0.0031415324,-0.005263196,-0.009985001,0.093282565,-0.009893855,0.0053551095,0.037795275,-0.033621345,-0.004880134,0.053096734,0.016736208,0.032360688,-0.0009132503,0.04036349,0.035316955,-0.0008135353,0.028901063,0.045565497,-0.037657507,-0.077591345,0.058633372,0.07018613,0.042824917,-0.021135135,-0.018856082,0.056108657,-0.017886577,-0.05015726,-0.05032548,-0.033803817,-0.036179837,0.016627453,-0.031038346,-0.0018494243,0.028717944,-0.05430031,0.053966384,-0.07704887,-0.00050053344,0.0010104962,-0.014157973,0.01508923,-0.018894812,0.023003405,0.060332857,-0.074036546,0.18639866,-0.027735516,0.1438335,0.01488123}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:28.996158+05:30	2026-10-12 18:54:46.007127+05:30
14	14	{-0.08465332,0.07566299,0.0025809866,-0.063653074,0.018576453,-0.11868392,0.0070135356,0.102515444,0.036923483,0.016337877,-0.06825401,0.094772816,0.008429966,0.017106587,0.01106343,-0.021727623,0.03800549,-0.030555626,-0.014365934,0.015473129,-0.052247867,0.046764553,0.014833577,-0.004044275,-0.06077111,0.0052839215,-0.005787095,-0.03287297,-0.04011724,-0.05397058,0.093569875,-0.0084217265,-0.011284227,0.09928724,-0.1394378,0.010981957,0.050045118,-0.01883774,-0.0977258,0.019031912,0.04483371,-0.048042994,-0.026131233,0.039125927,0.012737736,0.03369799,-0.12474032,0.01398672,-0.004952756,0.016314235,0.0012866253,-0.097672306,0.016404446,0.13302933,-0.012393203,0.0061921705,0.04671132,-0.068103604,-0.073887534,-0.011880735,0.0044543534,0.022463525,0.034496576,0.06091126,0.027462512,0.011684716,0.071788706,0.04389319,0.034948718,-0.09583631,-0.028491404,-0.025095832,-0.052009754,0.09773463,-0.025550643,-0.0148748355,-0.07018629,-0.06705589,0.03418235,-0.070906036,0.03720212,0.037926078,0.040851876,0.028183138,-0.08499687,-0.0023151971,0.012910456,-0.030436793,-0.031292148,-0.049104627,-0.0067281593,0.07436259,-0.024494503,-0.023431238,-0.04058876,-0.0030780905,0.01958716,-0.035632364,-0.043730885,0.035357255,-0.029867288,0.030537046,-0.034232114,-0.031032166,-0.039826702,-0.032054655,0.03559362,-0.053810723,0.030182468,0.04637083,-0.017574493,0.045476228,-0.02648692,-0.0068763057,-0.03101483,0.008945199,-0.072688594,0.010970204,0.0398602,-0.017757794,0.010271238,-0.0179659,-0.015421616,-0.027995083,0.04256978,-0.041318636,0.016498832,5.980639e-33,-0.035111,0.0029710603,0.03505879,0.0016006578,0.055469822,0.05537852,-0.0055408725,-0.024248455,-0.122289784,0.0066390033,-0.06385658,0.06369162,0.07877787,-0.012008849,0.059293527,-0.06333133,-0.02240323,0.048620906,0.085298285,0.07870757,0.06620787,0.008601045,0.017214565,0.08059671,0.026308648,-0.01478712,-0.042542964,0.010152433,0.19019812,-0.03209206,-0.08828303,0.0203338,0.096402265,0.028566135,0.011009885,0.050138555,-0.014567632,-0.07766567,-0.043306544,-0.030878622,0.031005636,-0.018707456,-0.013684569,-0.03412424,-0.092090644,-0.0031935165,-0.049098708,-0.05257405,-0.0031876625,0.039014444,-0.030854458,-0.0011855415,-0.06914933,-0.07084898,-0.011084247,0.011814373,-0.057627883,-0.034404553,-0.005171011,0.060061574,0.04120324,0.04574887,-0.0059481086,-0.08296926,-0.0077210227,-0.03734636,-0.0037494577,-0.12603134,0.092504285,-0.023482967,-0.04962574,0.04144494,0.07726008,0.042635202,-0.0038094518,-0.017853392,-0.058476087,0.011702681,0.014800299,-0.044319376,-0.038495515,-0.0116360355,-0.00046428505,0.11727251,0.021952003,0.002294777,-0.06811519,0.049497373,-0.10049498,-0.01979466,-0.023945684,-0.01423088,0.10006233,0.030403145,0.022225307,-7.0670544e-33,-0.050371833,-0.029156778,-0.0759169,0.08347996,0.15374658,0.0067334766,-0.016821042,0.028510626,0.03802366,0.0048019737,0.013850137,-0.052851543,0.05347849,-0.054466583,-0.009407036,-0.027664261,-0.104747534,-0.123363785,-0.07786683,0.03614388,-0.017897433,0.08002262,0.022611551,0.12136134,0.06864467,0.04931646,-0.041250896,-0.011012665,0.033146333,-0.082407,-0.03428268,-0.0035979582,-0.027733577,-0.035270736,-0.05376025,-0.05598375,0.012872578,0.062099315,-0.005784052,-0.02305657,0.010271379,0.018265605,-0.035187997,0.016386542,-0.01955754,0.029990796,-0.077534124,0.057066467,0.06641908,-0.016271478,-0.0428791,-0.015983501,0.052615717,-0.03861191,0.0025930647,-0.002472978,0.007677161,0.003865551,0.021945933,0.03583489,0.0686505,-0.015471004,-0.011653156,0.15275066,-0.010312296,-0.023043424,-0.042870753,0.016084034,-0.030772517,0.024913013,0.04109142,-0.023101883,-0.025410853,-0.04578906,0.14481732,-0.1014847,0.0026014226,-0.076245345,-0.05721779,0.048866548,0.030142993,0.0040883627,-0.02467259,0.0512848,0.041802026,-0.064942636,0.039223403,-0.06466483,-0.024491878,0.014616397,-0.069631904,-0.006535025,-0.089840546,0.010903852,0.01563056,-4.6677144e-08,0.013280071,-0.055760715,0.024444275,-0.002249513,0.003414144,-0.09935003,0.055862237,0.084935084,-0.0037437566,0.046276648,0.06844811,0.0028923703,-0.071276486,-0.07998906,0.06329169,0.05541636,0.0002922408,0.078195795,-0.032554112,-0.007584992,-0.0034759662,-0.05574247,-0.09111966,-0.015888281,0.06690287,0.047514684,0.069293275,0.04123018,-0.020001048,0.018194346,-0.042237952,-0.0173184,0.05743478,0.060376253,-0.016781183,0.0057119685,-0.004257164,0.014593799,0.030659724,-0.042154577,0.014650558,0.023755264,0.013707025,0.033657804,-0.0060811737,-0.032293096,0.0155659085,0.0464276,0.03608205,-0.09556448,-0.03605056,-0.041392494,0.06654789,0.0070809536,0.023944847,0.08318628,0.010990717,0.0027834112,0.01469704,0.01660209,0.084706776,-0.02386022,0.064000845,0.02701604}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:34.433991+05:30	2026-10-12 18:54:46.147464+05:30
16	16	{0.014505723,0.026909921,-0.05728111,-0.026238194,-0.016892511,-0.032507185,-0.05098723,0.029445933,-0.006833752,0.018273085,0.01667854,-0.0051314374,0.0686604,0.0077440436,-0.0052927826,0.014895465,-0.022787832,-0.021710942,0.04985616,-0.07168721,0.03116735,0.075853325,-0.003527929,-0.015344855,0.009017672,-0.022606872,0.019596845,-0.007145618,-0.088892415,-0.07057592,-0.022286927,-0.04261855,0.04788937,0.044395152,-0.028443068,0.025742201,-0.00050122023,0.001219255,-0.06326763,-0.07758957,-0.06142472,-0.048303206,0.04449141,0.023255691,0.06338349,-0.06820591,-0.13307378,-0.10459158,-0.009899005,0.10720408,-0.0815858,-0.050663248,0.025491267,-0.066519834,-0.041389428,0.12915587,0.011366808,-0.0484181,-0.02479414,-0.07342828,-0.060853228,-0.010160491,-0.015627803,0.08645503,0.028691119,0.03497209,-0.04806068,-0.004000582,0.031175168,-0.006749642,-0.027056161,-0.027368307,-0.016311731,0.020261217,0.07847945,0.057101384,-0.093689,0.010691724,0.079059914,0.0038938525,-0.040092923,0.049975373,-0.009533425,0.05821603,0.029228393,0.00876504,0.04178281,-0.01929115,0.04830197,0.03942682,0.0057083326,-0.069277816,0.07675479,0.052769057,-0.011236316,-0.060101524,-0.027041052,-0.1313246,0.01836323,0.008847579,-0.059186045,0.05863674,-0.06293959,-0.10814945,-0.09442617,-0.075219885,0.07479413,0.02002638,0.06752948,-0.02983561,0.0035139464,-0.022631591,0.060758267,-0.039977755,-0.023074342,0.09577272,0.054059397,0.01511108,0.09442216,0.045469068,-0.048826434,0.015528917,-0.01281587,-0.09995395,0.020803638,-0.06248717,-0.07428676,1.9069444e-33,0.036273398,0.015332638,0.044700835,0.03601676,0.02678581,-0.09103011,0.0125741325,0.009098203,-0.096002854,-0.023110205,-0.029068206,0.18446986,-0.011836215,0.12906273,0.02819123,-0.000947542,-0.00988108,0.12741461,-0.0022125258,0.028228905,-0.018305313,-0.060241308,0.084817424,-0.03765905,0.08485427,0.07743898,-0.049564466,0.118558496,0.0073590293,0.022392957,0.05048402,-0.036259357,-0.13354518,-0.060813796,0.008762592,0.021679629,-0.018374037,-0.0013829407,0.006797995,0.012820198,-0.020920878,-0.059403047,-0.0040037865,-0.02724677,-0.030360034,0.0029625073,0.0041901264,0.02178824,0.11476692,0.07001615,-0.020304842,-0.08035417,0.0012362427,-0.06941805,-0.04095887,0.010110673,-0.05448846,0.04511373,-0.031548,-0.028884511,0.0077196173,0.051867526,-0.04516981,0.0014118048,-0.017654898,-0.024255073,-0.010905534,-0.08378177,0.13793828,-0.038259275,-0.027250018,-0.015300331,0.012897941,0.0026046762,-0.014913217,-0.031436283,-0.046955403,-0.063447036,0.07366539,0.009697514,0.038804863,-0.02552624,-0.02230755,-0.10082141,0.08233371,0.0031449576,0.024766827,0.01696446,-0.012515452,0.03426171,-0.003421943,0.030570367,-0.061391357,0.113579676,0.005211399,-3.1039424e-33,0.03350782,0.0038057365,-0.0022207466,0.055863738,0.061836723,0.0065301973,0.048837118,-0.03319834,0.07140955,-0.007989263,0.02343623,0.00786967,0.01782919,0.013363562,0.03109731,-0.013315663,-0.09950843,-0.04536078,-0.028738018,0.04057342,0.06406714,0.062248092,0.00050320633,0.012587123,-0.019330472,-0.0144032035,0.00751086,0.024607698,-0.014075386,0.028428609,0.041290045,-0.025062839,-0.038702887,0.04829056,0.008998299,-0.049517244,0.0792551,0.034528334,-0.051876526,0.063752525,-0.034166966,-0.049195122,-0.09123066,-0.05919553,0.054297592,0.027972246,0.08290378,0.035234652,0.06903497,-0.019046819,-0.03850106,-0.040406227,0.0248771,0.003659912,0.06331794,-0.021035085,-0.01613428,-0.02916153,-0.07208748,0.0170826,-0.029747307,-0.0061434032,0.06949918,0.09248682,0.028893616,-0.04582963,0.01619744,-0.0247959,-0.1420134,0.057537932,0.05281298,-0.01190793,0.04713856,-0.079263605,0.020528102,0.011218559,-0.0070282943,0.054085594,-0.10623384,-0.026651042,0.028702315,-0.048022863,0.041854538,0.07097449,0.001067449,0.053740203,0.057194352,-0.015483905,0.06990138,0.06511584,-0.060154337,0.04240384,-0.026555892,-0.05963001,-0.059962217,-4.0733607e-08,-0.0036527342,-0.011907495,-0.03284425,0.07100335,-0.08487263,0.030369896,0.04126718,0.022996308,0.0093741,0.018710375,-0.005030536,0.02525842,0.010414196,-0.059913892,0.05312822,0.015137735,0.020590162,0.11542182,-0.016292654,0.011451371,-0.0013075876,-0.06976758,0.031169966,0.0073143705,-0.0041101878,-0.042079423,0.008227564,0.010737088,-0.029814104,0.0028980125,0.042060386,-0.022853067,0.08184456,-0.07657338,0.010779321,-0.01869119,0.08279405,-0.015324747,0.027289303,0.0374036,-0.049715348,-0.021890152,0.0017657949,-0.029453801,0.010487282,0.026901484,-0.03221986,0.049926218,0.007880716,-0.03892393,-0.003989194,-0.060465056,-0.08968612,-0.044871315,0.07599013,0.0083917705,0.02719974,-0.06892849,-0.0060977386,0.015891474,0.12422379,-0.015268763,0.015658036,-0.07185247}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:38.66065+05:30	2026-10-12 18:54:46.264742+05:30
18	18	{-0.035117164,-0.0002433894,-0.0011790689,0.042717323,-0.04397829,-0.02800921,0.011552906,-0.007229449,-0.07055628,0.016123595,-0.055321783,-0.058998674,-0.018593684,-0.0126864165,-0.03620035,0.028287355,0.020534305,-0.0100184735,0.021849021,-0.08634673,0.025520267,0.030950027,-0.026492633,-0.014170439,0.035812307,-0.02664318,0.027702685,0.055085663,0.013830792,-0.038584936,0.0064066807,-0.021154314,-0.06217958,-0.0045366175,-0.127561,-0.013951926,-0.087482266,-0.015207004,0.060557008,-0.09063052,-0.0024967182,-0.05065075,-0.026248584,0.0172142,0.05373907,0.011247396,-0.07683241,0.06362924,-0.006438987,-0.011437556,-0.035745777,-0.062188074,0.017465388,0.0034875958,-0.059017055,-0.009884875,-0.0053837528,-0.046081927,0.0141581325,0.07870692,-0.05434454,-0.04715572,0.08240641,0.032827377,-0.03436305,0.06538021,-0.021944165,0.026716745,-0.021406842,-0.058529276,-0.009252144,0.091719285,-0.042288676,0.07359806,0.017591689,-0.06960332,0.05629958,0.052410103,-0.0176533,0.008158082,-0.022109915,0.020082714,-0.04290979,0.108182006,0.0716669,-0.035498954,-0.011336551,0.0008032555,0.048287738,-0.035499327,0.13122076,0.020408757,0.08763419,-0.0016092422,-0.03547745,0.021672934,-0.058436844,-0.076959066,-0.07176014,0.029775046,0.01713565,-0.0018569159,-0.011198181,-0.029190555,0.07283626,0.025329687,0.0462185,0.011158832,0.037053686,0.03616594,0.009544275,-0.004211476,0.038795713,-0.06963825,-0.0962013,-0.012705029,0.020762518,0.011261122,0.07443547,0.014131207,-0.04765573,-0.008503973,-0.026770385,-0.0675582,0.05440595,-0.007310488,0.040641475,4.585506e-33,-0.041734897,0.023858095,-0.004048432,-0.051630013,-0.05137478,-0.05695498,-0.0331264,-0.014441122,-0.046545386,-0.030321842,-0.041060794,0.014997752,0.010568132,0.023994578,0.0479611,-0.05561513,-0.02274913,0.011750872,0.12446084,-0.0017044318,-0.06343165,-0.102751404,0.06259837,-0.024845112,0.03524162,0.08302195,0.070737846,0.007111501,0.05513726,0.030242296,0.0084453635,-0.00828613,-0.08649958,0.060390946,-0.04201546,-0.029955348,-0.07032411,-0.06361386,-0.093250036,0.047423974,-0.06570696,-0.0040758336,-0.096121155,-0.007671031,-0.056496635,-0.007783169,0.02680842,0.034974582,0.096877806,0.11121763,-0.095893785,0.03442869,-0.008692921,0.0016937312,-0.08041954,0.030402653,0.009454275,-0.02506686,0.015363189,-0.0014363778,-0.022562064,-0.059716206,-0.011571079,-0.03313064,0.009388791,0.015843578,0.008405266,0.016730633,0.03250418,0.011714803,0.06461631,-0.01574556,0.060933795,0.11353066,-0.024387047,0.03358259,-0.0062478124,0.013181322,0.070068784,0.0036727448,-0.048175342,0.021672694,0.025605949,-0.034445975,0.16298294,-0.05231288,0.006946428,-0.06320938,-0.029313028,0.0012116377,-0.020097965,0.08578973,-0.087982625,0.092180885,-0.049888723,-4.3790937e-33,-0.024960848,0.015441188,0.021917164,0.089252494,0.059146717,-0.04389561,-0.03461174,0.049214665,0.09440196,0.11277564,-0.07272369,0.018357906,0.0031573575,-0.06666338,0.125859,-0.029328564,0.05230026,-0.09363547,-0.060336813,0.035860147,-0.08134339,0.02482888,-0.08974602,-0.016767334,0.013700664,0.026241008,-0.020849613,0.013976939,-0.0065778065,0.037777733,-0.05262919,-0.08913269,0.017402919,-0.008036258,0.003750183,0.05117739,0.09219855,0.09563649,0.028609611,0.015568226,0.05401835,0.000991438,0.023033358,-0.04071646,-0.069007546,0.04663235,-0.07415632,0.07084787,-0.07815842,-0.020322666,0.057847846,0.07609333,-0.013603989,0.043503463,0.0172467,0.03709327,0.009386868,0.024980512,0.008820345,0.0018006909,0.024117779,-0.025254866,0.026428543,0.072604306,0.066224344,-0.02585871,0.04624106,-0.09549191,-0.05522714,-0.0031948164,-0.009625965,0.04700977,-0.033265352,-0.0386245,-0.011788978,-0.012366097,0.024412192,0.052213054,0.033874787,-0.0142814005,0.09950422,0.040845275,0.07443509,-0.027344482,-0.057370286,-0.06453597,0.02180032,0.014082392,0.044211127,0.084268115,-0.077230595,0.09550849,-0.10123313,0.033881307,-0.09978169,-3.936528e-08,0.015286509,-0.022983484,-0.044106092,-0.005631763,-0.0011419312,-0.011659232,0.03329551,0.07028981,-0.10298782,0.049516533,0.064285606,0.04115267,-0.05756003,0.06865335,-0.059584565,-0.025568042,-0.050655607,0.0039711986,-0.044740524,0.016826637,0.05873503,0.035221193,-0.028294785,-0.029676033,0.07215739,-0.012687227,-0.052523,0.06611062,0.026530072,-0.0934221,-0.11475981,0.0605231,-0.030789696,-0.040337835,0.027107332,0.08900483,-0.021864664,-0.041917775,0.024080144,0.064131744,0.015827127,0.03293927,0.0029346342,-0.02239492,0.07828856,-0.024391375,-0.080641426,-0.053677898,0.03787987,-0.063016675,-0.02918758,-0.05770085,-0.031493396,0.037532315,0.02014633,-0.02652088,0.0047804173,-0.09480456,0.0011696313,0.07496209,0.11347765,-0.014251919,0.024039034,0.01624104}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:40.455602+05:30	2026-10-12 18:54:46.37769+05:30
20	20	{-0.051611338,0.029896371,0.0063237697,-0.0050198603,0.09581456,-0.09072109,0.009199067,-0.021129312,-0.07405939,0.025454747,0.019013513,-0.0070759365,0.06717125,-0.036902543,-0.06808974,0.068116695,0.09080168,0.021286858,0.029420257,-0.048395198,-0.057128515,-0.0002577084,-0.025249159,-0.014260639,-0.018006219,0.032196477,-0.02076707,0.028890317,-0.03830863,-0.06827992,0.10759207,-0.03811925,0.007123184,0.05601881,-0.029027695,0.032101322,0.05345429,-0.03985315,-0.028228376,-0.018938,0.007834087,-0.02388544,-0.080798626,-0.025379265,0.0038212622,0.07273531,-0.042667482,-0.052316345,-0.041248016,-0.063583456,0.10622002,-0.09045525,-0.035127033,0.029414024,-0.064558946,-0.047282144,-0.012747686,0.01916279,0.04681704,0.07303498,0.091505565,0.0018413903,0.023040142,0.050274894,-0.015076548,0.052378446,0.029443407,0.05394781,-0.035026252,-0.07300082,0.06330097,0.04148818,-0.022348097,0.014943739,0.013664761,0.038274106,0.0019461287,-0.065579265,-0.007294408,0.020509275,-0.0896114,-0.036368843,-0.023731558,0.01327144,0.02882551,-0.011426815,0.009282383,0.04212031,-0.016403822,0.026701402,-0.015451344,0.057124637,-0.009248853,0.022733483,0.08452573,0.009785313,-0.026071137,-0.0702801,-0.04716637,0.01373545,-0.07523861,-0.061358843,-0.027822768,-0.051437713,0.10018515,0.0253013,-0.055872068,-0.037693158,0.09032841,0.006544562,0.02685491,-0.03829858,0.017990462,0.003221657,-0.013085246,0.012254095,-0.056749642,0.06513189,0.0685411,0.017516874,0.06270899,0.018324563,-0.006785299,-0.048289713,0.023688897,-0.021054674,0.0033149258,4.191742e-33,-0.014252951,0.054326765,-0.02892341,0.008320137,0.07649914,-0.027846802,0.037863616,-0.0040830313,-0.06799139,-0.0042197024,-0.08621425,-0.02505228,0.03027994,0.01465412,0.016055964,-0.03234714,-0.010502932,-0.035673548,0.0774605,0.012773534,0.02578579,-0.09679056,-0.024434773,0.0021959934,0.023522343,0.008842608,0.039939784,0.010959373,0.13655132,0.006763152,-0.10125341,0.0334051,0.057467937,0.04155096,-0.030861968,0.0906991,0.016907742,-0.077848814,-0.039702386,-0.078140974,0.069882385,-0.010865725,-0.04846001,-0.090359814,0.0048557553,-0.07176252,-0.07486836,-0.028148858,0.06351007,0.030225646,-0.066889405,-0.052437402,0.054664273,-0.0068721655,-0.020854712,-0.020040149,-0.011540797,0.038178977,0.009277328,0.08850035,-0.007344166,-0.0667803,-0.053364422,-0.041554347,0.030430118,0.030947765,0.024173519,-0.012827272,-0.024694448,0.045967177,-0.07900406,0.0008382038,0.056924637,0.05929219,-0.05709286,-0.053969268,-0.038665164,0.086224586,-0.013193671,-0.04821185,-0.057019692,0.00041630538,0.06257799,0.030014638,0.009817454,-0.081419535,-0.0445992,0.0142068835,-0.06812444,0.08418496,-0.016017476,-0.011272204,0.10807812,0.06981147,-0.098750696,-3.483917e-33,-0.112299435,0.045979716,-0.029295221,0.114820674,0.028895728,-0.022753565,0.004924354,0.04646772,-0.10588213,0.064770564,-0.014617841,-0.05976599,0.09794605,-0.100669794,-0.04728087,-0.05454553,-0.001431329,-0.07063801,-0.008607633,0.019543322,-0.011465284,0.029086044,0.021096664,-0.057378493,0.0009203382,0.06927457,-0.05225503,-0.01291597,0.036133368,0.009646313,0.060249224,-0.007021547,0.029134339,-0.1244228,0.03354624,-0.019088909,0.13056858,0.0017520252,-0.020608457,0.017515656,0.042134553,-0.0018026999,-0.030420715,0.017733872,0.0033226067,0.03985066,-0.029879697,0.074136846,-0.038576163,-0.07647628,0.012485395,0.024321312,0.013986518,0.059587065,-0.018923352,0.022798367,0.037767597,0.12830718,-0.09246962,-0.008383184,0.046126075,-0.098613895,0.019351596,0.07600087,0.035814155,0.066930614,-0.03729956,-0.0027543937,-0.056199327,0.03821621,-0.019131394,-0.0022295911,-0.056749444,-0.02384046,0.020104043,-0.073886,0.02291923,-0.055871643,0.0012280485,0.055390906,0.004054936,0.0033384948,-0.050074473,0.017993959,0.067566514,-0.0785539,0.029245099,0.022910861,-0.004463071,0.015687928,-0.14184606,0.010405303,-0.10738792,0.036052324,-0.036972154,-3.654194e-08,-0.024502605,0.03363054,-0.033858415,-0.04489362,-0.031191146,0.042488083,0.08667334,-0.03995129,0.008971839,0.0069905445,0.019391786,-0.056249067,-0.10573831,-0.06169396,0.04389168,0.0054386663,-0.060674354,0.055220407,0.022132495,-0.044142704,0.04644138,0.042760547,-0.022933034,-0.045768484,0.036295615,0.020778045,0.07986194,0.048902523,0.0022233217,0.042968158,-0.07691529,-0.035378754,0.07310244,-0.015114469,-0.052514758,0.1054374,-0.053966098,0.008401908,0.115234785,0.07173964,-0.015824087,0.06855197,-0.02170432,-0.011640858,-0.04816425,-0.016583344,0.046343487,0.0836798,-0.0033752362,0.023007656,0.060080964,-0.045984708,-0.021896241,0.013445123,-0.0032031327,0.056980494,0.029146709,-0.098848686,0.085434385,0.07849624,0.05795985,-0.07435285,0.043400645,0.047392227}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:47.860136+05:30	2026-10-12 18:54:46.516561+05:30
22	22	{-0.042887766,0.05448465,-0.052766282,-0.04796599,0.095479034,-0.024509966,0.036435124,-0.021812566,-0.014098789,-0.039946847,-0.037259307,-0.0107451035,-0.008583594,0.00038486978,-0.01178947,5.6768706e-05,-0.019529043,0.042197593,0.009130526,-0.031742565,0.0076030595,0.029694322,0.010691477,0.006630043,-0.056717698,-0.0034930327,0.05010924,0.06128593,-0.023051945,-0.04134803,0.031577885,-0.0214033,0.037021324,-0.057913274,-0.013461955,0.027544709,0.05879637,0.003533396,-0.012805226,-0.051576424,-0.00056915253,0.019583743,-0.05343781,0.06928295,-0.010552848,0.011054919,-0.019068837,-0.0066724364,-0.008864286,-0.05230119,0.010522333,-0.0014761507,-0.052388962,0.06937831,-0.06622176,-0.08662216,-0.0015140997,0.006851057,0.021761535,0.029873485,-0.013696286,0.039284334,-0.009382268,0.023375476,-0.03856996,-0.004411525,0.0051808255,0.031554922,0.043611255,-0.059287976,-0.07705123,0.016101753,-0.023305187,0.08754451,0.012731136,0.043923967,-0.024474103,0.07932021,-0.004112321,-0.04443212,-0.043428168,0.017082091,-0.009512982,0.021049647,0.027375212,-0.0028957531,-0.015876507,0.034391515,0.012596967,0.07205575,0.07543175,0.0139355585,0.06432547,0.006362598,0.07443978,0.029149104,-0.030339604,-0.051657792,-0.058294404,0.06403065,-0.11084115,-0.06951557,0.012815781,-0.02625935,0.08328105,0.026109112,0.062189776,-0.023743292,0.09204048,-0.086536825,-0.027476449,0.012666199,-0.0116254985,-0.061722707,0.047009435,0.00960948,-0.08359789,0.040672153,-0.049850456,0.01439092,-0.034834646,0.032473285,-0.0013819435,-0.039712775,0.006067287,-0.03173278,-0.051430497,2.1164195e-33,-0.025806807,-0.07405395,-0.036752913,-0.012608598,0.047561698,-0.10055507,0.037014548,0.095415294,0.00700059,0.047280543,-0.08512607,0.060196947,0.035122238,0.08453626,0.056137957,0.04439911,0.0128326425,0.03337767,-0.008261601,-0.029177822,0.04563869,-0.010996577,-0.052488033,-0.014214161,-0.0030736236,0.0217589,-0.0009936834,0.038406905,0.05911586,0.04942119,-0.047170945,0.042449303,-0.049343985,-0.04979676,-0.0099831475,-0.012448112,-0.057756677,-0.004761636,0.025606893,-0.0080141565,0.023881959,-0.049761355,0.045721903,-0.026965713,-0.035334665,0.020809405,-0.061455745,-0.053148866,0.011415199,0.035127025,0.0161686,-0.009448645,-0.00820916,0.09316387,-0.07298243,0.092092626,0.0017119248,0.021595607,-0.018689249,0.014962235,0.031890962,0.08627804,0.02687225,-0.014273514,-0.044495653,-0.05224164,0.08070021,0.06077724,-0.029809067,0.09404326,0.005825228,0.049895436,0.08391465,-0.01797545,0.016528705,-0.064272724,0.08534125,-0.08182746,-0.02772913,0.031035934,-0.055736706,-0.0025375122,0.08404271,-0.09869038,-0.0740463,0.0012713261,-0.03348472,-0.06228505,-0.042602662,0.06866935,-0.024604168,-0.058881477,-0.021855764,0.07714946,-0.07004769,-2.6994117e-33,0.02478888,-0.011216506,0.00643145,-0.044881847,-0.08196158,0.07594812,-0.08086328,0.03334368,-0.0768713,0.043002874,-0.042846724,0.056328677,0.12566887,-0.024071664,0.02694706,0.09707141,-0.05185142,-0.01418185,0.021719111,0.020678258,-0.01152032,0.08842625,-0.037974518,-0.07001188,-0.031308502,-0.050283473,-0.025206663,0.11021415,0.04218761,-0.014346372,-0.025185581,0.0022044217,-0.08401366,-0.08168403,-0.0014488018,-0.0481064,0.08624395,-0.13758111,0.08843921,0.0077962526,0.040919993,0.06040075,-0.060926795,0.017632203,0.033803776,0.020654263,0.010846859,0.035058126,0.11050203,-0.052275494,0.07360929,0.111828096,-0.020873891,-0.030659156,-0.055188317,0.028521297,-0.05712628,0.043579556,0.015541189,0.07369451,0.0133432755,-0.07548812,-0.062134508,-0.00014422274,-0.00865791,0.03982436,0.01367364,0.055190112,-0.031087274,0.0035448913,0.06439742,-0.018298807,-0.044895656,0.020571856,-0.089401506,-0.015418549,0.08235562,-0.13354766,-0.088003725,0.0444545,0.12018256,-0.022582168,0.0063662613,0.032821443,-0.032447636,0.0040367898,0.01741529,-0.048028823,0.036132958,0.019789578,-0.0016639284,0.046089556,0.0077187503,0.03593165,0.049726203,-3.7158703e-08,0.044789962,-0.01163585,0.01211952,0.01747938,0.010395607,0.10333935,-0.12430325,0.062039442,-0.08393672,-0.068669245,0.0729916,-0.086241275,-0.11823221,-0.034636114,-0.027182687,0.0665369,-0.07867283,0.017778631,0.002547981,-0.043762658,0.06538523,0.05029131,0.06061518,0.013348638,-0.070772015,-0.07221636,0.03814884,0.0002750294,-0.0038175143,0.048822194,-0.08612916,0.029100245,-0.034642253,0.0051730345,0.042936616,0.11046186,-0.035350587,-0.012290997,-0.026562067,0.048782337,0.052418362,-0.044792034,-0.030336589,-0.028049013,-0.047251873,0.016067948,0.006011564,-0.09384921,0.054819826,-0.01725917,0.12159358,0.05583501,-0.019813754,0.05465185,-0.016410688,0.06709331,-0.113947935,-0.097041324,0.01852161,0.059666745,0.00526659,-0.027732486,0.09933056,0.0020805032}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:48.023273+05:30	2026-10-12 18:54:46.663148+05:30
24	24	{-0.11638933,-0.0063086315,0.036404353,-0.009169274,0.04579536,-0.024089653,0.035209525,0.012543053,0.00040311652,-0.03616347,-0.03825346,0.010954371,-0.0012809223,-0.007872779,0.015006153,0.07503135,0.07523817,-0.011078752,0.0074370136,-0.070639305,-0.04791276,0.055463366,0.086279325,-0.025468405,-0.017246557,0.013100196,-0.08321162,0.0461793,0.008998942,-0.021447675,-0.034782857,0.026101423,0.007953328,0.07131289,-0.11025815,0.039643887,-0.015069958,0.058468547,-0.06484621,-0.07069933,-0.118054844,-0.013471709,-0.030273592,0.0037447421,0.06765227,-0.03366916,-0.08273906,0.024611639,-0.13302077,0.035997488,-0.05886129,-0.11990543,0.004683782,0.013030844,-0.021225737,0.056597367,-0.043729063,0.07007512,0.08135547,0.013571254,-0.004602404,-0.036839966,-0.015242957,-0.035008017,0.03317397,0.044594686,-0.017924057,0.010297158,-0.05620451,-0.050408248,0.0051904274,-0.03322207,0.0126155205,0.09830586,-0.01112989,0.023268724,0.012326264,-0.056541435,-0.0063490104,0.03359468,-0.011479518,-0.041038062,-0.023359992,0.07729189,0.076298706,-0.020562384,0.038079422,0.018758113,-0.023425031,0.0745724,-0.04853298,-0.062486462,0.027857365,-0.0034332054,-0.04270253,0.026299812,-0.076835506,-0.048824757,-0.047882132,0.093209855,0.09527329,-0.00096193724,0.012228059,-0.10347148,-0.031628374,-0.04137848,0.060914304,0.023793105,0.024718637,-0.030842785,-0.04228792,0.009476888,-0.012111383,-0.1633655,0.06972491,0.02895295,0.0055555347,-0.0029550577,0.14391184,0.04235002,0.016659299,0.024384072,-0.035045408,0.022926435,0.12589636,-0.092904955,0.02512506,2.8331227e-33,0.037554704,0.054182377,-0.009827366,0.036902424,0.07700114,0.03568842,-0.09523929,-0.013987205,-0.12773438,-0.104235515,0.006337321,0.083240576,0.05478155,0.08328183,-0.025732148,-0.031274468,-0.060692504,0.044039797,0.04177776,0.01643834,-0.032779757,0.0099838665,0.04233827,-0.0014755395,-0.03261881,0.019584257,0.03819765,-0.032910902,0.00086375856,0.03115856,-0.10688447,0.0051835007,-0.03533187,0.024183106,0.003029495,0.0030767326,-0.029989699,-0.02794264,0.016841967,0.0076885195,-0.03341362,0.051719844,-0.05086737,0.009035042,-0.026937233,0.043824296,-0.007935693,-0.0013923581,0.065828115,-0.014766587,0.038070757,-0.0045120562,0.04370495,0.081922494,-0.036456477,0.006003407,0.049884155,0.0026700092,0.033251185,-0.045122944,0.05732782,0.083862156,-0.018360252,-0.03434839,0.03052675,-0.06663757,-0.09922303,0.048088185,0.05974613,-0.074145675,0.017745452,0.0014244936,0.055010937,0.04804661,-0.09412774,-0.09086581,-0.01425341,0.018479975,0.059795823,-0.012892491,0.03844812,-0.04697996,-0.020116039,-0.112259634,0.0018251861,-0.017206838,-0.0324949,-0.06774522,-0.027578779,0.03653713,-0.08924526,0.0046898257,0.01087286,0.043076437,-0.03078864,-3.1397583e-33,-0.083928816,0.025222395,-0.08307052,0.107997015,-0.026181962,0.05077872,0.0030615379,0.08036679,0.07724691,0.017256605,0.050293967,-0.115643844,0.015580325,-0.017970882,0.0029919299,-0.05056024,-0.091417775,-0.05127613,-0.034420345,-0.015136479,0.015027775,-0.04111059,-0.06728698,0.061569657,-0.03431311,0.072870836,-0.023457253,-0.019244269,-0.013698896,-0.045861673,-0.065909445,0.00820095,-0.025493952,0.024017036,0.10325239,0.0039608,0.05489935,0.014142755,0.0052534854,0.022747971,0.06874941,0.023057172,-0.00025457205,-0.009399906,-0.059194285,0.092366196,-0.07375233,0.018309465,-0.026939122,0.03683734,0.08390888,-0.020917507,-0.008802457,-0.036789645,-0.035180494,-0.07019908,-0.0087362565,-0.032148875,-0.03475262,0.08019433,-0.028901633,-0.05372304,0.019409629,-0.05128382,0.06522317,-0.05039233,0.027393935,0.0278976,0.053233024,0.00072295935,0.013848735,-0.049601384,-0.011736899,-0.050648335,0.08273188,-0.011606723,0.097927265,-0.038364843,-0.0820142,-0.062050696,0.056231827,-0.029279811,0.008685386,-0.0485783,0.048961677,-0.02847104,-0.0062287557,0.05707665,-0.009308159,0.029021794,0.018161805,0.12604254,0.018738646,-0.016391132,-0.0769992,-3.895211e-08,-0.018165177,-0.102409355,-0.050432824,0.11357739,-0.020153152,-0.05495413,0.07351463,-0.022453152,0.014683626,0.0028769842,0.08419858,-0.026120538,-0.027802862,-0.034364924,0.040021103,-0.03899344,-0.057971835,0.03112305,-0.027571103,-0.06358191,0.033309963,0.07772413,-0.040161815,0.0077398317,0.014091026,-0.009633843,-0.007788252,0.10545945,-0.048390765,-0.008660001,-0.0673737,0.060609307,-0.061623987,-0.050256576,-0.009493851,0.049796905,0.03260615,-0.061420828,0.0044263303,0.029075658,0.024869211,0.027924826,-0.041972585,0.0008520537,0.028603775,-0.044204216,0.014542409,-0.0995829,0.055262025,0.0077880044,-0.018593036,0.05653926,0.03034327,0.02960208,0.024593271,0.0451721,0.028144624,0.033520177,0.01156962,0.068021245,0.06413257,0.036419116,0.04793741,0.044086013}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:53.950904+05:30	2026-10-12 18:54:46.78324+05:30
26	26	{-0.006274038,-0.02687294,-0.0006811623,0.04343705,-0.008043516,-0.051882025,0.02367047,-0.012315884,-0.078095995,0.02850164,0.037466377,0.0062919855,-0.01377909,0.02688166,0.07364981,-0.0010975428,0.03228368,0.025781495,0.026628546,-0.043329477,-0.06621077,0.03383041,-0.03531993,0.041017696,-0.022195078,0.07577208,-0.04726429,0.06319483,-0.010171303,-0.009203937,0.05664605,0.0044764886,0.08896855,0.035589878,-0.01933451,0.10739298,-0.023489766,-0.065188825,-0.010781871,-0.048376318,0.01172305,-0.03451447,-0.0319772,-0.07710121,0.0015485934,0.02512803,-0.08534728,-0.02994467,-0.03484069,-0.009525474,-0.010006207,-0.0052971155,0.06019978,0.10297922,-0.059150074,0.0828364,0.09759186,-0.042418532,-0.008703383,-0.10829492,0.029839676,-0.010273914,0.031653263,0.067018814,-0.033264447,0.015436449,-0.031445738,0.04670696,0.052620713,-0.06926804,-0.021832732,-0.07658857,-0.05351203,0.060668167,-0.012254413,0.0053402632,-0.02280658,-0.027099257,0.0801285,0.031678878,0.03188201,0.01899642,-0.0033661763,0.073298894,-0.035832535,-0.010916396,-0.037830196,0.015981192,-0.011044168,-0.032559525,0.021719182,0.09323285,0.11540335,-0.07678833,-0.11409674,-0.010469765,-0.040943146,-0.077127464,-0.071608216,0.067999035,0.005818162,0.039746676,0.051205106,-0.011842524,0.037022162,-0.062117115,0.039875593,0.081297904,0.031304125,0.0015826585,0.011751429,-0.037410334,-0.033781614,-0.042865727,0.03268429,-0.004238871,-0.0034415114,0.04195255,0.06590251,0.035302576,0.06074103,0.0014394011,-0.032135382,-0.06963299,0.08624764,0.04620129,0.034203142,3.5493997e-33,-0.011156399,0.043706182,-0.057265498,0.0039257663,0.09239935,-0.004267325,-0.007319349,0.07816792,0.0632188,-0.017035382,0.10942378,0.0760926,-0.004528332,0.026544617,0.0168449,-0.0009301808,-0.01233656,0.10771825,0.09798486,0.020155126,-0.016041705,-0.049048975,0.0405419,-0.005691226,0.08553185,-0.007444587,0.028771838,0.07423924,0.038415715,-0.016532043,0.048016485,0.057669044,-0.019976152,-0.009891904,-0.009692076,-0.018200682,-0.085615195,-0.10448714,-0.117988944,-0.03410813,-0.13207278,-0.0057281586,0.0042106505,-0.001925858,0.02457493,0.017101401,0.05445325,-0.019785797,0.06436961,0.024295306,-0.016670654,-0.008906939,-0.096824944,0.07495111,-0.0024609677,0.018226115,0.0677909,-0.04717552,0.0100418655,-0.063116446,-0.05223632,-0.03965389,-0.05449533,-0.009983102,0.057674397,-0.08713691,0.012272092,0.03676401,0.12428419,0.025448995,0.0045074825,0.003180729,0.06580542,0.08728757,-0.05652617,-0.045028042,-0.097454265,0.051807847,-0.10205228,0.064495526,-0.006517996,-0.06963663,0.018270262,0.0475506,0.099650994,0.02554531,0.046702713,0.023080433,-0.012589996,0.015870715,0.01583501,0.04854633,-0.031225424,0.108789325,-0.018280504,-2.9888325e-33,-0.051052164,-0.04733113,-0.054981146,0.022218449,0.0030666634,-0.0036947764,-0.13423239,-0.02798729,-0.004981874,0.023150694,-0.04172802,-0.013922353,-0.0044525918,-0.018802345,-0.03879472,0.09915899,0.0027477916,-0.17566425,-0.08593575,0.041032214,0.00562906,0.048889704,-0.055546854,0.031765655,-0.024848668,0.038880803,0.017233018,-0.0010862673,0.0040254053,0.045295376,-0.049918313,-0.048298344,-0.026658885,-0.023972219,0.020987643,-0.006297981,-0.02962136,0.05880727,-0.08605988,0.029480003,0.057890587,-0.0481933,0.0059277425,0.002826229,0.033216964,-0.007380394,-0.05770378,0.008630896,-0.09259626,-0.012796885,-0.079755545,-0.03922937,-0.046615247,-0.017215393,0.030119322,0.014446156,0.0023400132,0.036576323,-0.08992998,-0.017247679,0.04684797,0.02588448,0.073819585,0.059859138,-0.028296199,-0.016037803,0.04439082,-0.07631541,-0.06666533,-0.0037604384,0.06605498,0.016324881,0.014485709,-0.02132542,0.01082436,-0.007938261,-0.011983177,-0.054240763,-0.04465849,-0.069131695,0.0024075878,-0.020415768,-0.0312987,0.031599198,0.016937343,-0.107307434,-0.03262877,0.03894275,0.019384876,0.020272616,-0.016191518,0.07344074,-0.14321896,-0.028084558,-0.015351132,-4.6992678e-08,-0.05144179,0.02717302,-0.07179787,-0.07695977,0.074301824,-0.061285995,0.036264814,0.0067547276,0.0295302,0.110022485,0.07633295,-0.017022979,-0.061317325,-0.0030790758,0.030221203,0.0015869628,-0.025524583,0.060259204,-0.050631743,0.028701575,0.023201909,-0.045496684,-0.028419571,0.03368981,0.03878586,-0.047231056,-0.04593427,0.07233591,0.08547155,-0.018479334,-0.015595923,0.008417423,0.047353674,-0.011286457,0.11667489,0.05088028,0.0662573,-0.11224414,0.051737938,-0.022274982,-0.06026455,-0.05401316,-0.013667995,0.006991009,0.0001051528,0.041163858,-0.008493662,-0.047496,0.05600586,-0.07205504,-0.016044738,-0.088170946,0.01466782,0.040301893,0.03688489,-0.039961,0.06704988,-0.0428831,0.055404287,0.025815021,0.010865172,-0.0030519841,-0.021930316,-0.025307711}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:59.960178+05:30	2026-10-12 18:54:46.881577+05:30
28	28	{-0.010809396,0.058376584,0.020600129,-0.013278063,0.0917285,-0.14462273,0.06368187,0.04034583,-0.0060072276,-0.0075599346,-0.00061007304,-0.061490025,0.010042233,0.0067495382,-0.07175346,-0.023419736,0.09499346,-0.041536,-0.013785986,-0.054088324,0.1055864,0.03268583,0.05115866,-0.035504617,0.022742057,0.035621826,0.021334043,0.001174143,-0.06081099,-0.06374875,0.0043086093,-0.016878862,0.047016796,-0.01798106,0.010938604,0.057936218,0.018239565,-0.051470373,-0.018831013,-0.058523998,-0.06332285,-0.07760422,0.0040382664,-0.095901825,0.03973619,0.035204176,-0.05914104,-0.101459295,-0.008951525,-0.07264261,0.051574923,-0.050735436,0.008598079,0.087361835,-0.036809497,-0.035118688,0.04703862,-0.061432406,0.0044628815,-0.04173248,0.043767195,-0.00018125128,0.06493584,0.027312148,0.098221205,-0.0049606054,0.041906744,-0.015422392,-0.017716724,-0.10651826,-0.05997766,0.0044536088,0.03012036,0.04380058,-0.05899835,0.054388344,0.06587455,-0.043823265,0.0043794345,-0.02770086,-0.04828827,0.035221394,-0.016866302,-0.023373142,-0.040768657,0.014232337,-0.12114157,0.06074975,0.01847026,-0.01183889,-6.384955e-05,0.032508094,0.019696733,-0.082832664,0.06684539,-0.04629544,0.011318951,-0.06023579,-0.015853884,0.029575527,-0.048229963,0.05976,-0.0029862395,-0.02396075,0.11329331,-0.037344534,-0.015383985,-0.036814794,0.109690264,-0.040971816,-0.017446874,-0.08374266,-0.012623308,0.058642864,-0.009361482,0.09007771,0.023870103,0.060891278,-0.019414065,0.03331498,-0.00026161663,-0.08082445,-0.1251755,-0.065235734,0.1743002,0.026515307,0.015003903,4.2900126e-33,-0.0035547817,0.007986745,-0.022882754,-0.027285293,0.06823345,-0.03828943,0.03634059,0.015636023,-0.039253723,0.01499,-0.07694898,-0.024961926,-0.036926366,0.060055405,0.03904771,-0.08884412,-0.027167471,0.018797252,-0.004618436,-0.05982092,0.029007344,0.02149174,0.008080307,-0.020994572,0.09534826,0.012620283,-0.027671488,-0.014369095,0.039105553,0.01823188,0.047844697,0.11652328,-0.052565817,0.021674901,0.069002435,-0.063288905,-0.09320517,0.045952156,-0.025272917,-0.059023574,0.00036338193,0.025421845,-0.041702088,-0.083440766,-0.020544622,-0.07543684,0.03624532,-0.008047562,0.0897143,8.402948e-05,0.0027770386,0.029255515,-0.011982504,-0.076889426,0.05485573,-0.07779911,0.038125604,-0.033626225,0.049825348,-0.015969615,0.037550848,0.073213354,-0.009798359,0.015070218,0.10267422,-0.05230977,0.04689823,0.045580797,0.058171917,0.07773624,0.02694765,-0.009278489,-0.04115919,0.014149766,0.038339492,-0.0022658561,-0.021786317,-0.03709328,-0.05828596,-0.03996513,0.012814361,0.026249014,0.034461595,-0.095370464,-0.020711796,-0.0019966862,0.02139678,0.03728871,-0.019497886,-0.0015568661,-0.023969548,-0.012854836,-0.040349547,0.012346826,-0.042327955,-4.5980924e-33,0.045595493,0.062415145,0.030365437,0.061438143,-0.02317199,-0.04477475,-0.026871251,-0.029134234,-0.0091266055,0.14235511,-0.019653406,0.062107127,0.08241535,-0.0036532425,0.05082171,0.036065374,-0.03958859,-0.115732,-0.08439936,-0.015637856,-0.043500774,0.07928925,0.059387073,-0.06336078,-0.05197997,0.0147628235,-0.031119332,-0.027877185,-0.028331708,-0.0397058,-0.09731344,-0.059045788,0.028259935,-0.032311797,0.02915973,-0.04060114,0.04988712,0.04290603,-0.023601579,-0.03429877,0.060792755,-0.011354879,-0.07025149,0.0053570988,-0.076149195,-0.063553736,-0.09284501,0.094606504,0.008956937,-0.030983372,0.03139484,0.05390479,-0.03719538,-0.019320568,0.057464562,0.085301,0.034362722,0.06554605,-0.11593186,-0.048421632,0.025999518,-0.008379323,0.03867434,0.04796765,0.026790872,0.014430222,0.04742576,-0.006743142,-0.014614827,-0.013237318,0.059284143,0.027692072,0.034603905,-0.100614935,-0.017198974,-0.03723779,0.0032800643,0.014704761,-0.017127551,0.0017073365,0.031588007,-0.04924791,0.038019937,0.059260797,0.0051616975,-0.049254354,-0.042272933,-0.009737157,0.0055931895,0.026660096,-0.051059023,-0.040099073,0.030632123,0.055134133,-0.026158718,-4.063398e-08,0.011013391,-0.01008479,0.029306019,0.025725044,0.029685734,-0.05785994,0.05008382,0.048762873,0.025552582,0.06073409,0.004897517,-0.016503174,-0.030692898,-0.0043719704,0.10120379,-0.028453827,-0.015332781,0.012200398,-0.0024503896,-0.003310406,0.07943816,-0.15181063,0.002494398,0.07156772,0.07190095,0.014138499,-0.05162299,0.02608654,0.04228883,0.03673374,0.04975925,0.005437915,0.0033953376,0.013794142,-0.00038040694,0.030549167,-0.06280558,-0.022535784,-0.028244054,0.029519722,0.02237168,-0.02860839,-0.034339264,0.00698515,-0.023691539,0.041201398,-0.027582988,-0.06755169,-0.0112130605,0.018540157,8.095991e-06,-0.10055505,0.028679088,0.084333256,0.059049666,-0.015665835,0.12334271,-0.10177342,0.1098352,0.095638655,0.09793401,0.0015942696,0.009323558,-0.05485649}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:07.10465+05:30	2026-10-12 18:54:46.994745+05:30
30	30	{-0.041086566,-0.014336551,-0.049862783,-0.03641104,0.05086974,-0.015150252,0.021186277,-0.051436145,-0.0512104,-0.015154764,0.06891746,-0.0144712385,0.011130912,0.029056353,-0.04075552,0.02765133,0.061307587,-0.03134863,0.06596052,-0.04422419,-0.034866355,-0.0136944875,0.013174926,-0.03068963,-0.0041743456,-0.0025858844,-0.0580818,0.012900456,-0.026302895,0.01355855,0.038079157,-0.0001761119,-0.059161674,0.057937995,-0.019699376,0.011461264,0.0040583103,0.031736474,-0.025429394,-0.04749634,0.03964856,-0.05591799,-0.025104461,0.03523872,-0.030779997,0.00012943194,-0.096454896,0.008108783,0.028859701,-0.062838934,-0.010335146,-0.05854256,-0.010842254,0.07016763,-0.02461869,0.05464644,0.025526086,0.020179825,0.0005208647,-0.031603303,0.122813016,-0.027642222,-0.05942218,0.04022922,0.059756953,0.031211333,-0.072885714,0.030608503,0.04799833,-0.13892116,-0.0076619787,0.04051921,-0.0060133166,0.060560297,0.046558004,0.012526927,-0.011864172,0.03569848,0.09408818,-0.048848778,0.03553998,0.06018436,-0.028190207,-0.0056669214,-0.0485572,-0.026086131,-0.011194443,-0.03744777,0.018006932,-0.019938983,-0.0043301736,0.05579892,-0.0048544165,-0.028254382,-0.027591145,-0.030778356,-0.008016717,-0.065323256,-0.07074032,0.039746176,-0.02772151,-0.037283957,0.024917906,-0.10628089,0.07821187,-0.021155046,-0.015965015,0.038705222,0.1005033,0.070243515,-0.080410026,-0.011472016,-0.04898785,-0.018696016,-0.0037106983,0.0290363,0.0952279,0.063372664,0.10413038,0.023729753,0.0019178058,-0.012470835,-0.016700827,-0.10118785,0.09939954,-0.05629367,-0.06657472,3.796623e-33,0.004852324,0.061989192,-0.067925975,0.004692776,0.061236143,0.005629291,0.0009813712,-0.051627424,-0.09355403,0.016941821,-0.06046056,0.04202991,0.06933677,0.100972295,0.074510835,-0.04101766,0.008489821,0.016895577,0.11403977,0.039876573,0.004227068,-0.008383915,0.014589169,0.0035887102,0.036762394,-0.048753615,-0.014895159,0.059778363,0.12599447,0.026007475,-0.028686728,0.028021822,0.010388707,0.04284437,0.022767402,0.065867126,0.0067916308,-0.12989658,-0.013598376,-0.08349095,-0.017509516,-0.017680753,-0.06481083,-0.029277895,0.024403628,-0.03883058,0.033267733,0.021411952,0.0022290582,0.04008458,-0.03381766,0.00272712,-0.07413017,0.060613725,-0.06213928,0.0011929505,0.011455929,0.021836162,0.07685485,0.0057929726,0.023329293,-0.0047463058,-0.04437376,0.04969296,-0.07067445,-0.14862144,0.026873542,-0.017247723,0.060347896,0.072081275,-0.020342786,0.037294984,0.04805686,0.092128426,-0.09320116,-0.0034195094,-0.09716364,0.045601003,0.024295945,-0.029924402,0.013485322,-0.02662027,0.025313046,0.08791755,0.017449647,0.0004891907,-0.048473936,0.0070100585,-0.030869247,0.012905184,0.020460354,0.008200106,0.03626051,0.091136456,-0.03854848,-4.022571e-33,-0.07605488,-0.04828221,0.00018634784,0.02983534,0.0029593199,-0.035551738,-0.020761728,-0.04201639,-0.001379234,0.06590782,0.013472512,-0.06847283,0.1218183,-0.0562906,0.0419611,0.03766514,0.05689623,-0.06774606,0.0046586804,-0.0049662967,0.001967006,0.04740164,-0.07275165,0.0017712679,0.0014429771,-0.039331384,-0.033492476,0.010495013,-0.047307797,-0.0059370263,-0.05141948,-0.04568224,0.02427696,-0.0166793,0.019395465,0.026721217,0.09564887,-0.019144807,-0.009672852,-0.043844547,0.086296156,-0.023983305,-0.037647538,0.014864611,-0.05660828,0.043020446,-0.07574849,-0.022828436,-0.10246251,0.03196684,-0.025983471,-0.0625028,0.08556175,-0.00043182194,-0.065845415,0.099326394,0.014512103,0.06377546,0.03453001,0.020980662,0.09500424,-0.10443217,-0.070489645,0.12132673,0.027599884,-0.016204895,-0.039029624,0.032775924,-0.049444553,0.030432679,0.050287172,-0.009448069,-0.061086804,-0.07206074,-0.094122,-0.10109726,0.08722428,0.021140996,-0.020917188,-0.01200314,0.047688667,0.012457569,-0.00024242519,-0.037210334,0.11271195,-0.016474728,0.07342061,0.07369612,-0.06612424,0.035393685,-0.13421004,0.051467787,-0.11176013,0.00407632,0.022042241,-4.4366175e-08,0.038605917,0.0042112865,-0.0950424,0.042553138,0.027623098,0.0820824,-0.0041180523,0.03883647,-0.02232196,0.11755941,0.033945106,-0.030039718,-0.04414245,-0.011809953,0.008340783,0.019666936,0.023130298,-0.003107979,-0.039937984,-0.016975895,-0.014358826,0.05617128,-0.041125465,0.026839744,-0.0016187195,-0.017786171,0.03683966,0.10491105,0.014962031,-0.053605843,-0.0897005,-0.027616106,-0.04157701,-0.01157794,-0.122953996,0.14238173,-0.06326212,0.00026903267,0.062317465,0.0082146125,0.0065732063,-0.0044807214,0.012566765,0.019865314,-0.034794018,-0.036045432,-0.015471483,-0.03613397,0.06292929,-0.018424707,-0.021383677,-0.034286678,-0.040912185,0.017632399,0.06440187,0.0053783087,-0.043792605,0.0057871616,0.06478032,0.0995301,-0.03326604,0.00744188,-0.03377564,-0.023297317}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:09.94707+05:30	2026-10-12 18:54:47.102384+05:30
32	32	{-0.017707761,0.06283551,-0.029467689,-0.10093958,0.04145596,-0.037621647,-0.0047634724,0.009643662,-0.010161079,-0.025101965,-0.017780092,0.025745764,0.03932892,-0.06406838,0.06701929,-0.04303119,0.084780924,-0.08409109,0.02810594,0.030753791,0.060595993,0.037094142,-0.04187403,-0.046005953,0.11559576,0.04468777,0.08153965,0.025492663,-0.06695085,-0.040682007,0.08948062,0.027704816,0.030213403,-0.037342966,0.0061305086,-0.011614158,0.04333185,0.056968085,-0.075076126,0.0337577,-0.021042276,-0.013615229,-0.016990544,-0.01360344,-0.02011192,-0.056367908,-0.041795354,0.024813507,-0.027230496,0.022131542,0.06534617,-0.056174688,-0.007684024,0.087004095,-0.06360649,-0.045542102,-0.034470133,0.021931622,0.046309017,-0.014819661,0.08933453,0.013752039,0.06732257,0.045967244,-0.03399328,-0.06770147,0.04931123,-0.020321839,-0.0053959317,-0.048587948,-0.012079508,-0.006542044,0.023909442,0.06891449,0.018520955,-0.006981696,0.10999757,0.033201993,0.02133536,0.051557213,-0.00040830264,-0.004028223,-0.011781457,0.025159972,-0.037494436,-0.015047964,-0.06748021,0.05523041,0.0037107894,-0.10311687,0.009385406,0.06444641,0.057452634,-0.0011066439,0.033522975,-0.008470862,-0.027020294,-0.0786972,-0.09565183,0.05933863,0.04620791,-0.07113485,-0.0010784084,-0.0029148748,0.0048408885,-0.05611781,-0.00082848134,-0.013553294,0.04314078,-0.015122428,-0.044909872,0.001115192,0.0077782962,-0.0003041397,-0.05189445,0.07433874,-0.07041046,0.028218677,0.028072458,0.03510788,-0.029715326,-0.057108838,-0.018351799,-0.03510328,0.03727219,0.02954367,-0.0076890416,5.022103e-33,0.032827385,0.02583808,-0.06417606,-0.007141806,0.075835735,-0.043835875,0.036593508,-0.0035959503,-0.015765408,-0.025432589,-0.11302578,-0.021195851,0.013321824,0.0026717968,0.040251456,-0.04952109,0.008756923,-0.07057967,0.0834275,-0.00035129767,-0.027666667,-0.11877297,0.0862831,-0.0007375595,0.11130713,0.08658052,0.019237816,-0.049521137,0.10576411,0.04247163,0.0386913,-0.066242844,0.056273554,0.015166541,-0.065671764,0.0018062444,-0.090294614,-0.06545169,-0.014615298,-0.09212398,-0.048990704,0.0027906632,-0.089451455,-0.022543306,-0.019924581,-0.07401822,0.015205737,0.020176746,-0.012261705,0.057159342,-0.0709632,0.00015578647,-0.068454705,-0.052313488,-0.048289835,0.024324434,-0.009685389,0.04596733,-0.0034587109,0.0032958572,-0.01027176,-0.017079998,0.0449822,-0.02821522,0.08731517,-0.038583506,0.021280812,-0.056952447,0.0103171645,0.029939381,-0.01605885,0.04095459,0.08577505,0.034360904,-0.051706553,-0.032921813,-0.050534315,0.014924463,0.0027528158,0.021592528,-0.008021858,-0.00063729467,0.06150347,0.041126955,0.01086044,0.0046668225,-0.029068347,-0.0336932,-0.09094722,0.14185062,-0.0047779316,0.0028248485,0.017785868,-0.0256444,0.023465315,-3.4833622e-33,-0.07535013,0.0022060387,-0.04606601,0.05670561,0.023510518,-0.036047116,0.0024147427,0.08645474,-0.04698071,0.09748277,-0.021475513,-0.024768598,0.01929304,-0.061490588,0.10446338,-0.10120521,0.047369353,-0.09499929,-0.036538985,-0.028542325,0.0187788,-0.0030356017,-0.015144754,-0.10063962,-0.022086553,0.026711943,-0.011338622,0.036687713,-0.073661745,0.025380906,-0.0736037,-0.040921982,0.034027457,-0.014541783,0.061259788,0.0044443994,0.053138096,0.06287929,-0.05095574,-0.077260844,0.08571559,0.00081538304,-0.07018215,0.04453262,0.008351351,-0.080454044,-0.024051804,0.044585176,-0.014874564,-0.019219387,0.05638335,-0.05405629,0.0432238,0.06065169,0.008023281,0.04958435,0.047816474,0.04489587,-0.11449858,-0.017058784,0.042788345,-0.037075922,-0.0138786,0.1364031,0.10333323,0.038630858,-0.043152027,-0.007913016,-0.045582235,0.036812544,0.016200783,-0.05002001,-0.048451677,0.0035749932,0.014393732,-0.011363199,-0.044183314,0.06625228,-0.047897965,-0.02183541,-0.0017527121,0.04002261,-0.05023531,0.020765053,0.15587936,-0.0215416,0.053846236,0.03203495,0.04867167,0.021822885,-0.10155798,0.066270076,-0.027536904,0.04319652,-0.0062173023,-3.9013262e-08,-0.082753785,-0.027278477,-0.053661954,-0.005162787,0.012654431,0.008028291,0.07650006,-0.047805615,0.04533459,0.0049518174,-0.051207572,0.021360839,-0.063450605,-0.036322467,0.08150258,-0.0036499863,0.03757467,-0.027824879,-0.014786147,-0.0012282504,0.07083408,-0.02330158,-0.036804643,0.08261351,0.0861716,0.02403842,0.009524974,0.06044343,0.10221514,-0.019832458,-0.09590504,-0.035793882,0.031938523,0.021405254,-0.08693459,0.072712526,0.021108849,-0.027559055,0.042712364,0.07381037,0.0076246266,-0.019428376,-0.01856249,-0.046857253,-0.008837226,0.0141556,-0.059030864,0.012152075,0.02713185,-0.03281617,-0.10708472,-0.072092034,0.0049170717,-0.024357382,0.032255374,-0.06241998,0.05926154,-0.1343485,0.117344536,0.081878915,0.08525528,0.024221981,-0.04195058,0.0062726717}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:14.383224+05:30	2026-10-12 18:54:47.214271+05:30
34	34	{-0.0689427,-0.0019373551,-0.040240783,0.02808059,-0.016057821,-0.101541124,0.018663635,0.0010655234,-0.064568855,-0.019534418,-0.061273284,-0.0051176026,0.014849275,-0.087618515,-0.026885984,0.010665188,0.10334108,-0.04638825,-0.08405131,-0.12615405,-0.04752166,-0.009245462,-0.056045786,0.03367478,0.014353114,0.034962542,-0.02291682,-0.102161154,-0.05292955,-0.121563315,-0.030555151,-0.04817618,0.002389121,0.04991965,0.02208264,0.114121005,0.04790951,-0.074241914,-0.013420214,-0.067021124,0.11382387,-0.040019825,-0.06832238,0.0256603,0.0036226884,-0.036992557,-0.0900485,-0.026422748,-0.00568951,0.011648544,-0.09491075,-0.057697438,-0.038442053,0.086587965,3.938426e-05,0.034925416,0.055551786,6.9832895e-06,-0.05150961,0.021647917,0.0067132115,-0.052428536,0.03922943,0.0025704626,0.01416271,-0.002350738,0.00054316246,0.06021497,0.034758408,-0.038659025,0.028374268,0.07532128,-0.07836651,0.04748177,-0.08829291,0.016841473,-0.014007177,-0.030367184,-0.02169869,-0.025067247,-0.07612405,0.029986598,-0.008959018,-0.036057234,-0.03421387,-0.012467559,-0.033849057,0.04488676,-0.03672677,-0.02860684,-0.01208719,0.050208624,0.08968147,-0.012155692,-0.03646393,0.03451546,-0.03533777,-0.013473245,0.086761355,-0.0060998662,-0.007685006,0.113449834,0.07934855,0.028516617,-0.04647904,-0.09276663,-0.049052153,0.03827316,-0.021248514,-0.037715103,0.029931076,0.016490905,0.091235556,-0.06098696,-0.0032187314,0.01991495,-0.048483025,-0.05084626,-0.05492329,0.04231176,0.05347399,0.01643282,-0.049983054,-0.026651662,0.056863487,0.011965222,6.6782566e-05,5.8752442e-33,-0.035207167,2.2482163e-05,0.07773315,-0.018094119,0.03741869,-0.0018191102,-0.0034451159,-0.024060681,-0.091011785,0.008416832,-0.051194333,0.044496763,-0.03850674,0.06311114,0.009757905,-0.12207669,0.052734908,0.123146735,0.012762342,-0.026350696,0.048420765,-0.041442264,-0.062257707,0.06061381,0.048273206,-0.00838334,0.032391317,0.024353713,0.066881396,0.01607049,0.0034120583,0.026487919,-0.026159968,0.049173083,-0.0062217,-0.041152716,-0.07883701,-0.05282907,0.012645633,-0.018152623,-0.01773044,0.06357883,-0.07263352,0.008003554,-0.10762044,0.025741614,-0.014121184,-0.016676575,0.058428787,-0.014694542,0.04093501,-0.022841224,0.10274917,0.04781801,0.031643335,0.014610156,0.039204758,-0.024363223,0.045760814,0.09425347,-0.012294985,0.031373017,-0.045281406,0.047118023,0.046855744,-0.005133197,0.061738964,0.06309463,0.032342587,0.034967154,0.0013958564,0.04613968,0.04762541,0.012359507,0.07264654,-0.09441459,0.031719152,-0.0009939189,-0.050058324,-0.056940746,-0.05161955,-0.02639388,-0.028813655,0.022505274,-0.02023074,-0.010340717,-0.059920512,0.071569964,-0.005195545,0.04697095,-0.050665345,0.008280563,0.035930447,-0.04362229,-0.06955769,-4.642137e-33,0.014130667,-0.045276266,-0.043650318,0.10019872,0.07295311,-0.020755216,-0.027453082,0.02024272,-0.0034931041,-0.015844727,-0.073603176,-0.045145832,-0.0044820397,-0.03239717,-0.03162977,-0.03387859,0.05591938,-0.07518353,-0.08394363,0.012489208,-0.051886052,0.016205981,-0.029850043,0.0599892,-0.013291396,0.034809515,-0.108990856,0.0010203075,-0.007393241,-0.032157015,-0.021717912,0.00821063,0.0053950273,-0.040285844,-0.02725318,-0.031300355,0.09873749,0.08748557,0.016744234,-0.03395324,0.0046557663,0.033413548,-0.057894845,0.013772833,0.0040623844,0.078384906,-0.056762952,0.028820196,-0.04119382,0.031086586,-0.06288286,0.036013197,-0.011759536,0.028559137,0.037828084,-0.07838448,0.0034518482,-0.045393597,-0.12686878,-0.00958575,-0.039922882,-0.018227456,0.07851386,0.018520534,0.060367666,-0.024330981,0.073047906,-0.02019261,-0.028765842,-0.038251035,0.105888,0.027396595,-0.0045781774,0.09978412,-0.02886168,-0.055970125,-0.025933344,-0.09318733,0.01481684,0.10744537,0.0097680865,0.06882772,0.045521557,0.08440912,0.09178296,0.06141002,0.02088172,-0.010597446,0.017088205,0.052041862,-0.08939112,-0.007575322,-0.0883704,0.061763063,0.0007809029,-3.993706e-08,-0.01611668,0.038901277,-0.054222535,0.049907085,0.04299625,-0.029129816,-0.008506634,0.12145723,0.05585732,-0.008164019,0.020520601,-0.062034253,-0.029344078,-0.06908254,0.0994084,-0.041286666,0.046365354,-0.027423272,-0.015313834,0.010822355,0.030233802,0.07815516,-0.027579078,-0.0063457787,0.083332896,-0.031973023,0.097111896,0.074048676,0.037255835,-0.052132368,0.00979313,-0.029997021,0.013314305,0.012810465,0.060099702,-0.020504305,0.0610537,0.062073674,0.007165832,-0.014127006,0.02470661,0.025436271,-0.032134186,-0.0011030241,-0.058079008,-0.0048241364,-0.0980697,0.03854459,0.04370525,0.012455069,-0.01805722,-0.06939684,0.027783796,0.09470278,0.039551534,0.01065013,0.02510025,-0.042882834,0.08394789,0.05851198,0.13714637,-0.06736274,0.047788396,0.04759555}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:17.011954+05:30	2026-10-12 18:54:47.315202+05:30
36	36	{-0.040840082,-0.031575833,-0.022211878,-0.021875821,-0.0694024,-0.0006910758,0.027768077,0.05006257,-0.018050449,0.043123454,-0.043783966,0.026351027,0.083449475,0.023863077,-0.0010186362,0.044406097,-0.028927615,-0.050753858,0.06631023,-0.1348402,-0.00045535516,0.026825387,0.06512875,-0.011634174,0.017122807,0.022845292,-0.07241117,0.04092859,0.025104001,0.01153492,0.040424135,0.029231014,0.0014080153,-0.061166223,-0.032062665,0.052315127,-0.14891186,-0.05023304,-0.082474254,-0.00040767025,-0.19872062,0.044444166,-0.019687753,0.0006472241,0.03684954,-0.016201694,-0.04144872,-0.024941286,-0.008483412,-0.045966733,-0.09171775,-0.097950354,0.0016449637,-0.02799579,0.01466973,0.048781488,-0.0030736544,0.023343356,-0.0042542107,-0.062467776,-0.023819504,-0.017253293,0.01324165,0.048522476,-0.028990323,-0.007568122,-0.041340787,0.12802191,0.020456055,-0.054298542,-0.05455747,0.010923831,-0.023323318,-0.0018338095,0.08861395,-0.002012254,-0.005493584,-0.007874433,0.067599915,0.0148443375,-0.04422811,-0.047282603,-0.04819176,0.060881108,0.04269524,-0.079183936,0.059063647,0.09119543,0.032081015,-0.023238536,0.07631242,-0.029210355,0.01248754,0.00029175077,-0.0052218945,0.028213937,-0.06362153,-0.08703891,-0.04386475,0.01528729,-0.0030843054,0.06177406,0.014061395,-0.059633013,-0.05355965,-0.012137436,0.09101026,0.06304901,0.08063318,-0.08214472,-0.023019245,0.047994968,-0.015825395,-0.01943385,-0.04401194,0.07872991,0.06751536,0.013085187,-0.021269253,0.07624328,0.042471904,0.0019203564,-0.03665538,-0.037374277,0.042846512,-0.050995257,-0.06670258,1.8942697e-33,0.0812842,0.009659633,0.04537917,-0.061127182,0.107046306,-0.0479533,0.060102675,0.023107277,-0.14091736,-0.021011725,0.033692013,0.056723032,-0.015469534,0.09511472,0.09359383,-0.05917061,-0.15355706,0.028475057,0.0006065613,-0.002127441,0.04652615,-0.069757104,-0.019105941,-0.014363574,0.05808578,0.08598265,0.016158132,0.104127385,0.07086488,-0.005824704,-0.04487292,-0.004881035,-0.13327818,-0.017106513,-0.030744161,-0.0023208302,-0.043693084,0.011664871,0.018520666,-0.0037131254,0.021745302,0.0047628544,0.039201435,0.03627877,0.030337723,0.009253547,0.021477098,-0.061669525,-0.019503552,-0.015394357,-0.031443052,-0.038339898,0.0011826952,-0.028000835,-0.009378913,0.037186194,0.053110126,0.072141916,-0.04820997,-0.003960632,0.044634085,-0.012515802,-0.0056923963,-0.030271918,0.020846253,0.03267579,-0.0023859425,-0.0023003009,0.1095053,0.01779182,-0.011010197,0.028831802,0.06945161,0.016717201,0.044267554,-0.046314646,-0.06010203,-0.08871826,-0.050725732,-0.03727872,0.02154316,-0.067300364,-0.05018054,0.005500404,0.060311213,-0.028142894,0.029065106,-0.039527845,-0.021578187,0.046647303,-0.0064405994,-0.02767736,0.019846946,0.108584285,-0.02881879,-2.3499675e-33,-0.027692743,-0.03327906,0.015175882,0.04189503,0.064205065,-0.03887767,-0.021016765,0.01154419,0.06341733,-0.04815277,-0.06771189,-9.279446e-05,-0.010155168,0.04929645,-0.010603569,0.039801948,-0.07827126,-0.044359468,-0.041334424,-0.0038890643,-0.00937272,0.05992298,-0.070681676,-0.034962084,0.02770919,-0.0011730493,0.047509823,0.07218803,0.047301836,0.014675582,-0.054925688,-0.16426685,-0.045198288,-0.020037515,0.041663323,0.027998343,0.052873928,-0.02431634,-0.060138322,0.11384071,0.08529529,-0.07003755,-0.019172462,-0.002207572,-0.005002585,0.06803913,-0.08032749,0.025923358,-0.0059089065,0.033040076,-0.04034432,0.045683295,-0.0028943243,-0.058395978,0.006420526,0.025841936,-0.044207115,0.063105635,0.03994779,0.047649592,-0.018584842,-0.0634211,0.042209025,0.06428781,0.016232125,-0.040074375,-0.021037348,0.08103463,-0.025731493,-0.0356447,0.02836728,0.027224548,0.0027781422,-0.014815077,0.0873733,0.001336648,-0.06298808,-0.010827293,-0.03685445,-0.06276553,0.03863433,0.0066575394,-0.0064030043,0.04402238,0.049939204,0.03562553,0.08728552,0.067793004,-0.036485363,-0.06271073,-0.032181196,0.09605146,0.05037408,-0.038172916,-0.1007106,-3.8041e-08,-0.0055296845,-0.08894361,0.014331134,0.024712754,0.092156924,0.029609801,0.024372898,0.0507225,-0.03899366,0.07992061,0.10253126,0.05185968,-0.0068803555,-0.015185379,0.027695777,0.049186055,0.01646773,-0.014066146,-0.020769749,-0.06891939,0.074095026,0.039410826,-0.00562271,-0.0071902145,-0.09989014,-0.036171835,0.07298483,0.07010595,0.019663306,-0.02174533,0.014694368,0.016361432,0.060731865,-0.029470636,0.037151113,-0.0047232467,0.030583002,-0.06869127,0.01878167,-0.06730184,-0.015637612,-0.058489665,0.039997246,-0.010653999,-0.008606522,-0.014213349,-0.035294924,-0.06769794,0.06768706,-0.05064607,0.036433082,-0.0033400715,-0.07176354,-0.057544284,0.12568265,0.023159623,-0.009527625,-0.021268282,0.03805825,0.050307434,0.014553666,0.00013451405,-0.0020339368,0.06900211}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:19.679182+05:30	2026-10-12 18:54:47.417513+05:30
1	1	{-0.045350604,-0.0055370363,-0.019374486,-0.01588352,0.040266003,-0.064070374,0.004046301,-0.002147628,0.0062181344,-0.04111032,-0.033176105,-0.033589788,0.03601213,-0.051491223,-0.05016496,-0.020639714,0.013963726,-0.021810977,-0.023637557,-0.05935293,0.042396426,0.005593366,0.007540281,-0.02612164,0.048880965,0.0004232226,0.08806475,0.024935871,0.009781861,-0.025807412,0.028431257,0.060198247,0.07206743,0.0052499725,-0.044899654,0.08105437,-0.08804175,-0.002019173,-0.05749927,-0.04588329,0.0067863935,-0.09339906,0.023069285,-0.04280504,0.052700024,0.0099471975,-0.032310292,0.0014829835,0.03222433,0.050999586,-0.14177151,-0.0015671949,0.011459425,0.03513153,-0.022717759,0.072446726,0.009486196,-0.0051699514,-0.0004862957,-0.10207757,0.057537895,-0.039118268,0.048117597,0.015846599,0.080132514,0.11887071,-0.025607662,0.060532156,-0.026914466,-0.064020656,-0.017036485,0.02596745,-0.03944034,0.04933125,0.011967383,0.13049197,0.038645778,0.034439128,0.034191865,-0.045346655,-0.0582878,-0.033922125,-0.02684312,0.017399225,-0.06546463,-0.007151184,0.024576072,0.048632436,0.06626477,0.051727872,0.064986214,0.01408964,0.089677714,-0.078897685,-0.011051994,0.0049520466,-0.05952589,-0.09266826,-0.021337505,0.061064787,-0.0058887987,0.10769676,0.038683858,-0.062270038,0.020563344,-0.040340915,0.06158806,0.0001764305,0.10821921,-0.038003854,0.00031299205,0.040544994,0.02194919,-0.08773869,0.040701713,0.06220713,-0.013692247,0.020825578,0.059143685,0.0641328,0.007446212,0.049995027,-0.06645529,0.023344139,0.027807059,-0.03744468,-0.18698384,2.6445482e-33,-0.037261847,0.007954917,0.081094615,-0.060116958,-0.010256881,-0.057591476,-0.047593143,0.050727043,-0.122398205,0.09017097,-0.026990108,0.022343868,-0.057137705,0.0049990183,0.007670972,-0.006482111,-0.060599953,0.026729057,0.03549816,0.016488954,0.026232213,-0.04390979,0.02325316,-0.032188512,0.08784121,-0.035209548,0.004761446,-0.009561108,0.12231739,-0.006804163,-0.05485903,-0.04896384,-0.00047470955,-0.0065037683,0.017672801,-0.022137187,-0.06839437,-0.066325925,-0.0068635545,-0.0069959112,-0.01792443,-0.035932522,0.035064008,-0.0014331245,-0.053783752,0.022985224,-0.03824415,-0.083095774,-0.019809842,0.08144579,0.007753514,0.02339432,-0.021920467,-0.046588797,-0.09107428,-0.024872763,-0.034684923,0.012629021,-0.066035405,-0.040291112,-0.010944502,-0.06336469,-0.022405494,0.05359562,-0.070408344,0.061911047,-0.011433863,0.05026612,0.055486385,0.03467234,-0.08974734,0.015291758,0.0015081934,0.046198215,-0.00094801525,-0.07659932,-0.0037408008,-0.00029349112,0.038903967,0.005409367,-0.052586004,0.01445023,0.008219053,0.070084535,-0.0338404,0.058639947,0.0461021,-0.05776324,0.0030076567,-0.097963974,-0.11605383,-0.016426694,-0.027448528,0.022085588,0.033214826,-4.2187302e-33,-0.0634735,-0.025189037,-0.062135585,0.012472991,-0.017165704,-0.0017599829,-0.06072839,-0.009570807,0.06561367,0.03151444,0.027762804,-0.018809412,0.099980906,-0.058340773,-0.015308236,0.007744418,-0.021725005,-0.017302338,0.024960518,0.034585465,-0.012938127,0.10234328,0.019395297,-0.016046777,-0.030020276,0.027412614,-0.035444546,0.06459203,0.011745913,0.02815133,-0.055791564,0.025037615,-0.029425105,0.043485038,-0.05055933,-0.0066259475,0.008347723,-0.029529907,-0.014930845,0.044686638,0.09728769,-0.015134489,-0.06092593,-0.07034435,-0.060767196,0.027242623,0.031209368,0.049571123,0.059999954,-0.0018860748,-0.00576095,0.068470426,-0.040243726,0.06537119,-0.046344835,0.04465579,0.106647246,0.012051504,0.010901803,0.043056898,-0.1041207,0.023559257,0.065455064,0.03966573,0.041722257,-0.048504706,0.02954738,0.019900344,-0.05980513,-0.10811727,0.101177886,-0.04185954,-0.015456533,0.062357537,0.050746504,0.05554766,-0.066512935,-0.044101425,-0.074378856,-0.054066867,0.026151106,0.021020178,0.086062126,0.11905142,0.06340957,-0.049760126,0.06612617,0.013517095,0.047288552,0.038326193,-0.09485183,0.06486924,-0.042817354,0.048659246,-0.11408672,-3.7574427e-08,-0.032169733,0.041357767,-0.04809995,0.023383167,0.07567074,-0.002021555,-0.04819566,0.0076732473,-0.06266602,-0.04535494,0.03417648,-0.043199446,-0.10119887,-0.04382117,-0.017931646,0.026539952,-0.004918606,-0.01115234,-0.02731909,0.009416585,0.011362535,-0.036717538,-0.00043232256,0.019724028,0.017402805,-0.06446852,-0.016422905,0.091726765,0.030095853,0.03258648,-0.041446928,0.039122302,0.041331906,-0.042843387,0.02136402,0.13374189,0.03388371,-0.033362303,-0.01456895,0.06308615,-0.04153318,-0.039226606,-0.079770625,-0.063225284,0.024697904,0.0079067135,-0.01902744,-0.11526393,0.10114099,-0.006878416,-0.014688161,-0.017037164,0.044596486,0.027313692,0.11463285,-0.033691734,-0.0051536644,-0.014926657,0.042830743,0.004766706,0.10070741,0.05285876,0.03410088,-0.037878964}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:14:43.216455+05:30	2026-10-12 18:54:45.287495+05:30
3	3	{-0.06989802,0.06377846,-0.106710896,-0.026160445,0.07017115,0.016493771,0.042992976,0.042195946,-0.04637271,-0.0013666793,-0.018324185,-0.014957097,0.07904866,0.0013678174,-0.01638233,0.0066354154,-0.015790863,-0.01027519,0.06527733,-0.04911089,-0.012440449,0.06808148,-0.09028296,0.012198954,-0.056861486,0.01370187,-0.002403155,-0.028728941,-0.111654356,-0.014496977,-0.022089519,0.0014735231,-0.0063666333,0.05988019,0.013682113,0.043960948,0.047458667,0.011815528,0.013335012,-0.038932618,-0.006341764,0.0077195032,-0.036192503,-0.021990582,-0.05993279,-0.07301245,-0.07941132,-0.061098047,-0.055801336,-0.08442234,0.018661061,-0.04034743,0.012439026,0.020395327,0.028795138,-0.028212061,-0.003908169,-0.049144242,0.0794685,0.0064435657,0.04570421,0.0469093,-0.0080678575,0.050320733,0.036372624,0.009283723,0.029665574,0.053243,0.058480456,-0.017935166,-0.13390246,-0.008437893,-0.044787064,0.02884632,0.05109797,0.039795805,-0.04070565,-0.013213955,0.011989115,-0.16437717,-0.034243755,-0.032160398,-0.04922387,0.067889236,0.027355231,0.055454686,0.025770193,0.0028592406,0.11508206,0.05842548,0.07867633,-0.031129422,0.10086841,0.008835001,0.0024585354,-0.035024565,0.013416137,-0.04897147,-0.06493575,0.06445634,0.018581035,-0.037771404,0.011189129,-0.077885464,0.059785742,0.020568963,0.059496377,-0.08159785,0.033700842,-0.020130886,-0.037192896,0.014126063,-0.054005004,-0.14341086,-0.039099082,0.055506896,-0.04577273,0.02281578,-0.0068142605,0.05671563,0.12726142,0.03508187,-0.0005769818,-0.012234989,0.07049267,0.023907242,-0.012007047,3.5891883e-33,0.0006033272,0.028284172,-0.0516034,-0.0021598465,0.021091897,-0.04908908,0.051039472,0.048416983,-0.09624912,0.064959586,-0.02812021,-0.0037739621,0.0015225663,0.046668172,0.020979255,0.008663121,-0.008122913,-0.012751302,0.062273927,0.014215191,-0.052293308,-0.061294757,0.023174262,0.0106787095,0.10301576,-0.058480773,-0.023771351,0.023340687,0.08158684,0.04297323,0.0042792964,0.039612878,0.007708993,-0.0011801651,0.020985426,0.007484099,-0.006516592,-0.07677074,0.01210344,-0.044012405,-0.013015834,-0.057611965,-0.0015503636,0.021512263,0.052540816,-0.019517746,-0.07662008,-0.011814666,0.07125623,-0.020309523,-0.07363942,0.032940563,0.048328053,0.054857865,-0.060930856,-0.014659222,0.0029820064,-0.020607444,0.0226947,0.093035616,-0.020635774,0.013564858,-0.035537995,-0.025749825,0.032274842,-0.016671179,-0.0173605,0.027127018,0.019764578,0.032569014,-0.12292417,0.03139969,0.06669812,0.047844354,-0.041826155,-0.056947265,0.03535426,0.06262691,0.008546315,-0.051413666,-0.051777575,-0.03152445,0.098316684,0.013775505,-0.023644047,-0.05559301,-0.05137398,-0.005088665,-0.04359171,-0.026361173,0.021830913,-0.100815244,0.057164524,0.046958186,-0.02977973,-5.542957e-33,-0.068682045,0.000698488,0.012224828,0.053573776,-0.045191232,-0.016628493,-0.044363342,0.010653053,-0.044226702,0.052500825,-0.0044393116,-0.005385818,0.046864998,-0.0897893,0.06950495,0.030600408,-0.093025014,-0.056913614,0.01160642,0.030878626,0.029111883,0.0898162,0.009926562,0.011238815,-0.015073565,0.01931376,-0.008464974,0.024443515,0.03170876,0.0980116,0.042492814,0.02840919,-0.04204855,0.024923034,-0.045194604,-0.085514836,0.06698809,0.004329147,-0.020364383,-0.0033386932,0.08610298,0.054421727,0.0035853228,-0.030232735,-0.030720778,0.039597597,-0.0019839965,0.11416967,0.004742062,-0.053541478,-0.029970154,0.023236709,0.02141485,-0.03959613,-0.003044956,0.037008304,-0.010614136,0.053969923,-0.035592347,0.06907707,0.042683546,0.017232459,0.022224888,-0.003451772,0.027244175,-0.022421781,-0.087173976,0.051637933,-0.054499745,-0.08126598,0.056929536,-0.02035936,-0.049456958,-0.023791574,-0.028394729,-0.09027015,-0.0282336,-0.12263036,-0.06358536,0.14556804,0.07009101,0.0048311725,-0.035695862,0.018929437,0.008167354,0.010893325,0.012864586,-0.002240138,0.055043384,-0.015701324,-0.1582783,0.022197917,-0.031079398,0.032232136,0.023210192,-4.4883485e-08,0.08080028,-0.020231081,-0.014486447,-0.058975615,0.029200915,-0.013139189,-0.034438357,-0.063955314,-0.06174291,-0.07377875,0.024028482,-0.101166345,-0.065902784,-0.07927835,-0.03600398,-0.026870307,-0.09419122,0.10249233,-0.069469534,-0.011835265,0.04517928,-0.012270483,-0.0004254544,0.0034346022,-0.018125758,-0.016118558,0.04926314,0.0874505,0.04295325,0.012074967,-0.012203314,-0.018726993,0.06522776,0.040464856,-0.013695892,0.11857883,-0.0544274,-0.07815606,0.09046292,0.096796684,-0.042152025,-0.021616008,0.012626571,0.032485966,-0.062377546,-0.035703428,-0.003604484,-0.013794674,0.099294275,-0.07972777,0.023655295,-0.03669395,-0.0219265,0.10296682,0.059732705,0.045635596,-0.024053933,-0.050712682,0.08776474,0.05068948,-0.015143959,-0.09522317,0.0758522,0.036838345}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:14:57.443762+05:30	2026-10-12 18:54:45.418893+05:30
38	38	{-0.05122179,-0.09164161,0.0043910886,-0.05426449,0.00043791774,0.020445146,-0.045596905,-0.0893871,0.021644687,-0.16417271,-0.04057324,-0.082070544,-0.057452798,-0.009145762,-0.040641516,-0.017787103,0.046114583,0.113111176,-0.022567293,-0.07935331,0.06973535,0.07028885,0.07636247,0.02468577,0.11641407,0.065515324,-0.025623012,0.00095124403,0.03742308,-0.046556417,0.052061,0.039425712,0.026198316,0.010749283,-0.008546339,0.04293148,-0.0425666,0.022663133,-0.0006641058,0.0051193316,0.020209676,0.048671376,0.06151031,-0.068802625,0.027461788,0.032847177,-0.036457468,0.020332146,0.018993566,0.022950225,-0.11567166,-0.063099,0.002947835,0.09888686,-0.04549952,0.021096032,0.09270598,-0.0055603823,0.029273825,0.038025945,-0.052176893,0.02800805,0.05585084,0.040562835,0.047052283,-0.0330252,-0.0053399997,0.023122748,-0.010312853,-0.010208298,-0.059897497,0.057471868,0.040730305,0.05643111,-0.0042073173,-0.001696168,0.0144924335,-0.027833957,0.023438117,-0.036990702,0.05362602,-0.06914391,0.13160089,-0.053391244,-0.014731557,-0.028338542,0.034313373,-0.021531045,0.003357391,-0.0118815685,-0.101068586,-0.0018978176,0.06562817,-0.0011223195,-0.016015697,0.0035400626,-0.015234672,-0.017925907,-0.024132986,0.022057932,-0.015969627,-0.034648884,0.015505893,-0.06676233,-0.041057777,-0.0670849,0.06349385,0.006245843,0.058572076,-0.025707604,0.03286916,-0.027095854,-0.0100639155,-0.07086005,0.04939618,0.053452913,-0.05222529,-0.002747086,-0.008886146,-0.023989735,-0.103892386,0.015489034,-0.025741091,-0.012338439,0.0092682,-0.006555032,0.0030884389,2.7423736e-33,0.06044075,0.01782125,0.01915176,0.015573945,0.04957924,-0.066385,-0.04672888,-0.03303727,-0.07013266,-0.06574215,0.03466433,-0.038815867,-0.0702532,0.051816512,-0.029991373,-0.05637901,-0.05961193,0.026717074,0.014765286,0.023805862,0.04923514,0.060319245,0.06277928,0.05214586,0.0071047787,0.0060053677,0.040577564,-0.08850701,0.07563614,0.030475378,-0.08843274,-0.0067568533,-0.026207462,-0.050806172,0.016980356,-0.060594395,-0.029685732,-0.04777718,-0.07104809,0.030573968,0.0014053972,-0.0035489658,-0.13280295,-0.09513079,-0.049682144,-0.011973055,-0.013784425,0.094191045,9.029373e-05,0.06334205,-0.025350776,0.031086644,-0.025502073,-0.0402272,0.016704213,0.024559379,0.11188016,-0.021312376,0.07531035,-0.06530567,-0.008247537,-0.0070329783,0.014997607,-0.018881066,0.001692923,-0.011830032,0.09704827,-0.012488347,0.094468884,-0.027457539,-0.042419545,-0.017911155,0.021738034,0.070581265,-0.052575868,0.0920293,-0.025134658,-0.04720856,0.047903232,0.05289821,-0.04284155,-0.01762684,-0.03096742,-0.02657365,0.06522822,-0.012682549,-0.029632838,-0.07982677,0.0022846183,0.0609113,-0.03295017,0.0021659655,-0.024696376,-0.015787845,-0.0049130484,-1.3754315e-33,0.031565536,0.03561824,-0.022572536,0.1070955,0.0030231574,-0.056026764,0.04233444,0.06496432,0.09060821,-0.019996142,-0.02554688,-0.071393706,0.04249851,-0.008018813,-0.04218268,-0.022286195,0.103345565,0.0050764354,0.0019849343,0.020659976,-0.006097644,-0.00181204,-0.028397262,0.02217159,-0.03959041,0.061696295,-0.03770561,0.052827664,0.058627937,-0.02741059,0.027474778,-0.053695284,-0.027109351,0.017293477,-0.08196547,0.13089997,0.061557572,0.010505414,-0.011810603,0.0033390366,0.045750547,0.030557139,-0.0787413,-0.07767832,-0.01089442,-0.006676455,-0.10667831,0.06808482,-0.08942639,-0.042849556,0.029251017,0.0686276,-0.010868814,-0.041041065,-0.04526671,-0.05695954,0.0032808823,-0.009410869,0.018063372,-0.044492763,-0.05411893,-0.07103117,0.06300384,-0.10577724,-0.026946869,0.09840577,0.067691244,0.007875077,0.07207318,-0.057646386,0.079281956,-0.04696748,0.0059088822,0.084503844,-0.041607894,0.029602073,-0.042117275,-0.003543072,0.037570693,-0.05697251,-0.013420404,-0.047148637,0.002634749,0.025644502,0.12155463,0.10153881,0.028714808,0.040376186,0.06991043,0.08000444,-0.0059745503,0.13834713,-0.05216848,0.008613184,-0.0147455,-3.228281e-08,-0.061223347,-0.04905843,0.022084298,0.031863414,-0.03388784,-0.08863597,0.053620137,-0.0044854623,0.037350796,-0.080796316,0.029761052,-0.012878859,0.033993073,0.020100689,-0.027641749,0.04309843,0.011120142,0.11465833,-0.02557253,-0.035952125,-0.0037795797,0.05315986,0.07940604,-0.0098500755,-0.033427548,-0.024208143,-0.023067301,0.042557716,0.013418492,-0.11909206,-0.013521342,0.09780776,0.01263875,-0.056156978,-0.0037823229,-0.01383205,-0.022812126,-0.002608581,-0.036513567,0.049556717,0.03263773,0.029304998,-0.035153873,-0.014460899,0.023656646,0.021082649,0.004729989,-0.12438805,-0.016952492,-0.029758438,-0.026999101,0.02170275,-0.0057062632,0.120730214,0.066352785,0.05437427,0.013383887,-0.012455431,0.04040304,0.09940254,-0.05232547,0.0078992555,0.07810611,-0.03293314}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:31.488983+05:30	2026-10-12 18:54:47.515546+05:30
5	5	{-0.020582924,0.06700456,-0.009148232,-0.04278673,-0.06182635,-0.02672573,0.0044677574,-0.00359477,0.049778935,0.027283728,-0.08564514,-0.008387364,-0.034442917,0.02696601,-0.020586668,0.046085503,-0.05059226,-0.0760645,-0.003741421,-0.04210861,-0.00036059032,0.054080676,0.027265117,-0.0050389883,0.009914805,-0.033522666,-0.040622346,-0.064072736,0.04293188,-0.047624785,0.06362319,0.06575419,0.0069428734,0.05433181,0.03078892,0.02553109,-0.00016477314,0.024101047,-0.025865352,-0.022888046,-0.029837677,-0.01249258,-0.08060529,0.0054196417,0.079424836,-0.101647146,-0.06725347,-0.011256741,-0.021422135,0.023583693,-0.0783584,-0.15808159,0.02936009,0.047298845,-0.049022783,0.08766626,0.042199552,-0.016171213,-0.04053717,-0.036004007,-0.08676198,-0.04005173,0.01842436,0.043509945,0.0033699498,0.028939955,-0.017316353,0.084645584,0.04706389,-0.03267983,-0.09181551,0.026245268,-0.030527044,0.030395951,0.03230599,0.032351285,-0.05740066,-0.015140321,0.04326947,-0.0441678,0.07737427,-0.046178035,-0.0024477802,0.014862952,-0.00459534,0.048303198,0.034352187,0.040868666,-0.04474689,0.02679081,-0.054182716,-0.008575123,0.11126017,0.007954179,0.060501188,-0.004401115,0.017015468,-0.09318304,0.063222535,0.005905889,0.07838219,0.08122041,0.04819855,-0.044284537,-0.10031396,-0.0077063437,0.029351931,-0.039459977,0.06019846,-0.04973397,-0.036849078,0.014571468,0.02473491,-0.014209957,-0.016897265,0.036886737,0.047957253,0.1251639,-0.018054739,0.050470844,0.02587143,0.066316776,-0.050459627,-0.05368613,-0.0047598225,-0.060211368,-0.10903581,4.175714e-33,0.06714301,0.016238857,-0.016045358,0.044458672,0.06806373,-0.038233504,0.02767303,0.048214763,-0.09924411,-0.064552754,0.012595115,0.059337202,-0.011660493,0.009963026,0.017775739,-0.05953677,-0.15708809,0.044177115,0.04715701,0.06589588,-0.012101716,-0.1466407,-0.014625698,0.02391262,0.05588532,-0.02858483,0.005350436,0.058505677,0.0817253,-0.004015251,-0.1420735,-0.13669452,-0.07409187,-0.05118268,-0.033004966,0.08771464,-0.018081743,-0.059446577,0.043401025,-0.009276255,-0.015914364,-0.027091483,0.07061438,0.054462787,-0.040713437,0.03198957,-0.005459684,-0.00084374857,0.09724539,0.02095026,-0.046958767,-0.08260164,-0.001726501,-0.07984806,0.050621647,-0.031286813,-0.02017988,0.057369366,-0.0570199,0.039083548,0.0029216786,0.11252528,-0.0969847,0.123398125,-0.020311233,-0.016224345,-0.024079654,0.012375697,0.11458839,-0.0068544312,-0.016976552,-0.060522534,0.049038187,0.041856177,0.04016595,-0.0069476673,-0.10986786,-0.016324379,0.00635006,-0.02939909,-0.021326665,-0.06956992,-0.02929974,-0.013791159,0.0126412,-0.07521118,0.062393986,0.0050299135,-0.046605095,-0.013136849,0.0006026311,0.0007896557,0.10254701,0.106481045,-0.012802609,-3.9430933e-33,0.002442813,-0.034208275,-0.09553939,0.061046857,0.07333173,0.026950065,-0.011564829,-0.03328605,0.059134576,-0.038160916,-0.031507652,0.033220295,0.014524666,0.008613465,0.0043870937,-0.08450703,-0.021113068,-0.028149635,-0.014128233,0.032839935,-0.009529249,0.056327093,-0.040321656,0.018945413,-0.008049054,0.050184496,0.04719569,-0.037757803,0.00324484,0.017416457,-0.08682824,-0.098256476,-0.03884811,0.025807017,-0.0089477,-0.0015999719,0.07715839,-0.044520754,0.017498339,0.02788977,0.0006701253,0.0039042323,-0.028070133,-0.00076135003,-0.061744343,0.075484365,-0.015633943,0.039340783,0.030019572,0.020562159,-0.033689074,0.050255947,-0.004697955,-0.048540857,-0.020014098,0.059756774,0.0056901947,0.040844,-0.025030594,0.086699046,0.01998834,0.012562641,0.026716363,0.031108156,0.0334242,-0.063383356,0.024855437,0.08901975,-0.10301171,0.005268644,0.029761823,-0.00068199,0.024984699,0.032563232,0.041236475,0.012762579,-0.014291849,-0.0760044,-0.015211026,-0.048489187,0.015181585,0.022293843,-0.044307534,0.115898736,0.026289908,-0.053791963,0.034029238,0.044144545,-0.0017735471,0.006893767,0.03712895,-0.032671344,0.027325902,-0.015352883,-0.044766046,-3.988815e-08,0.029108092,-0.018528992,-0.015076225,0.032341003,0.00093371974,-0.060849804,0.014020168,0.024507493,0.012898699,-0.021794891,-0.023938997,-0.013396133,-0.018706115,0.02409355,0.09113404,0.025697382,0.015061554,0.0643979,-0.035816915,-0.12413018,0.06533066,-0.015026799,-0.06686282,0.05844007,-0.031376496,0.024137322,0.07699074,0.04193206,0.02508011,0.0008104618,-0.012438776,0.01087095,-0.043228913,0.0036370978,0.033149265,0.02199164,-0.017654676,-0.039334133,0.052031223,0.08612576,-0.09194365,-0.05974972,0.031627573,-0.011296489,-0.08271754,-0.050691683,-0.11922457,0.026612196,0.034181148,-0.016017152,-0.01519732,-0.059554935,0.03821015,-0.012034344,0.058839597,0.06513223,0.019972645,0.010121189,-0.008802962,-0.013104223,0.16659054,0.02450624,0.06323563,0.02296325}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:35.218388+05:30	2026-10-12 18:54:45.529793+05:30
7	7	{-0.034913745,-0.094521895,0.024455495,0.06495298,0.102047704,-0.053695604,-0.013468125,-0.065943405,0.046647344,0.050611712,-0.04666619,-0.05065263,-0.046944827,-0.0076986207,-0.07652782,0.00041561967,0.051780816,-0.008137745,-0.015178667,-0.028785512,-0.034021374,0.07172047,-0.047527213,0.06457898,0.007422992,0.009919995,0.027673181,0.01139975,0.010473461,-0.032286152,-0.0007081073,-0.01880567,-0.067161545,0.06820912,-0.0057770754,-0.053665146,-0.05226716,-0.046948034,0.04858049,0.023155544,0.12329453,-0.11485764,0.032419153,-0.057831727,-0.010807582,-0.0017577694,-0.087526865,-0.045333363,0.0079976665,0.06440459,0.0132018635,-0.050374534,0.024899643,0.09852438,-0.058942717,-0.018954115,-0.00660024,0.04682154,0.05700861,-0.013591216,-0.00601008,-0.029013183,0.033107843,-0.02264869,-0.045618605,0.023180922,0.04335715,0.10690861,0.060951315,0.04677746,0.013493016,0.09945288,-0.039030187,-0.019730816,0.038429122,-0.0049527255,0.0032263892,0.03324008,0.03834877,-0.03063704,0.0076042423,0.06476627,0.010423976,-0.0075182426,0.0038698756,-0.050745364,-0.01983215,0.061961595,0.028922433,0.016930167,0.017547686,-0.01203147,0.12598504,0.016171154,0.022043226,0.039735828,-0.052349314,-0.0009948986,-0.0026118467,-0.0064676595,-0.031757772,0.07753221,0.029657638,-0.0013202797,0.08436359,-0.06942665,-0.004688067,0.021014867,0.07853687,-0.06457743,0.066676386,0.0055293045,0.047846034,-0.037094977,0.050736338,0.026143841,0.034259126,-0.072583914,-0.11274156,0.03392924,0.05989302,-0.08764157,-0.025149316,-0.033813618,0.036221802,0.065199524,-0.06799523,3.8880464e-33,0.059069235,0.027648138,-0.022236586,-0.069277905,0.06880736,-0.0484681,-0.045882504,0.0193832,-0.06475559,0.0056834375,-0.16573478,0.07039387,0.011108111,-0.015119053,0.051531006,-0.017997855,-0.02426827,0.024015255,0.042442948,0.008248231,-0.018607019,-0.06341351,0.013886953,-0.051212046,0.07518143,0.0588533,0.07984692,-0.010464607,0.01990538,0.024788653,-0.03105124,0.04099111,-0.029759794,0.0016191632,0.029651187,-0.09062551,-0.103906296,-0.0102079585,-0.011939956,-0.028990703,-0.0053267297,-0.019730808,-0.076124616,-0.047228932,-0.012416015,-0.007698365,0.012254914,-0.056190412,0.0065487646,-0.072279364,0.07225842,-0.013723378,-0.0076442477,0.03239551,0.032012615,-0.0014199857,0.047332417,-0.012598947,0.042342905,0.015818745,-0.030555213,-0.010789721,0.061897304,0.03676522,0.036553357,-0.036997344,0.05218352,0.13136567,-0.031277895,0.012878844,0.07333739,-0.07427498,0.0121559035,0.033546086,0.024057169,-0.016633593,0.07422495,-0.010196134,-0.06602891,0.052154854,0.0054137204,-0.024303984,0.09596773,-0.0047819065,-0.101046704,0.0061787334,0.05008127,0.021778788,-0.06298238,0.04390301,-0.078377575,-0.0356136,0.052753236,-0.0127406,-0.060445197,-2.9387243e-33,-0.002401205,0.01250614,-0.08681705,0.046779394,0.017050467,-0.04548019,-0.03309682,0.056940418,-0.029513087,0.024303278,-0.0074292384,-0.02746291,-0.01686577,-0.011442226,0.07339734,-0.01243846,-0.067690626,-0.03711438,-0.05902656,0.020905914,0.019406343,-0.03781094,-0.062439643,-0.055941895,-0.056741588,0.030399786,-0.039665386,0.10134789,-0.0015333213,-0.09038779,-0.09493728,0.025444608,-0.018622078,-0.011408572,-0.009204627,0.016722206,0.10519515,-0.002647132,0.06206885,0.009192084,0.050185166,0.006363506,0.0040178234,0.025300954,-0.0060085575,0.034513332,0.014943406,0.08277068,-0.057505596,-0.047155987,-0.025440909,0.013123031,0.026206631,0.09191458,-0.067783095,0.04509637,-0.04584522,0.06053171,-0.057882316,0.05963542,-0.025114236,-0.0785697,0.070823036,-0.023194132,0.050275017,-0.041303,0.055431154,-0.015440645,-0.07297397,-0.046293136,0.095670894,-0.05814599,-0.12050365,0.06307715,0.016212348,-0.055219408,-0.037247192,-0.06705224,-0.026375547,0.011053309,0.016674723,0.012193653,-0.04891979,0.07271622,0.07399968,0.056625184,0.08745606,0.011425878,0.03508425,0.04117475,-0.06288359,0.0061046067,-0.10642418,-0.018105397,-0.024470363,-3.2206366e-08,-0.023452396,0.056080487,-0.012866163,0.016987028,0.09642151,0.013207843,-0.030509353,0.08138073,-0.050102618,-0.011909345,-0.010944969,-0.09345693,0.006060205,0.0128018595,0.032848164,0.0019487772,-0.02136031,0.013523289,-0.030317595,-0.024794906,0.07684712,0.052891847,0.041243933,-0.017761998,-0.03742098,-0.048052274,0.07488653,0.06929804,-0.04450564,-0.049894877,-0.011455418,0.011293171,0.0043136002,-0.03231804,0.0024901745,0.1370048,-0.000709453,-0.0738887,-0.0205127,0.021961223,-0.03241509,-0.012650134,-0.044870954,-0.004587497,-0.13764302,-0.03684099,-0.032055825,-0.058444865,0.060075935,0.022268498,0.060239382,-0.05465503,0.056662537,0.07044486,0.10789147,-0.03182807,0.070693865,-0.110997505,0.068886995,0.09369134,0.073314436,-0.03199101,-0.03964932,0.013302617}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:43.274415+05:30	2026-10-12 18:54:45.643137+05:30
9	9	{-0.05396021,-0.04948906,-0.015422567,-0.043408364,0.023682887,0.047422793,0.03904696,-0.045580413,-0.025631884,-0.11059441,-0.00782201,-0.056564216,-0.013184963,-0.0216731,-0.055275578,-0.04878262,-0.0028910444,0.058136545,0.0013787318,-0.03401945,-0.015388311,0.0062260726,0.00010048951,-0.032460548,0.012020484,0.016812546,0.016916309,-0.023821555,-0.055057384,-0.044078868,0.0605524,0.026925212,0.003982977,0.03800219,-0.0843781,-0.05848372,-0.08005209,-0.031603295,0.012985442,-0.0038507634,0.06098019,-0.0800776,-0.011452263,-0.035343096,0.089571245,-0.005316163,0.026314067,0.02841088,0.016579531,0.062280457,-0.07718634,0.004702097,0.04169424,0.08260822,-0.03562823,0.024961172,0.07296459,0.035716243,-0.039369915,-0.03373087,0.029938258,-0.013690697,0.058648977,-0.011929612,-0.023932843,-0.0034820521,-0.05561146,0.059301488,0.021965852,0.0069055534,0.07698086,0.0047956337,-0.07281145,-0.0156152155,-0.06882086,-0.00077235006,0.07860451,0.0349806,0.06914675,-0.0065746834,-0.06410187,-0.011605554,0.025968328,-0.019452447,0.073690906,-0.03857772,-0.063144386,0.06871635,-0.10825028,-0.04179632,0.08480588,0.010392855,0.089101754,-0.053380698,-0.052972283,-0.051349558,-0.046969637,-0.058144115,0.02345116,0.007703889,-0.037861716,0.07969262,0.039213907,0.04351356,0.08477212,-0.047525924,0.062093314,0.07054047,0.05116822,-0.06881401,0.04651717,0.03775319,0.047641918,0.0012114024,0.033316333,0.020719437,-0.019239537,-0.039011985,-0.021592772,0.110687636,-0.006939299,0.03546984,-0.079467766,0.03351842,-0.08401438,0.008711131,-0.08988355,3.3553638e-33,0.009053005,0.02503449,-0.0067193755,-0.11938682,0.03753404,-0.014228271,-0.04039764,0.10478762,-0.009019472,0.08840146,-0.12313499,-0.0012683797,-0.0371776,0.071811296,-0.03913898,0.016530082,-0.06912957,0.0148831,0.019747868,-0.042398296,0.040078867,-0.02726852,0.025308369,-0.01672367,0.045708217,-0.008866023,0.036695138,0.020739902,0.06706414,0.0047498024,-0.045152742,-0.05975956,0.031634163,0.006729565,0.03301113,-0.04133367,-0.036870755,-0.03269957,-0.04747548,-0.029523488,-0.08123939,0.01847205,0.010220622,-0.024149261,-0.076402724,0.07116031,0.022373505,-0.027611705,0.0018331273,0.047078017,0.0035914548,-0.034223974,-0.04986655,0.06612398,-0.065906554,0.028113622,-0.009449517,0.057366014,0.013472716,-0.031735044,0.030585345,-0.009890829,-0.04084037,-0.0014505523,-0.08266456,0.025973754,0.07318776,0.04826888,-0.043899298,0.020700894,0.01890352,0.06920377,0.0580337,0.004908405,0.045961414,-0.021591205,0.07636008,-0.002489263,-0.028832449,0.041561216,0.041564852,-0.0031718246,0.07727381,-0.010217405,-0.016086346,0.082774065,0.09881431,-0.028494477,0.02457864,0.05139123,-0.09857685,-0.027490623,0.06808041,0.03722978,0.0093078455,-2.1739956e-33,-0.08284725,0.008926713,-0.020186022,0.008041919,0.0037796993,0.025480181,-0.07929264,0.033834517,-0.015571368,0.04082233,0.008325112,0.0030751005,0.08014642,-0.016595403,0.033660308,-0.026257416,0.022471894,-0.0148814265,-0.008593049,-0.027151326,0.050568383,0.046576813,-0.040991616,0.002616051,-0.12643194,-0.011456611,-0.026173498,0.035397504,-0.010931762,-0.044700757,-0.0388046,0.010368706,-0.036561668,0.02663273,-0.041993618,-0.024765335,0.022262715,-0.028835688,0.014979783,0.012099732,0.09403967,0.039469495,-0.075981125,-0.0032761637,-0.017014148,0.003910087,-0.032341458,-0.0034534414,0.08736862,0.029040346,-0.04875898,-0.03667268,-0.05338674,0.08263694,-0.071235165,0.052612968,0.017475901,0.008727916,0.04721046,0.04330462,-0.12613349,-0.02651514,0.034608986,-0.041914135,0.050024524,-0.050469015,0.053797238,0.03982776,0.005326709,-0.065011054,0.033362128,0.0049573802,0.02995545,0.09531682,-0.08241343,-0.017979562,-0.068566695,-0.088466614,-0.029499335,-0.021058075,0.12863024,-0.019042185,0.09714124,0.05182093,0.069524884,0.050031245,0.019495545,0.06855582,0.060242113,-0.054982547,0.022096423,-0.026878402,-0.04891017,-0.0422905,-0.049525034,-3.3426453e-08,-0.021572407,0.05845878,0.0056786104,0.0713746,0.03763252,-0.059568316,0.045302678,0.06978117,-0.031551883,-0.051808953,0.07255482,-0.014651861,-0.12393603,-0.10608742,-0.0065931175,-0.0072429692,-0.01436049,-0.027860375,0.04758775,0.120081104,0.09578802,0.048477795,0.04560676,0.034288093,-0.014832094,-0.083145685,0.011453663,0.1339464,0.0584902,-0.035323463,-0.06433282,0.00849431,0.025421187,0.0063671567,0.0031604227,0.0819899,0.032085508,-0.015715744,-0.041817643,-0.0047282204,-0.028584644,-0.07429927,-0.023798484,-0.03219499,-0.06837894,-0.027535923,-0.08548329,-0.09758946,0.10291813,-0.03800295,0.036770627,-0.043617815,0.15238225,0.08481415,0.0800658,-0.018771488,-0.0084697455,-0.0674169,0.06513296,0.01882008,0.058156457,-0.06977521,0.0035169516,0.026686631}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:44.527097+05:30	2026-10-12 18:54:45.780678+05:30
11	11	{-0.037784535,0.070589446,-0.006592998,-0.08423079,0.0070522684,-0.043508925,0.0065341615,-0.026328454,0.06711552,-0.033462487,0.009992343,0.039793603,0.08954351,0.013923145,-0.018581318,-0.028633371,-0.07724995,0.033634543,-0.00663757,-0.011919058,-0.011671492,-0.11481715,0.022914667,-0.05419478,-0.010989261,0.013387785,0.043324653,-0.0128792105,-0.014944135,-0.096225075,0.090772405,-0.016057307,0.044436663,-4.8111604e-05,-0.048371762,0.10288279,0.06323461,-0.062906094,-0.01790716,0.0044791508,-0.058973033,-0.038882285,0.01071895,0.015674531,-0.03048711,0.05104109,0.022455819,-0.033335388,0.0053422363,-0.0617774,-0.06735425,0.058860563,-0.033120196,0.100277714,-0.015202855,0.025556544,0.01428598,-0.019236408,-0.003516872,-0.04730996,0.007872535,0.101548135,0.017431049,0.10388592,-0.044987418,0.06068582,0.04205278,-0.04008814,0.058202785,-0.031985473,-0.07841594,0.004801723,-0.017014498,0.045166362,-0.0361547,-0.014939102,-0.019144176,-0.04801621,0.004032017,-0.035810504,0.058399383,-0.111253105,0.00056725467,-0.02031632,0.05535735,0.042726588,-0.016984694,-0.022508757,0.055335183,-0.013437297,0.037580077,-0.0025365502,0.046212222,0.027742783,0.09648687,-0.049465377,0.056247372,-0.047955275,0.012425027,0.016079498,-0.005458901,-0.104406,-0.042706776,-0.02627135,0.09078313,-0.0050262236,0.055903852,-0.02472591,0.023673713,0.023196667,-2.5187317e-05,0.019168492,-0.0103125535,0.024814151,0.0013617967,0.057853956,-0.11969772,0.07154722,-0.03642034,0.058855824,0.05093065,-0.0012316908,-0.08970172,-0.03272361,-0.017878,-0.057062026,-0.03172257,2.4149046e-33,-0.04730786,0.00824193,-0.015156973,-0.041413903,0.009870023,0.080079034,0.06646769,-0.0338115,-0.071653344,0.041386124,-0.06382807,0.018216655,-0.021287251,0.041326303,0.019490002,0.006387597,-0.028967237,-0.036070943,0.049652554,-0.0066964077,0.04288654,0.004553014,0.017101454,0.006837078,-0.016197633,0.0002021954,0.050358195,-0.04584433,0.13316783,0.051389653,-0.07732426,0.010601946,-0.04141495,-0.0668732,-0.013997213,0.025098717,-0.027051792,-0.037489697,-0.06897482,-0.010325161,0.049980257,0.013448425,-0.062236775,-0.03536079,-0.09139514,0.04286783,0.066050775,0.049881294,-0.01341969,0.05329755,-0.025467912,-0.06800372,-0.13539825,-0.049439922,0.013476345,-0.13437325,0.04978934,0.0109830145,-0.07375105,0.09403531,-0.027829958,-0.029230038,0.022329787,-0.08928657,-0.0040873736,-0.07853507,0.08227522,-0.061039627,-0.04999166,0.0042395676,-0.016480513,0.043641035,0.01949449,-0.005389651,-0.009432577,-0.042246107,-0.008773912,-0.011108157,0.03297424,0.014078762,-0.099481046,0.0421232,0.09364835,0.026319155,-0.05919321,0.03899537,-0.048030153,0.038198285,-0.14653745,0.00079953513,-0.018193085,-0.053712755,0.11580448,0.035651937,-0.022493044,-3.4191747e-33,-0.052652694,0.036279883,0.012796679,0.090017796,0.016063923,0.021847589,0.069558255,0.13259725,0.008552458,-0.009500222,-0.0043224967,-0.0007336135,0.06745565,-0.017975375,0.05591217,-0.070133545,0.03867193,-0.002259259,-0.03850622,-0.023564683,-0.037265666,0.07379223,0.004174594,0.10392387,0.08803791,0.071335554,0.012873193,0.022215804,-0.016742582,0.052019704,-0.033779107,-0.040604334,-0.045881413,0.026903052,-0.0019595812,-0.033738993,0.045068428,-0.017216187,-0.033931866,-0.017057778,0.059149712,0.031684037,0.033893403,0.023345595,-0.003753856,-0.03058412,-0.029894482,0.095846646,0.041007806,0.042517774,0.012148467,-0.031589262,-0.020511905,0.021306098,-0.0053417813,0.054306276,-0.098448895,0.094802156,0.05562206,-0.01893445,0.06811478,-0.018312687,-0.0018873832,0.0142005645,-0.046106372,0.029947026,-0.004700521,-0.022134757,-0.08236786,0.0015374564,0.09254452,-0.033009555,0.029303642,0.075589664,0.008403354,-0.057535425,-0.03592395,-0.010522225,0.024156975,0.0071171257,0.011161737,0.043678045,0.02391423,0.07476731,0.053367697,0.040928617,0.0739733,-0.1340784,0.027739337,-0.023554718,-0.04743132,0.028018158,0.019038998,0.0884209,0.1501334,-3.7467583e-08,0.017694604,-0.079690985,-0.016291052,-0.057652313,-0.027481172,0.011794315,-0.007731795,-0.00016635352,0.030222144,-0.11750414,0.085825905,-0.04741231,-0.0361328,0.00936418,-0.020143252,0.023633441,-0.001687852,-0.010848379,-0.028578557,-0.124161415,-0.016944401,-0.07692201,0.020794732,-0.0024289198,-0.012918598,0.07167588,-0.02189919,-0.019503193,0.050262295,-0.08152397,-0.033097327,-0.077333465,0.02345776,0.00030178687,-0.06345814,0.043581553,-0.039723296,-0.03358473,0.04856351,0.08202817,0.010492786,-0.096972786,0.03443601,-0.03052781,-0.029108496,-0.007883344,0.055512764,-0.0066475356,-0.054933604,0.11215179,0.036979314,-0.10645142,-0.0055837245,0.017431673,0.03840741,-0.050052002,0.028631514,-0.025440594,0.0593849,0.07266301,0.0489671,-0.03576866,-0.037436083,0.0014271743}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:15:44.717434+05:30	2026-10-12 18:54:45.932378+05:30
13	13	{-0.10069774,-0.053040087,0.061154716,0.045939457,0.061796356,0.011237955,-0.035286643,-0.1019217,-0.049286433,-0.075061195,-0.03793462,0.0041534593,0.024039516,0.0014962025,-0.0863932,0.022509266,0.0480642,0.16514917,-0.10591953,-0.035216108,-0.034120593,0.016919557,-0.0042896317,0.028061198,0.008399014,-0.019719042,0.0049265358,-0.016713332,-0.017200764,-0.06144093,0.02214448,-0.07278971,-0.06566666,0.06985286,-0.07565512,0.07534306,0.021114552,-0.027538689,0.058873404,-0.042508993,-0.0036046572,0.004275564,0.006400978,-0.019658936,0.022839183,0.032553457,0.037408818,-0.046287492,0.048716653,-0.01985806,-0.00565685,0.026022725,-0.062046923,0.03233802,-0.04912597,-0.054263357,0.026322002,0.0034321381,0.032045957,0.05898561,0.0049847118,-0.025898721,0.017403709,0.03529406,-0.047137305,-0.0075747035,0.025373152,0.00889641,0.044746496,0.0014849947,0.056168944,0.12783866,-0.054724645,-0.017286789,0.042050797,0.09237265,0.007090367,-0.018245922,0.13715552,-0.1264718,0.08856743,-0.0072804685,0.06347939,-0.0041107126,0.126219,-0.03503482,-0.09609483,0.02402766,0.043070704,0.021760449,-0.024609566,-0.030230077,0.013591293,0.046606466,0.0387633,-0.023531197,-0.0021535477,-0.103737354,-0.15218394,0.04727942,-0.055403773,-0.035226177,0.030475123,0.008192509,0.1077877,0.0005900608,0.09850511,-0.008882519,0.0066988,-0.025905691,0.097578324,0.05540787,0.0413462,-0.01768644,0.04390431,-0.02729209,-0.112521075,0.034170523,0.004722105,-0.0024357708,-0.035837073,0.020761637,0.016232919,0.016132455,-0.015671948,-0.014606307,-0.057268523,3.5275774e-33,-0.023609994,0.011111932,-0.0015924878,-0.059949458,0.035552453,-0.083299555,-0.023897389,0.050344616,-0.08469545,0.053369958,-0.0674253,-0.024693266,-0.080183394,0.11719698,0.048593014,0.06599189,0.023325188,-0.0048230733,0.009360516,-0.008416885,-0.008672406,-0.06092858,-0.027905367,-0.02798979,0.018385144,0.016501859,-0.00044241783,0.05090832,-0.033441637,0.050487395,-0.06472489,0.039953392,0.029164575,0.020556554,0.008344393,0.0052455273,-0.019234885,-0.029142566,-0.016827872,-0.0008792943,-0.024933852,0.031433117,-0.045315735,-0.0501276,0.0059042997,0.04589109,-0.003250718,0.011527812,-0.07885508,-0.041953906,-0.04376464,0.020724932,-0.080643564,-0.04021696,-0.08838863,-0.029574685,0.050735332,0.06215651,-0.030033395,0.048694227,-0.020602202,0.0730632,-0.03429083,0.0064750146,-0.07511156,-0.068516366,-0.0010591814,0.027797978,-0.016438017,0.049838167,-0.044518992,0.024069067,-0.017102087,-0.064861536,0.015195385,-0.016794134,0.08660359,0.028944695,0.014313044,0.027461864,-0.02769208,-0.031053517,0.026621941,0.061648563,-0.06783668,0.013549273,0.014542735,-0.06492841,-0.011652303,0.041115377,-0.04383575,-0.03628297,0.05933714,0.04861792,-0.029831313,-3.703196e-33,-0.09898139,0.12237222,-0.06568471,0.07713365,-0.048128877,-0.0128699625,-0.0013669239,0.09571757,-0.029689793,-0.013455434,0.007694627,-0.018517327,-0.0176882,-0.042253006,0.03635753,-0.028615767,-0.036885295,0.040773734,-0.03519161,0.019322133,0.005244123,0.10003956,-0.03000246,0.05726153,-0.03350651,2.1421809e-05,-0.07151578,-0.028005721,0.056745645,0.0053031985,-0.024179054,0.08033381,0.018094352,-0.03713872,-0.023019347,0.040267054,0.043609865,-0.06426022,0.033446305,0.043223992,0.08042535,0.07942206,-0.022550732,-0.010031159,-0.017645247,0.017956948,0.054590557,-0.0016272643,0.047684066,-0.024609385,0.005892982,0.0028708135,-0.062161572,0.06963789,-0.0570428,-0.014992869,0.06615256,0.012228849,0.08812179,0.07008838,-0.07092676,-0.046969596,-0.013568637,-0.022452936,0.014468983,0.03559811,-0.056635953,0.11036918,0.055260092,0.028171254,0.0800064,-0.012842659,0.023746049,0.08381767,-0.09272391,-0.07326528,-0.01403505,-0.09655186,-0.014668047,0.09250611,0.14504068,-0.051962264,-0.014568036,0.087683335,0.057178393,0.026055899,0.038269784,0.005733447,-0.0020075904,0.02193216,-0.038116623,-0.010033806,-0.035617642,-0.010383488,0.040689416,-3.344793e-08,-0.054192547,0.048764884,0.047681138,-0.04550106,-0.0129612405,-0.028164,-0.030139823,0.079935156,-0.033454627,-0.00436088,0.044408936,0.0010799916,-0.04630122,-0.0834814,-0.09013983,0.09116679,-0.016354598,0.013558494,0.002899943,-0.023830028,-0.053011477,0.008763449,-0.01783884,-0.036947332,-0.008317956,-0.0693193,-0.01682124,0.044250097,0.046269502,0.04956177,-0.07375388,-0.024818184,0.009717987,-0.009420001,0.007519068,0.13768014,-0.034964863,-0.025042342,0.053409155,-0.00012487528,-0.050228465,-0.004781855,0.048342865,-0.02080924,-0.09885563,0.013643154,0.04576315,-0.12870209,0.006830249,0.013726767,0.059229717,-0.0075322688,0.03649775,0.08042235,-0.020530624,0.0011406885,-0.03427977,-0.08682189,-0.0075760684,0.078665264,0.029094694,0.0147954635,0.033563413,-0.05630463}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:33.353322+05:30	2026-10-12 18:54:46.079782+05:30
15	15	{-0.042558093,-0.02019513,-0.0057308534,-0.021445055,0.05002193,-0.05958255,-0.0075281006,0.04908941,0.012571591,-0.008520273,-0.0584421,-0.05851827,0.035653815,0.023031734,-0.04130762,0.008459175,0.035705443,-0.039502136,0.06841598,-0.06775815,-0.099642456,-0.026408857,-0.0136261275,-0.051550522,0.063977756,0.026682252,0.029010752,-0.022070015,-0.016205551,-0.0479315,0.035687316,0.027378973,0.019234281,0.043242168,0.031215988,0.032196052,-0.03259784,-0.023025231,0.0067408285,-0.0652226,-0.05051391,-0.03655208,-0.015594248,-0.052548952,0.073627934,0.019947626,-0.08991989,0.0033676247,0.03578439,0.05156792,-0.08747077,-0.122321226,0.07572482,-0.0058239102,-0.027658958,0.069537625,0.017327733,-0.01666658,0.0024278143,-0.019914227,0.10617073,-0.017646844,0.05715912,-0.030025382,0.0080123115,0.009277232,-0.063013986,0.084890515,0.012784978,-0.04144603,0.06551564,-0.004412699,-0.118855834,0.07187758,0.009882586,0.05655021,-0.013264636,0.0047086584,0.11166916,-0.012001107,-0.09019637,-0.048768222,-0.021449862,0.034477137,-0.037329257,0.006335211,0.045538187,0.030084537,0.11328286,0.03722004,-0.06422669,-0.008722982,0.030015822,-0.006462691,0.0846108,0.026702002,-0.0028848858,-0.051453475,-0.008072654,0.017478047,-0.036106344,0.04051169,0.010741011,-0.04432899,-0.03410794,0.012507196,0.06444264,-0.029764293,0.12948474,-0.0024431585,-0.04499345,-0.037788894,0.10179106,-0.0410819,0.06302744,0.034804706,0.02048646,0.070988804,0.020096745,0.09094629,0.062468164,0.02302169,-0.021632012,-0.07748537,-0.019016584,-0.00573358,-0.09903178,3.2473094e-33,-0.028974662,0.07522333,-0.042860415,0.045776848,-0.0042278958,-0.0926209,-0.009523528,0.05270372,-0.15673445,-0.034753136,-0.0673494,0.07753121,-0.049671065,0.071958676,0.042588424,-0.06222248,0.018714024,0.056455474,0.013672851,-0.025538465,0.0059994794,-0.09188698,-0.027356338,-0.025814118,0.080822214,-0.046178043,0.012268192,0.03704916,0.076846346,0.0006310862,-0.022747986,0.012312014,-0.09194256,-0.046386015,-0.026149467,0.038762797,-0.010577208,-0.07036174,-0.04505899,0.06605237,-0.062947065,0.05642844,-0.0013389715,-0.061932866,-0.017384078,0.054239187,0.006477024,0.0015230088,0.10030036,-0.07493846,-0.0897889,0.00416901,-0.014483437,0.0054067825,0.019432234,-0.0106801605,-0.053540777,-0.031329688,-0.035173498,-0.023317415,-0.0055102934,0.005293052,-0.05698226,0.075303435,-0.050949432,0.02995808,0.06267556,0.095143706,0.06315663,0.11546329,-0.0036941092,-0.030442504,-0.019284695,-0.04143654,-0.015363095,-0.03469081,-0.009860727,0.009366281,0.04124771,-0.013562239,-0.024309088,-0.04270161,-0.021154221,0.021907616,0.0042750835,-0.018166047,0.04119151,-0.002219352,-0.038530167,0.055033863,-0.015949633,0.04706414,-0.07992995,0.09162168,-0.07130456,-3.6655925e-33,-0.019306833,-0.06245921,0.0050817686,-0.014682811,0.061731506,-0.0061803814,-0.033886302,-0.023939436,0.009570495,0.018336816,-0.0408344,-0.053706806,0.023838691,-0.029383065,-0.10924998,-0.018784463,0.015194034,-0.030212466,0.047695387,0.04356661,0.07108712,0.031610664,-0.064813,-0.08695222,-0.003866501,0.026347203,0.011860641,0.0043204324,-0.097995244,-0.005874363,0.06287072,-0.03887489,-0.047419757,-0.009721709,0.0391754,0.073886886,0.044969782,-0.08348884,0.00960507,0.007609234,0.0431135,0.00024250886,-0.07313474,-0.006038746,-0.051248163,-0.016115436,-0.001155879,0.07747483,0.018142814,-0.04522312,-0.015616999,0.03635664,0.05036802,-0.04483762,-0.04274132,-0.031172752,-0.008068562,0.09178768,-0.015785769,0.11921765,0.005276359,0.0064089457,0.030792518,0.033872534,0.0057783574,-0.06362886,-0.015507109,0.09423547,-0.11361815,-0.04749752,0.07329558,-0.024790745,-0.011789312,0.022128837,-0.047740262,-0.008603575,0.015596237,-0.067657,-0.04588206,-0.08721419,0.036433596,-0.001629053,0.014700047,-0.017451875,0.06641257,0.02129788,-0.0413937,0.059383772,0.021592082,0.051446542,-0.05392214,-0.031478744,-0.04816586,0.011880403,-0.09552193,-4.1868038e-08,-0.02380839,0.0012094342,-0.017725142,0.06087107,-0.03435225,-0.021102525,-0.054025985,0.008737047,-0.021768704,0.014781661,-0.006681757,-0.032169256,-0.08779891,0.052436665,0.08817577,0.0024614541,-0.0013811238,0.047551356,-0.029815232,0.01124971,0.036125656,0.06373598,-0.012433195,-0.056925055,-0.004900963,-0.030758662,0.029163677,0.006427987,-0.0033983614,0.06137413,0.0016104081,0.04503867,0.078800604,-0.04472235,0.062622145,0.09297792,-0.04558028,0.002343725,-0.030994594,-0.031432774,0.029848732,0.059931066,-0.044288497,-0.02501784,-0.082570426,-0.02374921,-0.0914154,-0.07992515,0.075729676,-0.049881373,0.018274384,-0.06831684,0.08925232,0.08651358,0.13865738,0.059626378,0.01067945,0.029227847,0.07109854,0.063634604,0.13922347,-0.063024126,0.1009695,-0.016658919}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:34.560434+05:30	2026-10-12 18:54:46.207943+05:30
17	17	{-0.034424137,-0.009826521,0.047359873,0.002254145,-0.017679058,-0.042494252,0.013307047,-0.00039187973,-0.019632801,0.01211261,-0.047964852,-0.03327852,-0.020160604,-0.01718495,0.030111365,-0.0020643238,0.069728374,-0.05475733,0.008272715,-0.06960756,0.028003072,0.06819318,0.015483403,-0.027417324,0.030644907,-0.026166674,-0.035537574,-0.030556874,0.043687705,0.023363002,0.030155055,-0.012076666,0.0739559,0.079670615,-0.032982707,0.04304286,0.004095274,-0.032386158,0.023440324,0.02607166,-0.069838285,-0.0433431,-0.003953481,-0.010313745,0.042804755,-0.07141446,-0.0746641,-0.025183838,0.04341023,-0.0005305069,-0.11811835,-0.086453415,0.06792809,-0.027927427,-0.04780696,0.13121,0.034205083,-0.02953742,0.01623197,0.0012622356,-0.045423888,-0.07410193,0.029186048,0.0394343,0.025189009,0.06668798,-0.023577122,0.052220102,0.080231324,-0.054396372,-0.046988156,0.05543519,0.036473736,0.110841766,0.05266493,0.053915724,-0.024375899,-0.029860388,0.0969636,-0.015784048,0.060289953,-0.04720037,0.032028373,0.03489621,-0.03981297,0.021530759,0.05199094,-0.024150625,-0.0076129655,-0.023793083,-0.0030826135,-0.04083168,-0.012220523,0.045145214,-0.0039605363,0.022587506,-0.047164675,-0.08930944,-0.029210264,0.033600904,0.056304943,0.024808027,-0.02209072,-0.05541381,-0.14621882,-0.07457743,0.061027817,-0.06715982,0.03643045,0.023176702,-0.028680557,-0.016017463,0.014175158,-0.025593616,-0.012266746,0.0022423617,-0.021684906,0.03546438,0.041644957,0.013191792,0.050399926,0.055984363,0.03309974,-0.033749714,0.032495283,-0.12086838,-0.020760303,2.4294601e-33,0.022700576,0.030941019,0.024301387,0.101996414,0.0006143468,-0.061591137,-0.034756966,0.04856651,-0.06465296,-0.008719495,0.029050082,0.03542448,-0.03450961,0.07568716,-0.024906749,0.030813685,-0.08188218,0.055082683,-0.018815823,0.015277251,-0.011092039,-0.03827707,0.006451531,-0.0032994805,0.090340845,0.007984019,0.0063002743,-0.01775449,0.072544135,0.026971247,-0.14303273,-0.057880614,-0.04733441,-0.05264003,0.0058710496,0.0074388217,-0.017622545,-0.06223433,-0.05073554,0.07423713,-0.06950203,-0.007930468,0.043585774,0.021844687,0.005105161,-0.06649052,-0.04486305,0.012710209,0.08493459,0.040156197,-0.09478337,-0.032935634,-0.024971353,-0.037284493,-0.045024294,0.003831995,0.12443889,-0.009654519,0.05310312,0.0013706166,-0.03612522,0.026720116,-0.12891953,-0.039522797,-0.032293532,-0.059182197,-0.031571127,-0.043661196,0.14238033,0.032445952,-0.012123029,-0.06325175,0.0022164066,0.07046369,-0.039764322,0.05174104,-0.061080363,0.0272473,0.03377427,0.018346827,0.040808942,-0.09576914,-0.073813275,-0.058289222,0.08101155,-0.092545494,-0.019911865,-0.07780994,0.0020521746,-0.036058716,0.03909333,0.082211845,-0.0060233814,0.06662918,-0.045512684,-3.0452922e-33,-0.012798059,0.054961354,-0.08460193,0.11320547,0.06863997,0.041307636,0.10211669,0.0059384354,0.028624984,-0.027248072,0.028657366,-0.07693603,0.038420342,-0.017283896,0.031663854,0.047543038,-0.05221912,-0.043292508,0.02456139,0.053386558,0.04575029,0.041134283,-0.009200635,0.030570608,-0.03925535,-0.04742928,-0.004630333,-0.022576071,0.0094711045,0.07523014,-0.014560638,-0.034897894,-0.04391282,0.0602071,0.01721002,0.06585329,0.07898926,-0.055914056,0.0061755436,-0.0001719004,0.100747496,-0.047083054,-0.027282251,-0.061000314,-0.02041374,0.045464158,-0.081440784,0.003658747,0.031317525,-0.011956323,-0.023189727,0.0023249926,0.032460656,-0.05182589,-0.020637538,-0.07607981,-0.011570289,-0.07238677,-0.008503247,0.03657111,-0.017416388,-0.026716968,0.12230166,-0.0516651,-0.00955987,-0.036422074,-0.033530995,0.09003747,-0.07240187,-0.01939894,0.0031004855,-0.007286417,0.026035432,-0.032263976,-0.020720255,-0.023718867,-0.03874559,0.0016861894,0.013615577,-0.026815925,0.0072404905,0.03637405,-0.03141958,0.055150654,0.038805295,0.12212369,0.024752794,0.0658678,-0.0045954115,0.0315233,-0.028871644,0.13137673,0.061355766,-0.030659623,-0.05255503,-3.717233e-08,-0.006123859,-0.031774472,0.04967042,0.061801955,-0.058139578,-0.14883205,-0.023438007,-0.03259851,-0.03547506,0.008343512,-0.040166546,0.012766478,-0.038506106,-0.011313494,0.049459323,0.0743986,-0.052610047,0.073671594,-0.02045251,-0.121948816,0.114048965,0.054871432,0.01132353,0.010719331,0.032715358,0.0057781925,0.0657195,0.071527906,-0.061765697,-0.01922138,-0.04169341,0.013622671,-0.048714954,-0.0754594,0.0426364,0.048285924,0.0020106693,-0.028349401,0.04716449,0.0010815056,-0.10187347,0.0016407412,-0.031113543,-0.028954364,0.04598857,0.02786804,-0.066958815,-0.024941295,0.028692989,-0.07063005,-0.014415798,-0.04925717,-0.04818346,0.06523701,0.04282605,0.08907874,0.011846181,0.041579664,-0.02187053,0.0484235,0.10724462,0.08673034,0.017920101,0.0037693013}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:40.32661+05:30	2026-10-12 18:54:46.319604+05:30
19	19	{-0.03374235,-0.011355043,0.029860202,0.01810781,0.073774934,-0.08668817,0.047178637,-0.060101204,0.039463975,0.043009456,-0.082251,-0.024580427,-0.004435093,0.00011417957,-0.09734825,-0.07720206,-0.0032297755,-0.10314763,-0.0024908588,-0.032034755,-0.019704735,0.03855568,-0.079655744,-0.0055967104,0.0019228389,0.027964436,-0.019569786,-0.023140024,-0.03798151,-0.028339006,-0.076465234,0.026706334,-0.0025047236,0.03665219,0.028935099,-0.013315742,0.02350896,-0.04219036,-0.043140974,0.011982872,0.020146491,-0.08880156,-0.03457791,-0.03170761,-0.0016922848,-0.0322292,-0.1158097,-0.011367571,0.012036044,0.040596463,-0.030039884,-0.11359221,0.06713193,0.019448653,0.0053841476,0.042295504,0.028890362,-0.04294014,0.032406505,-0.095347635,0.094805226,-0.066146515,0.03571453,0.0005284208,-0.0005093516,0.08034408,0.06218492,0.075068295,0.01872047,-0.02723092,-0.024239812,0.056849327,-0.032264803,0.006878018,0.018154336,0.055301476,0.032146737,-0.015267101,0.08523866,-0.01998288,0.019213429,0.009628217,-0.040237237,0.09472124,0.028991753,-0.010782675,0.024990546,0.0256149,0.052975997,-0.020097796,-0.009205017,0.02350895,0.07799451,-0.03665322,-0.008237563,0.014041514,-0.063143015,-0.06971249,0.036448214,0.0010771478,0.01082905,0.0064927884,0.07306877,0.009676906,0.07047333,-0.00074440613,-0.055080693,0.03021203,0.08971974,-0.03655613,0.01159577,0.0092287455,0.031175071,-0.037213728,0.023194801,0.04304903,-0.039592065,-0.021203235,-0.042985756,0.06607242,0.085951865,0.03558595,0.031246295,-0.047993354,-0.009328331,0.014604503,-0.108801164,3.4905295e-33,0.037228804,0.021747187,0.04455192,-0.1496485,0.084004745,-0.0341306,-0.057290982,0.013579324,-0.08005796,0.032691114,-0.06624352,0.10144422,0.008749715,0.008779489,0.06459301,-0.055033844,0.053094715,0.119419254,0.046418067,-0.04715056,-0.0047922307,-0.016095106,-0.0061852317,-0.0111025255,0.09004319,-0.016182153,0.0537731,-0.012588334,0.14022458,0.032109044,0.033570252,0.057547737,0.012129132,-0.0065991716,0.013039702,-0.080042906,-0.08436154,-0.035013504,-0.015555511,0.0502223,-0.0033006915,0.008264874,-0.031210124,-0.054011907,-0.04659856,0.030239454,0.032863576,-0.045995343,0.040353604,-0.013534317,-0.10219744,-0.03008763,-0.015044062,0.0076917363,-0.050685093,0.00065278995,0.074829146,-0.09002892,0.03142337,-0.061122824,-0.06533786,-0.08467984,0.009036749,-0.036057808,-0.097067244,-0.03246188,0.04835444,0.092188,-0.05372975,0.10023786,0.015952464,0.012901878,0.060321983,0.029166786,0.04890902,-0.044011075,-0.0009364851,0.027477875,-0.08548123,0.010536504,-0.050357286,-0.065091215,0.07908244,-0.0073240674,-0.08547821,0.021886913,0.01469063,0.039697513,-0.042231243,0.021766426,-0.09255265,0.0018054596,-0.03932053,-0.058973167,-0.06532778,-4.2902484e-33,-0.052794077,0.019626915,-0.0484622,-0.0020803052,0.041891754,-0.0051090983,0.014673992,0.026466724,0.024485098,-0.041243322,-0.050067503,0.036728535,-0.023546273,-0.036935236,-0.010945759,0.04820439,-0.013590772,-0.1025705,-0.05072624,-0.010164708,-0.007465724,-0.07416433,-0.0019462694,-0.051445745,0.014951254,0.051688433,-0.015244666,0.0075893938,-0.014113457,0.019077986,-0.050301436,0.0039517074,-0.015432177,0.017726835,-0.00794632,-0.030177623,0.040689383,-0.0076241544,-0.00033746593,-0.03397406,0.0420207,-0.011260272,0.06745926,0.014563969,0.008253361,0.031165794,-0.010871929,0.071917996,-0.022690646,-0.01539827,-0.07119912,0.05091111,0.024289152,0.0998476,-0.05473131,0.03755129,0.03370583,0.06700608,-0.0659711,0.040956587,0.015051591,-0.013317798,0.023601118,0.02978954,0.044877294,0.010621725,0.015293466,-0.086586714,-0.04020852,-0.06847044,0.04722282,-0.002651552,-0.04482075,-0.026161749,-0.013233409,0.0010291977,-0.05503827,-0.07687588,-0.04417942,0.030340942,0.009908544,0.009387444,0.044803366,0.03663106,-0.032317396,-0.0039308714,0.10992596,0.0012580609,-0.012194006,0.050258383,-0.17851536,-0.024412662,-0.11650761,0.008256402,-0.014924847,-4.0730953e-08,-0.0070866193,0.049633786,-0.009393488,0.021212274,0.05241978,-0.080679275,0.028071286,0.14134638,-0.037463598,-0.0074786874,0.045404866,-0.0873987,-0.016065942,-0.009504831,0.020614937,-0.036972392,-0.0068795774,0.0041672597,-0.027558671,-0.070909224,-0.021190805,0.063268654,0.037860755,-0.004826777,-0.038784496,0.040645037,0.046259884,0.088834524,0.05442118,-0.030156912,-0.016939586,-0.021298714,0.05353296,-0.0033446704,-0.014779147,0.08646927,-0.112643205,-0.043526825,0.020320775,0.044686183,0.013914114,0.06439262,0.013317119,0.037344757,-0.009153704,-0.06228334,-0.035943903,-0.0112602115,0.08844385,-0.015235801,0.019510267,-0.04974075,0.040636238,0.19205597,0.08915496,0.018168561,0.056537878,-0.084534235,0.050220218,0.10921865,0.095992476,-0.077875316,-0.021110365,0.040622555}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:42.157129+05:30	2026-10-12 18:54:46.440418+05:30
21	21	{-0.071385466,-0.011535278,-0.08052823,0.04794593,0.103156224,-0.08476127,-0.033184145,0.06681578,-0.033500474,-0.017712636,-0.0029250712,-0.032606043,-0.01646874,-0.00017514432,0.011475553,0.06931794,0.03210564,0.009990212,0.030806238,0.00927466,-0.02476598,0.08237782,-0.054491144,0.013614844,0.0054921797,0.060278967,-0.0029924673,-0.020650448,0.029967034,-0.0034769536,-0.04493512,0.008938117,0.017724628,0.074049324,0.05129417,0.054365307,0.0030771163,-0.07494953,0.0075320536,-0.067566924,-0.13534945,0.019527402,-0.040113524,-0.0641188,0.052472435,-0.030679801,-0.0418249,-0.09176696,-0.0327448,0.02544603,-0.05364269,-0.06895601,-0.034208577,-0.023822417,0.031672195,0.04181136,0.029925225,-0.052108407,-0.0067350287,-0.022299767,0.03429469,0.049232922,-0.010894006,0.049780488,-0.028491227,0.0256528,-0.004778396,0.0824887,0.04692756,-0.088438496,-0.055260558,0.05344392,0.06609236,0.036546562,0.0034728206,0.06198649,-0.024293853,0.0009807367,0.047949836,-0.13959293,-0.051324904,0.028515514,-0.00074041553,0.09656216,-0.031621836,0.035996933,0.11337515,0.043691188,0.039730243,0.13110924,0.069956385,-0.0664733,0.110721506,-0.07499432,0.026133811,-0.023075003,0.015673704,-0.11588147,-0.023735784,0.03050862,-0.09930656,0.07016694,0.02827197,-0.100447305,-0.007177199,0.014916521,0.034251843,-0.053958237,0.070118755,0.0069359546,-0.057640746,-0.013559478,-0.11380006,-0.088750295,-0.026435276,0.060623392,0.0102516,0.051008858,0.0056065083,0.10728571,0.050665878,0.039533976,-0.017745728,0.035958596,0.104790345,-0.014007518,0.013136034,5.188621e-33,0.04604793,0.0051231347,-0.07193911,0.036932837,0.061281864,0.013153165,0.021651013,0.018619668,-0.08345813,-0.07694199,-0.05289093,0.074375436,-0.04631765,0.070374295,0.008756496,-0.050903972,-0.096314505,0.07267261,-0.06343181,0.03542181,-0.001026154,-0.09395901,0.04151243,-0.0017560887,0.059105262,0.029229982,0.050483365,0.031826936,0.022330353,0.042388223,-0.026015664,0.00803223,-0.00980418,0.027995242,0.039699946,0.054851647,-0.03715755,-0.06327712,0.056415655,0.015540657,-0.063547395,0.002637595,-0.053140398,-0.045992758,0.034627195,-0.05763716,0.016492955,-0.000324475,0.073157474,-0.07248198,-0.04480179,0.021122457,0.009764473,-0.0010028157,0.01882277,-0.10603451,-0.021084145,0.036774807,0.018124811,0.007806397,0.003494379,0.054156963,-0.06509846,0.016963284,-0.029580928,0.0018891782,-0.06559348,-0.0010299922,0.13760613,-0.058333106,-0.015526951,-0.021677552,-0.016042054,0.016317328,-0.06213207,-0.012253395,-0.033483,-0.029608542,0.010943881,-0.030761788,-0.074317075,-0.04665264,0.042155847,-0.005641391,0.057357255,-0.022626681,-0.03487171,0.037608135,-0.036145933,-0.0015177764,0.05126836,-0.050722204,0.011890099,-0.03463096,-0.001146567,-5.369795e-33,-0.007881793,-0.03735257,-0.092532136,0.049955633,-0.025700709,-0.0073704007,-0.033905055,0.014750798,-0.012163617,0.0020384844,0.009292084,-0.037934247,-0.023791991,-0.010237932,0.007566445,-0.013943461,-0.08450692,-0.04366496,0.081729785,0.071403846,0.030447608,-0.015115876,0.0128900735,-0.05633908,0.016820984,0.0027203008,-0.063770674,0.0038882212,0.009725175,-0.031807087,0.009802754,-0.0043737963,-0.07488893,-0.018267423,0.049658976,-0.046545178,0.04481277,-0.015272763,0.020328185,0.065214984,0.11063935,-0.06488005,-0.037978087,-0.07417474,-0.020884942,0.034147248,-0.03990463,0.100425206,-0.010318387,-0.063131355,0.023293713,-0.017651843,0.022893593,-0.082438104,-0.023090336,-0.05356126,0.03154437,-0.007020286,-0.117080845,0.064206444,0.016459562,0.027427163,0.08680435,0.036545426,-0.021954404,-0.019119125,0.005034035,-0.0028149989,-0.15811504,-0.059440706,0.06235267,-0.060084317,-0.08947552,-0.036483634,-0.014370718,-0.038844705,0.00040782927,-0.12271162,0.033914763,-0.07631175,0.0121457875,0.025882678,0.049514398,0.062415194,-0.022151094,0.117657095,-0.05643382,0.07301058,0.04723032,0.07106818,-0.056428105,0.04422053,0.03915284,0.032488137,-0.0030328897,-4.1655277e-08,-0.06352111,0.0029196148,0.017451096,0.019606382,0.055377666,-0.031899985,0.020055836,0.074905954,0.008565863,0.0030789417,0.07677172,0.0028281817,-0.0506032,-0.032829918,0.044448167,0.04706054,0.026794713,0.041792147,-0.012127068,-0.02636121,0.048521306,-0.03396392,-0.008685596,-0.00991354,-0.0051468075,-0.09203582,0.037156653,0.1261619,-0.0035352418,-0.05789665,0.07113788,0.041028783,0.008090229,-0.060703076,0.029746156,0.07550341,0.060923725,-0.036597215,0.015819019,-0.008918324,0.0071633873,0.029149998,0.02846669,-0.03109505,0.016032245,0.023489917,0.0028726135,-0.037509132,0.0096383765,-0.07193567,-0.07377937,-0.026502302,-0.027618464,0.092602216,0.04373374,0.033088524,-0.025362767,-0.032667015,0.06816811,0.035571523,0.02861064,0.02676796,0.087067224,0.07306643}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:47.935967+05:30	2026-10-12 18:54:46.596348+05:30
23	23	{-0.054338716,0.029644595,0.0070450497,-0.040291518,0.029302562,-0.060705487,-0.029038763,0.0029668522,0.024011757,0.08135079,-0.028841559,0.025579873,-0.017706152,0.018184662,-0.0083379755,-0.060827374,0.054697696,-0.13969235,0.041473024,-0.06420313,0.04176666,0.0025383774,-0.03061751,-0.04277873,0.022075703,-0.010001483,7.11026e-05,0.038060956,-0.00556256,-0.09092131,0.03591543,-0.038963564,0.031690236,-0.0007996544,0.021837028,0.0050204955,0.051615253,-0.0045827753,-0.00849053,-0.04179335,-0.039023217,0.0029500923,-0.0094690295,0.028902918,0.07020917,-0.05232312,-0.16532293,-0.02839416,-0.022433346,0.058251936,0.08811573,-0.12486488,0.07337901,0.010300638,-0.047958463,0.045842692,0.101336166,-0.02435305,0.0106563,-0.032928843,0.011514555,-0.049887564,-0.033166036,0.06760096,-0.031587217,-0.01644505,0.011243103,0.03920115,0.06588803,0.016661854,-0.00095944654,-0.0025640249,-0.050662182,0.037142146,0.05419413,0.056683462,0.009719553,0.0064991065,0.105794616,-0.048380382,-0.018379292,0.018542986,-0.03969956,-0.05026647,-0.017151847,-0.0018407431,-0.018476225,0.029283898,0.06597007,-0.04884221,0.00632038,0.011903859,0.019175813,0.049083088,-0.0623456,-0.010547847,-0.033093747,-0.013621934,-0.02071889,0.03994866,-0.004462736,0.10290382,0.023424275,-0.051905874,-0.06759828,-0.0039276257,0.0036247042,0.02727328,-0.0011339408,0.011298174,-0.057432685,0.0028745627,-0.03947966,0.03698285,-0.029071648,0.082990736,0.010771588,-0.019957209,0.019311188,0.009704774,0.025573822,0.0069314465,-0.0037182379,-0.02568785,-0.029277636,-0.07079804,-0.055105012,2.9872061e-33,-0.027281987,-0.021652948,-0.0949458,-0.10062559,0.07380782,-0.06973872,-0.0869786,0.041517515,-0.11063248,0.010536924,-0.05678974,0.1277975,0.040623643,0.113755815,0.036096353,-0.0842153,0.105942704,0.14153638,0.07994133,0.022015244,-0.031624388,-0.062400382,0.009515831,-0.045796342,0.11424113,0.08812356,-0.0032698482,0.14024794,0.11117289,0.010459399,-0.0075354152,-0.09864458,-0.02577677,-0.026329633,0.060333222,0.002261359,0.0030443459,-0.031603906,0.08082554,0.008462262,0.0045633125,-0.015035545,-0.030226965,-0.02293086,-0.019062174,0.051942147,0.017974278,-0.04197926,0.02383498,-0.0015699026,-0.08303311,-0.05152046,0.039753858,-0.03484111,0.018935034,-0.05493819,0.047241453,0.0042516794,0.063660674,-0.027324056,-0.024728583,0.06206813,-0.04299012,0.013689659,-0.03131701,-0.119958445,-0.009377192,-0.033467002,0.059459675,-0.051291507,-0.023455419,-0.026038267,0.027735626,0.046411708,0.034880493,-0.030551178,-0.07901515,0.07668056,-0.08262097,0.037789498,-0.026610455,-0.0725535,-0.06797981,-0.009072155,0.036282722,-0.05045499,0.033712767,0.10035992,0.00047070524,-0.013919459,0.029595803,-0.00035896295,-0.025121545,0.12941444,0.060204513,-2.7615771e-33,0.039536383,0.07409704,-0.027236285,0.04039753,0.12219894,-0.004993542,0.04137118,-0.020657793,0.005138376,-0.005906337,-0.040181868,-0.041592374,-0.016545398,-0.020498767,0.03443617,0.04276553,-0.009956822,-0.06661187,-0.049300358,0.0045327875,-0.034650747,0.021233017,-0.006078899,-0.04233533,0.026272414,0.028876517,0.0047096885,-0.028083073,-0.09898847,0.045597613,-0.108817585,-0.07542534,-0.049987644,0.029273089,0.05018997,0.016023958,0.10820602,0.059214573,-0.029344866,0.016800238,0.07259148,-0.008733618,-0.024548208,-0.029838359,0.07277842,0.07589335,-0.019577695,0.08061224,-0.10703576,0.013415973,-0.046510193,-0.008504967,0.058745194,-0.026932992,0.117251635,-0.035180382,0.029761638,0.018952712,-0.04516253,0.0357279,0.056223117,-0.08411294,-0.046221774,0.064838305,-0.018184729,-0.030367192,0.05670863,0.009419543,-0.078760915,0.024211848,0.08608043,-0.0061568297,-0.014594931,-0.0018731087,-0.046614457,0.033716634,0.011320519,-0.029710218,-0.033761892,-0.021371488,-0.040687863,-0.031768624,0.005888103,0.070351034,-0.0022607383,4.8496295e-05,-0.020086877,0.008411752,-0.037116595,-0.0043742615,-0.0558287,-0.015310185,-0.015044716,0.075087555,0.029114965,-3.6469867e-08,0.03480196,-0.032102432,0.027721183,-0.039155174,-0.0355193,-0.10612388,0.102049835,0.0067299055,0.07640787,0.078832604,0.04302949,-0.04663861,0.019573484,0.0061628562,0.03398903,0.06139419,0.022262922,0.08397747,-0.008753649,-0.074156746,0.03273026,-0.0066987947,0.043747324,-0.0117085595,0.014239647,0.023707664,0.05088607,0.088945314,0.0003212002,-0.0028229163,-0.034190573,-0.011441184,-0.041797023,-0.065174095,0.088516116,-0.0346861,-0.03787071,-0.03618868,0.099446826,0.035034116,-0.041599948,-0.06222616,-0.034055427,-0.025654225,0.042621292,0.0887437,-0.008671944,0.011563437,-0.010051827,-0.058463782,-0.07940511,-0.052900318,-0.00808806,-0.06233237,-0.03898203,0.067868665,-0.0044546183,-0.041411158,0.031341437,-0.00022610823,0.04672879,0.00014090259,-0.062157564,-0.049281415}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:53.607124+05:30	2026-10-12 18:54:46.727971+05:30
25	25	{-0.037998036,-0.08322508,-0.041670423,-0.00044048682,0.030405145,0.06700372,0.001390796,-0.06444032,-0.083016,-0.08999891,-0.03432042,0.0009146204,-0.025374401,0.028268894,-0.033522658,0.025993744,0.058948375,0.024442842,-0.0031288166,-0.060701773,-0.047204763,0.02326262,-0.051713683,-0.038668316,0.033300843,0.07843513,0.020391759,0.057150565,0.0052463235,0.05119832,0.020404413,0.08177449,0.08066455,-0.075976044,-0.061127573,-0.027588895,-0.07613899,-0.028001094,-0.0864057,0.015023477,0.025670554,0.06637486,0.0060102455,0.011515791,-0.09127808,-0.0049865204,-0.116841234,-0.043938473,0.026735239,0.09697731,-0.054386463,-0.01610507,-0.005484733,0.044997305,-0.05237336,-0.0046615517,-0.029427653,0.031056602,0.03879731,-0.013069877,-0.077100374,-0.07602963,0.017179554,-0.018178524,0.095919326,-0.0105423825,-0.056225494,0.006688587,0.0058659813,-0.012461674,-0.07182649,0.075277895,0.033638366,0.047436286,0.053603534,0.017331814,-0.038227197,-0.05096573,-0.031829663,0.013744685,-0.046944488,-0.07324732,-0.021842584,-0.06433669,0.011254495,-0.0456904,0.04951975,-0.09067095,-0.030122114,-0.0061750817,0.001934867,-0.0077271885,0.029348828,-0.06815173,0.0045923125,0.06774348,0.014616477,0.0053391987,-0.03292468,0.010104918,0.0020636348,0.003973188,0.00833453,0.0042901766,0.015087239,-0.028219737,-0.008450713,0.061862554,0.06555461,-0.05231357,-0.01574671,0.057764754,-0.031990606,-0.030301997,0.096906185,0.020719746,0.08615325,0.011211238,0.06679485,0.044813875,0.0181409,-0.013767406,0.02410534,-0.009800528,0.011889083,0.07470356,-0.034435138,2.337264e-33,0.03632202,-0.03665173,0.020200526,-0.031409416,0.026922824,-0.10798427,-0.11020064,0.021584386,0.027051222,-0.02820077,0.06574287,0.15325621,-0.033179983,0.04398919,0.029437857,-0.028211879,-0.053645547,-0.010147819,0.021904692,-0.06605087,0.0036952638,0.039840195,-0.0027345738,0.0056203566,0.011548356,-0.020363456,0.06823757,-0.011187424,0.030118268,-0.007376313,-0.076167755,-0.042033937,-0.031419832,-0.04294571,-0.016329352,0.07729111,-0.028444663,-0.050150983,0.06683187,-0.110077314,-0.045398433,-0.076912336,-0.036460772,-0.115515575,-0.110291645,-0.054030623,-0.0918006,0.06437242,0.066447735,0.02239271,0.05261837,0.002568819,-0.00057820464,0.087502174,-0.03642573,-0.037707135,0.004306103,0.026356097,0.038369942,0.0011292828,0.06370564,0.0052006333,0.050662182,-0.04127942,0.03253266,0.03456965,0.05990546,0.034183744,0.061653744,0.06778283,-0.013411221,-0.010148149,0.09434367,-0.0045929365,-0.00027570353,0.019057479,0.019268898,-0.052192193,0.033487678,-0.08425555,-0.026381984,0.051727943,0.004081216,-0.060171694,-0.062533334,0.043851312,0.0068254224,-0.07437528,-0.1016961,-0.08105418,-0.06914779,0.04636133,0.07146419,0.0880401,0.026017621,-3.3988394e-33,0.0047925864,0.01584461,0.09575093,-0.027867822,0.08302359,-0.04327117,-0.03041602,0.05256787,0.036920886,0.03254536,-0.010752876,-0.06475838,0.0895847,-0.081112444,0.021840623,0.068429776,-0.019738656,0.03170446,-0.017616494,-0.024462728,-0.07447512,-0.01426812,-0.018313596,-0.0041993065,-0.07288767,-0.03782718,0.018392047,-0.030320512,0.040522106,-0.07184824,-0.050279707,-0.02127955,-0.08834088,-0.11014755,-0.015949057,0.0067201215,-0.04564511,0.04205403,0.015411137,0.038908944,0.008821873,0.064863406,-0.0317723,-0.04780419,0.033837765,0.0045492067,-0.046627168,0.08055054,0.009808566,-0.07899599,0.08174512,0.027511882,0.08606014,-0.0113617135,-0.06722169,0.026153274,0.08568601,-0.011060057,0.040428966,0.08474322,-0.03776453,-0.0642822,-0.013057039,-0.11249477,-0.0058833803,0.038067512,0.043126866,0.018893357,-0.051427804,0.02205577,0.031135183,0.0042241667,-0.038189705,0.030324869,-0.05526058,-0.05538926,0.03029083,-0.023999022,-0.0010996496,0.0323324,0.043206286,0.057394512,0.011848105,-0.042164758,0.07616082,0.034263548,0.033434864,-0.043740228,0.029528929,-0.03251685,0.030648565,0.027348727,-0.0037914144,0.021824634,-0.08659028,-3.1102697e-08,-0.04837187,-1.5292613e-05,-0.032303393,0.068649806,-0.026823876,-0.015861686,0.052684646,-0.021482091,-0.021225939,0.029496623,0.077300906,-0.042936377,-0.01986624,0.05329679,-0.045355096,0.05878454,-0.036599096,0.07063006,-0.014705329,-0.052468065,0.026854543,0.026359849,0.0466519,0.03760491,0.006183095,0.05444202,0.035736803,0.08873184,0.1047589,0.045998618,-0.07066271,0.07464124,0.04513385,-0.07723832,-0.011227296,0.044059627,-0.016444158,-0.075033575,-0.08888938,-0.008378417,0.0007371783,0.054060195,-0.018219935,0.024440797,-0.02110782,-0.030515773,0.082688674,-0.046173733,0.021436,0.14660434,-0.016909918,-0.06622167,0.07228739,-0.028208198,0.10276795,0.012359013,-0.057573665,0.09657263,0.039490014,-0.06755459,-0.0084804855,0.00858551,0.03554547,0.11415698}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:16:58.291834+05:30	2026-10-12 18:54:46.833193+05:30
27	27	{-0.11495317,-0.051322978,0.06007416,-0.08900324,0.018227618,-0.020220723,0.10783889,-0.042278785,0.022825858,-0.0016212906,0.036641505,0.016374752,0.01056438,-0.011686436,-0.02240762,-0.06593427,-0.028800787,0.06989855,0.023662508,0.015218565,-0.004328509,-0.07019406,-0.009693723,-0.028317994,-0.046916686,-0.008929126,0.07900339,-0.011667855,-0.017278902,-0.031060683,-0.014953801,0.04110435,0.025361817,0.009127576,-0.08292367,-0.03573277,0.018058924,0.065499954,-0.024119228,-0.08975542,-0.0897196,-0.11608633,0.020997705,0.053656057,0.008658975,0.02942914,-0.09259644,0.014890746,0.006379303,-0.0046910057,-0.031524748,-0.0074467575,0.07167015,-0.0016600926,-0.0237311,-0.015435381,0.04237871,-0.029631153,0.10690917,0.03884168,0.047814894,-0.0330332,-0.020587621,0.025285864,-0.015017447,0.11968583,0.011020229,-0.047942907,0.059170563,0.0031333219,-0.04176748,-0.0064792656,-0.026364645,-0.045310516,0.05266786,-0.022134187,-0.06832404,-0.062220983,0.088968396,-0.025224024,-0.03147808,-0.039168656,0.00775252,0.015538511,0.08423261,0.028649231,-0.052928027,-0.015799258,-0.012582844,0.061417446,-0.079996355,0.023193972,0.09853303,-0.07360976,0.03475219,-0.017535232,-0.011897997,-0.017864846,-0.018579276,0.02757563,-0.043736283,0.0024505402,-0.045184653,-0.0006943699,0.14407103,-0.021501733,0.03538198,-0.121880785,0.10943648,0.008451218,0.0027209085,0.0030910124,-0.032809716,0.032570455,0.047986817,0.043515816,0.059190795,0.10324481,0.044207428,0.050966054,0.053385556,0.011795635,-0.030430699,-0.085359395,-0.015292983,-0.015035157,-0.043337245,3.9552832e-33,-0.038317516,0.05409841,-0.03873817,-0.025343016,0.014836755,-0.07376069,-0.04687929,-0.05716126,-0.029633118,0.0179566,-0.07834047,0.048567794,-0.040101122,0.100700654,0.004796689,0.025590627,-0.007516385,0.10190567,0.01860144,0.010293458,0.021411862,-0.06494015,0.06699375,0.061139163,0.020437816,-0.023017583,-0.012942591,0.038760874,0.063040435,0.043116912,-0.049888056,-0.01943145,-0.05880939,-0.021016898,0.009068352,-0.0075338446,0.090556264,-0.11059098,0.05240941,-0.06653812,-0.054520912,-0.05305865,-0.008515017,-0.08775718,-0.09391177,0.0020018176,0.033856396,0.0180152,0.054626614,0.025603518,-0.094832525,-0.004984833,-0.0056918254,-0.044547938,-0.07434133,-0.100951776,-0.060143266,0.0543257,0.0066556945,0.06162411,-0.020638805,0.07556414,0.026749728,-0.010719357,-0.007658742,-0.0827727,-0.009084607,0.03580651,0.01829589,0.03565071,0.038984276,0.03595929,-0.06797705,-0.012667327,-0.011682321,-0.007931478,0.07917272,0.044425767,-0.06405451,0.046396367,0.021350963,0.07706904,0.026152693,-0.0116507625,-0.025941117,0.016259976,-0.04650281,-0.042468857,-0.08812241,0.009204886,-0.020509211,-0.047148265,-0.026846746,0.10223943,-0.076952964,-5.3114242e-33,-0.0528834,0.0029564905,0.015935944,0.03783451,-0.008501297,0.028675832,-0.0081980135,0.04150884,-0.05198323,-0.0736848,0.045491345,0.058976542,0.11353046,-0.05612178,0.048389073,0.025012719,-0.04459725,0.041129336,-0.016416548,-0.019556439,0.037543282,-0.045767535,-0.10621088,0.008839593,-0.01566137,0.04926952,-0.07404835,0.06417681,-0.014037243,-0.0023740528,0.0001954499,0.087497674,-0.065005235,0.01790748,0.027946267,-0.050786708,0.022769678,0.06864063,-0.018745933,-0.021869907,0.077429414,0.006607678,0.007848447,-0.038505066,0.024616325,-0.029195482,0.029561697,0.03145703,0.0111521175,0.009111909,0.0663067,0.018195009,0.022409266,-0.015987683,-0.11263284,0.019110328,0.027144767,0.05844839,0.013110194,-0.0020423294,-0.057830043,-0.026674064,0.018847112,0.11213501,0.036083695,-0.03353535,0.039344277,0.062845595,-0.08033568,-0.06965417,0.13309501,0.01086739,0.006045057,0.026120512,-0.0067858943,-0.041667517,-0.0011278038,-0.10853985,-0.0667577,-0.02266541,0.10009611,-0.003528371,0.023194272,-0.0056100367,-0.05003088,0.09809758,-0.01661012,0.024627069,0.02821301,0.044515535,-0.045184687,0.08562254,-0.09544974,-0.042872723,0.028179675,-3.751858e-08,0.052181523,0.044293683,0.05876609,-0.10039677,-0.06499194,0.05001254,-0.05449869,-0.026888268,-0.006122917,-0.08938449,0.038405646,-0.027307726,0.050411616,-0.06809167,0.009866135,0.029920043,-0.027585596,0.04772906,-0.04975482,-0.056466248,-0.021230021,-0.005565637,0.04289051,-0.017220993,-0.05038993,0.0038891588,-0.003750897,0.098480985,0.033388913,-0.04694386,-0.002016948,0.024196751,0.02676673,-0.04360525,-0.03227867,0.10076841,-0.08474523,-0.06971,0.014541458,0.01154336,-0.018115574,-0.038387913,-0.099079356,0.011263463,-0.10291041,0.0031834391,0.011536813,-0.015111072,0.020629784,0.020041043,-0.00850631,-0.022929987,0.018826354,0.09851106,0.04240008,0.089509614,0.03704117,0.0011892767,0.11551949,0.001996493,0.057794128,-0.00091789203,-0.04523635,-0.014108335}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:07.029951+05:30	2026-10-12 18:54:46.934148+05:30
29	29	{-0.10117768,0.011712467,-0.006719844,-0.039137322,-0.019925902,-0.011915963,0.051965382,0.057021707,-0.09134335,-0.009606321,-0.01173838,-0.07518102,0.065986454,0.0018524189,0.06323011,0.02969378,0.065306135,-0.03955599,0.03308743,-0.039933234,0.03325233,0.07325294,0.008866146,-0.07455357,0.03321226,-0.00065258524,0.024808683,-0.05001847,-0.0067912163,0.026025485,0.08983015,0.04134787,-0.0049697836,0.07228003,0.01729768,-0.020126412,-0.08049348,0.0016471291,0.0006743646,-0.037789106,-0.08832149,-0.04729441,-0.045604765,-0.03318981,0.07705092,0.009318463,-0.059862517,0.03680711,-0.029420743,-0.023997054,-0.040347368,-0.022427458,0.07595187,0.09553196,-0.029627986,-0.024372676,-0.0026065263,0.050963193,-0.030903937,-0.052700732,0.0392011,-0.00012226199,-0.00974113,-0.00608388,0.049141053,0.04344184,-0.056857955,0.03670733,0.038105186,-0.06634695,-0.03597529,0.008426207,-0.022437265,0.052149862,0.009958548,-0.0019943938,0.022834001,0.05620515,0.09820762,-0.08588975,-0.06398531,0.022525325,0.017567951,0.02419914,-0.037898004,0.028618127,0.023727084,0.013896216,0.08943531,0.008091603,0.049136996,-0.012110662,0.09758218,-0.0047777393,-0.010471347,-0.05075928,-0.042783134,-0.04843664,-0.07157876,0.089115344,-0.05120588,-0.018702468,-0.05475425,-0.081213646,-0.05254209,-0.0255266,0.069380835,-0.0015848903,0.05778924,-0.057666317,-0.06752495,-0.056734152,-0.026271392,0.0069107874,-0.015799968,-0.03806462,0.025902774,0.07414758,0.043700676,0.05178356,0.009270368,0.005335554,-0.09376138,-0.06910031,0.06921439,0.01585358,-0.041408274,3.9146276e-33,0.032158993,0.0638238,-0.019377448,-0.03316534,-0.0014783513,0.017610282,-0.0049769003,-0.047552902,-0.06402938,-0.014686286,-0.050575297,0.06401284,0.023322517,0.023362517,-0.0011788588,-0.030348549,-0.0680041,0.07266517,0.019958198,0.07677589,0.04459046,0.0201782,0.06057906,0.01346475,0.054683145,0.029738145,0.012079636,-0.013383783,0.07724912,0.03792776,-0.029502086,-0.010961289,-0.010189676,-0.050823417,0.058718674,-0.017749164,0.04456593,-0.060803887,0.03403989,-0.0013197449,-0.06995413,-0.0380712,0.09030343,0.016477969,-0.023237552,0.0012094837,-0.023523415,-0.005583812,0.049762018,0.033074763,-0.04289745,0.028311308,0.00321435,-0.036209997,-0.0005268358,-0.10881088,-0.005434645,0.025403213,0.05998834,-0.10131334,0.036509644,-0.10727916,-0.019382188,-0.05427376,-0.021679955,-0.07006296,0.004991073,0.0076999436,0.07766069,-0.0193784,0.009883026,0.034084976,0.0095977,0.08989251,-0.10627875,0.070663214,0.04162693,-0.008319194,0.01989253,0.012232948,-0.0400483,-0.10339619,-0.041051798,-0.09907707,0.1390315,-0.0067572603,-0.04612785,-0.053272422,0.09553309,-0.005540755,0.0028936695,-0.008557413,-0.0777924,0.06965526,-0.0017037197,-3.3102637e-33,-0.017469179,0.042508606,-0.09132103,0.011339366,0.04841773,0.003048661,0.016980726,-0.035274923,0.10874048,0.08218244,-0.07349702,-0.053079564,0.068184316,0.030038098,0.0326745,0.049225118,0.00061929796,-0.00013823982,0.03655316,0.047898933,-0.06254312,0.080583885,-0.10509444,0.05571956,0.030168856,0.02585294,-0.0913918,0.0039376747,0.0069668507,-0.034303714,-0.018585604,-0.14443438,-0.08455947,0.012492295,-0.034787185,-0.0026087149,0.14217086,-0.084664635,-0.02418164,0.023177015,0.09665362,-0.025946457,-0.062211197,0.03545047,-0.040821087,-0.058465626,-0.03224256,0.022920847,-0.009308743,-0.043131787,0.09088503,0.02499856,0.112470455,-0.033456493,-0.030617412,-0.045750212,0.064976916,-0.01599606,-0.009042283,0.017673882,0.032129828,-0.034142,-0.010535431,0.07730436,0.02451237,-0.0666929,0.027636884,0.031818625,-0.03349557,-0.1203921,0.06732628,-0.16760275,-0.028536048,-0.031636324,-0.0056771254,0.050948113,0.0063447845,0.034195937,0.008505104,-0.007875516,0.029965004,-0.07046931,0.07688739,-0.0240273,0.034962147,0.019370712,-0.011851051,0.039058104,0.055503152,0.037863277,-0.07080706,0.013502171,0.037523635,0.12049891,0.076375045,-4.1006757e-08,0.09545311,-0.06510781,-0.028233387,0.04665136,-0.011536695,-0.01546807,-0.071099736,0.007979849,-0.053612206,-0.020733131,0.00046591792,0.018268745,-0.032603186,-0.05558539,0.077050224,0.027240692,0.0033954524,0.052239507,-0.028372893,-0.0045063486,0.07904063,0.006418687,-0.004785318,-0.010354287,-0.052731685,0.02111096,-0.0009692804,0.07270737,-0.021596026,-0.03129238,-0.033626717,0.0229579,-0.0070104296,-0.05155081,0.01489981,0.06845775,0.0024556094,-0.008546156,0.07635351,0.016778005,-0.015289007,0.0026652438,-0.008983024,-0.025861569,0.04310214,0.02424258,-0.03259082,-0.121119946,0.024509264,-0.15452261,-0.04252822,-0.058237463,-0.019465594,0.054164182,0.002538438,-0.013071779,-0.020882795,0.022521686,0.036098007,-7.563723e-06,0.022779439,0.09398476,0.014324245,-0.014595263}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:07.586289+05:30	2026-10-12 18:54:47.049791+05:30
31	31	{-0.121616654,0.07103491,-0.067739934,0.026046129,0.059757125,-0.043823022,0.02581156,0.056812305,-0.072182305,-0.016215747,-0.0378085,-0.05129957,0.07233175,0.045906845,-0.032705657,0.004098747,-0.00512098,-0.048063997,0.04422418,-0.06341086,-0.03883514,0.02028561,0.0068981564,0.045422155,0.016691308,-0.059559334,0.030734563,0.008283838,0.016742198,-0.023515016,0.0025229792,0.05179361,0.07456889,0.08390557,0.014940822,0.037664924,0.007163944,-0.0071034706,-0.012966801,-0.0062202914,-0.054228295,-0.059228115,-0.098939955,-0.024138797,0.06076635,-0.021212598,-0.05290383,-0.007282859,-0.050833758,0.11694917,-0.066217266,-0.0020378875,-0.00089269946,-0.016889283,0.025678003,0.0435849,0.07853541,-0.041995,-0.027972847,0.0008536761,0.016150912,-0.05465514,-0.05465739,0.0086405305,0.072456054,0.06721129,0.004565837,0.10400485,-0.060170837,-0.09192958,-0.04018682,-0.020118404,-0.023486804,0.11697811,0.008538132,-0.014616234,0.03431501,0.0064473026,0.021945177,-0.023187092,-0.09000751,-0.0029365541,-0.007242712,0.05085691,-0.03519383,-0.0013612754,0.03362404,0.011834673,0.020281604,0.0442901,0.017827917,0.0008146299,0.008977159,-0.032702304,-0.020209627,0.03337802,0.0014436756,0.024517624,0.1209342,0.014445651,-0.01174429,-0.010228934,0.09290122,-0.047654554,-0.11051431,-0.115171954,0.0588508,0.05252751,0.07629554,0.0057418393,0.04676162,-0.046294805,-0.00518025,-0.11704943,-0.026662495,-0.009468734,-0.0017438313,-0.012933223,0.11649749,0.060921855,0.030296043,0.07127662,0.016989058,-0.020047098,0.024772985,-0.05218729,-0.0022095044,5.4182473e-33,-0.0752443,0.016934354,-0.008278506,0.016412087,-0.033706766,0.009173344,0.01435288,-0.0049460833,-0.015055471,0.017167732,-0.037522923,0.111654036,-0.042536084,0.09905425,0.06527126,-0.07071194,-0.023809234,0.053917248,0.0214698,0.025583614,-0.052342135,-0.07824298,0.07319276,0.029052028,0.052132554,0.06057646,0.049768146,0.07796453,0.020924147,0.00027655583,0.09334746,0.0059543,0.043446813,0.036592558,-0.040375333,-0.040887367,-0.06808656,-0.0029699025,-0.018491492,0.018483294,0.006607081,0.04904845,0.072163865,0.03690754,-0.11436481,0.009243854,0.053081755,0.014754604,0.07683334,-0.0033979078,-0.040865332,0.013843674,0.055840094,-0.03373287,-0.004370392,-0.002368866,0.026828846,-0.10790729,0.008944157,-0.012293738,0.017601162,0.03274405,0.027105361,-0.009675803,0.020230789,-0.040393177,0.05238804,-0.0027119827,0.015822187,0.025071314,-0.03162837,0.00852773,0.08601634,-0.014592353,0.08000941,0.017698979,0.010150665,0.044000078,-0.07158366,-0.078443915,-0.11931179,-0.01537435,0.1136467,-0.054198164,-0.043021806,-0.006495339,0.00357388,0.0066565517,0.036233697,-0.02070274,0.018883139,0.011001455,-0.10593822,0.029218296,0.04157281,-4.549371e-33,0.024181215,0.022055568,0.026106142,0.06524591,0.022062311,-0.044572674,-0.048459917,0.027255949,0.028211346,0.07903777,0.059800748,-0.033714026,-0.05675735,0.005300735,0.012825814,0.078891486,-0.03132389,-0.06416236,-0.024075862,-0.036605503,-0.09468101,0.04283531,0.014092432,-0.0697298,-0.08544777,0.052324273,-0.02645784,-0.036846973,0.02279256,0.024083054,-0.03292489,-0.094462946,0.005493089,0.08244527,-0.056160763,-0.042387225,0.050461642,0.08677795,0.07175995,-0.05611615,0.022979675,0.0066690375,-0.05161714,-0.0068465197,-0.05362608,-0.102910854,-0.030252188,-0.029245554,0.0015846045,-0.029485244,-0.010016214,0.09043415,0.04202811,-0.13857421,-0.093824886,-0.0007513236,-0.017843828,-0.0017856616,-0.08453872,0.020480843,0.0031232545,0.07066414,0.09827472,-0.02344823,0.044154644,0.011311328,-0.026745513,-0.03750789,-0.096817486,-0.00943475,0.043791987,0.009215839,0.015110571,0.01227144,0.013086231,-0.06851168,-0.010091912,0.017329182,0.010886867,0.013246731,0.04656473,0.01637246,0.006963958,0.055036508,-0.04004595,-0.045566168,-0.02449995,0.047592722,-0.029016854,0.0013401276,-0.09611926,0.015614963,0.002667245,0.060424685,-0.04573528,-4.0873168e-08,-0.06584659,-0.04875844,-0.023729874,-0.005647756,-0.015869021,-0.017939871,-0.022128299,0.061715372,-0.06232587,0.027713208,0.017882029,-0.05269764,-0.08741286,0.05727435,-0.020308405,-0.041575637,0.004467023,0.097700916,-0.08713759,-0.09115179,0.009601556,0.067839414,0.03364269,0.08014629,0.07223694,0.009255713,-0.058482606,0.12176634,0.082375795,-0.024622776,-0.010381972,0.07649213,-0.0051017087,-0.03168346,0.029768802,0.0112830335,-0.020893807,-0.002578199,0.01501334,0.046620414,-0.014236105,-0.03759824,-0.09776784,0.01816251,0.049712706,-0.07929949,-0.10124395,-0.07155432,-0.0050328267,-0.026683778,0.024366124,-0.05399789,0.0080742175,0.04706927,-0.031044183,-0.019495038,-0.0053168805,-0.0670189,0.098370336,0.061542742,0.030439185,-0.11360655,0.07654023,-0.05306423}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:13.945133+05:30	2026-10-12 18:54:47.155255+05:30
33	33	{-0.07426471,0.030666221,0.040671613,-0.0021479107,0.010883684,-0.0832706,-0.04894263,0.0507944,-0.002877314,0.02444362,-0.03563383,0.03436994,0.06602876,-0.031509582,-0.04546558,-0.017865883,0.0348156,-0.01577415,-0.025343575,0.017066654,-0.09162892,0.012121856,0.009353982,0.019241149,0.021579692,0.022124587,0.0024421914,-0.028194295,-0.02304434,-0.07331179,0.01941287,-0.03580753,-0.04082146,0.05193,-0.07180567,-0.005907099,-0.00019307346,-0.053923707,-0.041562025,-0.123415105,0.022303324,-0.06076225,-0.08179521,0.0011117981,-0.006062307,0.074286275,-0.0079001095,-0.02189363,-0.0063869706,-0.03179148,-0.050348677,-0.07185104,-0.08287557,0.075439766,-0.05785328,0.06172029,0.027092405,0.011851937,-0.0090867635,0.051171176,0.018229395,-0.04683215,0.02906474,0.006366168,0.03168373,0.089001715,0.03630668,0.03851179,0.0035760605,-0.048883464,0.057796575,0.079220936,-0.03415595,0.04591592,0.012741589,-0.059720542,-0.0045123873,0.030488059,0.02484309,-0.0014742549,-0.09040974,0.008982483,0.01494772,0.033823892,-0.04399312,-0.12500995,-0.07724144,0.044162184,-0.061203796,-0.02466864,0.06321235,0.020026304,0.04060134,0.01003226,-0.020073937,-0.0015115158,-0.0028835663,-0.015263654,0.025520701,-0.017942125,-0.029596971,0.07411532,0.025681332,-0.0400614,0.049640473,-0.0063086073,0.039094076,-0.019541614,0.013930397,-0.059101515,-0.027253907,-0.020547712,-0.09142606,-0.02346069,-0.045945294,0.035863906,-0.055151172,0.058557607,0.001586374,0.027423663,0.05155135,-0.055149857,0.047121327,-0.08724089,0.028580202,-0.02307556,-0.029610494,3.5679927e-33,0.007902921,-0.0038771397,0.05116543,-0.049905635,0.011682678,-0.025442705,-0.05283713,-0.00085044216,-0.14540271,-0.0610733,-0.0075938455,0.10922669,-0.024032157,0.021556474,0.108054526,-0.005351771,-0.06806056,0.022432826,0.12097118,-0.05271926,0.05020062,0.090381615,0.025005898,-0.031708054,0.0458835,-0.027576026,0.09396816,-0.07165071,0.041104257,0.033527736,-0.02336999,-0.026228944,0.0005027466,0.046932038,0.026295334,0.07305032,-0.11373887,-0.046001118,-0.054839946,-0.006290401,0.006044814,-0.0437349,0.0013256259,-0.048593167,-0.122125514,0.0040924656,-0.010460243,-0.05475926,0.0007622741,0.12604141,-0.017015908,0.01276086,-0.048703875,-0.011944328,0.031182423,0.037729785,0.025465198,-0.012414147,0.022858007,-0.039530084,-0.006654866,-0.0066667553,0.0236308,0.040567514,-0.10245329,-0.05051096,0.042689964,-0.018828664,0.06587727,0.020213515,0.04581561,-0.0029997358,0.0138181,-0.036396615,0.036979277,-0.014768812,-0.03024766,-0.030331803,-0.033518318,-0.08304301,-0.03840453,-0.07050243,0.00077095674,0.060090836,-0.06465057,0.032409076,0.014852942,0.021874782,-0.066821225,0.009118607,-0.034174632,-0.004606566,0.098870404,-0.004809327,-0.057659805,-2.9376485e-33,0.035557862,-0.07589206,0.025959566,0.06558207,0.035042044,0.018301483,-0.033745844,0.036306903,-0.026445666,0.06756004,-0.07786935,-0.010648599,0.08565278,-0.034594283,-0.052625857,-0.0109109795,0.016513433,-0.1392475,0.001011694,-0.0061820447,-0.042504314,0.06863004,0.048149772,0.078114934,0.008708361,0.019975793,-0.10641236,0.030764587,0.010488929,-0.040239654,-0.058344766,-0.041322332,0.03383622,-0.1269001,0.0012364745,-0.015832245,0.030183658,0.030604685,-0.038266942,-0.022468287,-0.05080866,-0.061945792,0.0035148186,-0.06582869,-0.009767296,-0.021791408,-0.0420518,0.079620235,-0.009478782,-0.0067829336,-0.009532739,0.019459195,0.028740948,0.032506797,0.058480956,-0.0098239295,0.052843343,0.060725693,-0.064744525,0.07166692,0.07754029,-0.07351248,0.063849665,0.04078319,-0.060872305,-0.016225848,0.041292857,-0.019517051,-0.062154327,0.05606959,0.022224173,0.0053987475,0.03329217,0.0035031224,0.027013058,-0.032993197,0.07251645,-0.10308384,0.01736483,-0.0056305905,0.03955861,0.041471522,0.011933759,0.0836708,0.0523405,-0.12110368,-0.004191278,0.01799529,0.024801923,0.012370162,-0.06101693,0.06776401,-0.15383185,0.037927262,-0.02819805,-3.3359985e-08,-0.0009008506,0.006178545,-0.013397692,0.101812534,-0.023977265,-0.052178625,0.05441305,0.08632408,0.00045229157,0.030178724,0.14745753,-0.11721838,-0.06278591,-0.051060803,-0.034646504,0.05359297,0.07180599,0.043226656,-0.017434925,0.033703838,0.024866855,0.015731018,0.038601037,-0.015597475,0.08427689,0.03357489,0.048708834,0.009399842,0.010106336,-0.027138283,-0.050735425,0.018232796,0.016684834,0.01445449,-0.0009772535,0.08506425,0.0149966115,0.07525754,0.02073372,0.04091262,0.07072011,-0.0025074973,0.011743661,0.016148346,0.009181359,-0.008488379,0.010125132,0.049661588,-0.013615693,0.11922363,0.013108776,-0.088452585,-0.011099666,0.13308375,0.052164562,0.025444323,0.030501667,0.0070359632,0.040750172,0.101885825,0.13792433,-0.0018790445,0.024982493,0.08363521}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:14.479257+05:30	2026-10-12 18:54:47.263906+05:30
35	35	{-0.02078142,-0.07470482,0.0030753498,-0.049174692,0.019904442,0.0018572413,0.020589067,-0.035447937,-0.010030526,-0.04719413,-0.047201425,-0.042312156,0.0031544494,0.017501734,0.05899517,-0.003186367,0.053355098,0.026330777,0.025086397,-0.07807951,0.03807137,0.08556306,0.059073243,-0.0064854813,0.020417916,0.023353618,-0.01874864,-0.051512998,0.08463438,-0.033935897,0.036188647,-0.03340957,0.11212949,0.06259219,-0.11400931,0.06557118,0.0037368503,0.007388531,-0.051809795,-0.004885376,-0.07226108,0.008733817,0.016387723,-0.04644169,0.09301447,-0.062112574,-0.15123618,0.01722628,-0.00880847,0.052611448,-0.12036119,-0.1278716,0.09063157,0.058145367,-0.09073431,0.10187507,0.035757285,0.05246246,0.008810925,0.010993753,0.034829628,-0.08297285,0.005193785,0.019890003,-0.03415474,0.041473735,-0.052539017,0.060563873,0.044340055,-0.017585812,-0.07505663,0.06265209,0.033631384,0.058076773,0.010931596,-0.0070233145,0.041470014,-0.05679252,0.12929611,0.044379164,-0.006420044,-0.10999208,0.0025074387,0.010007765,0.0006681616,-0.055971514,-0.020464096,-0.018531809,-0.02011008,0.0066680145,-0.09251362,-0.002310739,0.014518896,0.018618958,-0.018011838,0.07384473,-0.045968913,-0.030361842,-0.023951447,0.022054274,-0.04853959,-0.053810116,0.008024888,-0.07972186,-0.09406741,-0.041914605,0.0075942674,0.023795832,0.055680037,0.0015207835,-0.045765076,-0.012948912,0.004441084,-0.028853068,0.11462354,0.031671952,-0.07547064,-0.03976161,0.054490525,0.03829702,0.048311304,0.08767732,-0.0306573,0.022510521,0.10802984,-0.033001967,0.039384324,1.3115004e-33,0.08957256,0.044874586,0.057380848,0.048691012,0.053249653,0.0025751828,0.0147753,-0.0069278586,-0.075627044,-0.028393824,0.051852062,0.04000969,-0.018783636,0.07238381,0.02003033,-0.078565225,-0.0008689549,0.082516775,-0.01993591,-0.019665444,0.06318115,0.019566514,0.023086784,0.055537887,0.10931496,0.015990105,0.07313844,-0.028024213,0.11390092,0.0013925821,-0.07654076,0.031454463,-0.08720849,-0.013874936,-0.0041008648,-0.036944263,0.016153784,-0.0593259,-0.026655303,-0.047831282,-0.06505657,-0.028742053,0.009622241,-0.036217585,-0.079911575,-0.0547633,-0.032917704,0.014541124,0.057402395,0.013649898,-0.07556924,0.04114233,-0.029856138,0.04337523,0.04173046,-0.03948801,0.041706737,0.030210169,-0.015019632,-0.020695347,0.0070118685,0.017886506,-0.033983026,0.034413014,-0.00076125143,-0.004241407,-0.0007167867,0.018071312,0.074159995,0.034524478,0.009483527,-0.002175406,0.011014744,0.038954694,-0.042832945,-0.012739202,0.011469541,-0.05594236,0.012287476,0.07996171,-0.016476551,-0.052176617,-0.039391518,-0.01899529,0.014828713,-0.029988527,-0.033064578,-0.037743058,0.08456925,0.05275619,-0.018102678,0.06697222,-0.029975032,0.058317937,-0.07405857,-7.828114e-34,-0.03870651,0.07123862,-0.057540745,0.14431109,0.08489727,0.024643697,0.059284,0.06283692,0.08147556,-0.053175796,-0.0037857955,-0.0515659,-0.020693284,-0.04332089,0.026984463,0.025150072,-0.027020754,-0.036797516,0.006375527,-0.0064353463,0.033905257,0.01763046,-0.021146819,-0.013676136,-0.04188714,-0.058316942,-0.10800994,0.030308122,-0.017182374,0.03440748,0.0478016,-0.036175344,-0.08182699,0.0056878617,0.02517101,0.04210646,0.02719147,-0.016720302,0.01461146,0.0033153805,0.09641719,-0.06346731,-0.03618977,-0.057638943,0.041147582,0.013167751,-0.10674389,0.022872444,-0.043695264,-0.023586664,-0.0027591514,-0.0030939095,0.013878675,-0.06644243,-0.07074312,-0.079490036,-0.004021053,-0.051655162,-0.018059332,0.011560548,0.019633457,-0.020544384,-0.02280395,-0.037783895,0.012301096,-0.0068832636,-0.027421892,0.077126555,0.010451819,0.00084414805,0.055170104,0.011192263,0.032246392,0.07177456,-0.036354057,0.047298957,-0.06823843,-0.018573241,-0.016168196,-0.008680108,0.07331278,0.043866627,0.054315668,-0.00268076,0.061889965,0.12704043,-0.041632485,0.04282757,0.026913118,0.04285196,-0.08146918,0.06492505,-0.032490473,-0.010742119,-0.022647647,-3.7325627e-08,-0.054329805,-0.0326224,0.030177293,-0.048329167,-0.038280282,-0.05154399,0.024112651,-0.043881107,0.04295689,0.0017253425,0.015099941,-0.05956558,0.020402296,-0.028271152,0.022660509,0.010417251,-0.00641653,0.08862159,0.01504881,-0.08833418,0.10091575,0.041506324,-0.04059361,0.058354855,-0.025270043,-0.025413781,0.015243722,0.1391562,-0.084969796,-0.043886594,-0.027836414,0.050725617,0.05264851,-0.038660437,0.052034516,0.06097466,-0.07092512,-0.04181192,-0.017360186,0.074910246,-0.054041497,0.06388034,0.0063489326,-0.028386852,0.02262017,0.020530432,-0.058834083,-0.17038114,0.07278994,-0.056520186,-0.06914083,0.0016353475,-0.01719724,0.032328878,0.0800667,0.087674774,0.006394826,-0.04345818,0.008708221,0.03939579,-0.003912487,0.010652785,-0.015830413,0.004397061}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:19.599026+05:30	2026-10-12 18:54:47.366408+05:30
37	37	{-0.05081049,0.031682685,-0.013706246,-0.08033016,0.055581175,-0.064134985,0.044391725,-0.03350399,-0.04654171,0.018573217,-0.035265453,0.0077433446,0.0054819686,-0.027393017,-0.084311925,-0.013916941,0.063834496,-0.015553868,0.06792008,-0.078175,-0.06769071,0.03345422,-0.03373117,-0.09073061,-0.0920005,0.047711894,0.027055826,-0.0021594414,-0.067941934,-0.05873037,0.021158488,0.010001819,0.006398295,0.012365008,-0.040881332,-0.041572373,0.039302077,0.03862747,-0.014356873,-0.018438922,0.040635277,-0.0994877,-0.023943467,0.04967857,-0.034417577,0.016031507,-0.10672763,0.041137774,0.029102406,-0.040151563,0.0008318648,0.0064529534,0.030585146,0.06365376,0.14408211,-0.036206678,-0.0005978711,-0.042236898,-0.07106483,0.054410003,0.008203262,0.018593172,0.028858425,-0.0018396764,0.04717326,0.039715525,0.03849864,0.055539347,0.07966372,-0.043139037,-0.03174575,0.08302031,-0.07772674,0.05972594,-0.048168913,0.046114378,0.012158875,-0.057785098,0.035862066,-0.118101105,0.012814486,0.108591355,0.03792495,0.024213463,0.049023136,0.0060399123,-0.012220808,-0.012438824,-0.008805717,-0.013029199,-0.0052916035,0.022979494,-0.02477306,0.01823156,0.008917685,0.0022985742,-0.039255537,-0.05820947,-0.07415641,0.048850372,0.05787009,-0.006309651,-0.059486832,-0.022912053,-0.021324834,-0.01483203,0.053850166,-0.051931243,0.036382463,0.07224002,-0.0147843035,-0.009499811,-0.0056165652,-0.03733134,0.0005928583,0.037954286,-0.015296778,0.075228445,-0.058860686,0.01733771,-0.035820797,0.009348522,-0.026979791,-0.030919917,0.02420347,0.04147185,-0.0015909458,4.9588604e-33,-0.06976517,0.068243645,-0.13663621,-0.09175183,0.050383125,-0.030148553,0.0020964262,0.043621376,-0.08003057,0.034611855,-0.08177763,0.05573138,-0.04771312,0.03151557,0.09022332,0.022793896,-0.012569901,0.1010449,0.10366248,0.014161216,-0.03422473,-0.08493581,-0.0068213567,-0.030549733,0.040059708,0.08636075,-0.08539921,0.00659368,0.110755615,0.02039024,-0.014831499,0.0015150188,0.048451446,0.014736198,-0.010171216,-0.054055296,-0.018772013,-0.075441115,-0.057970498,-0.07285955,-0.094746195,-0.00066284765,-0.030606654,-0.02249506,-0.05665214,-0.004902923,-0.10063893,-0.005431448,0.046831325,-0.04124666,0.025016345,-0.07020455,0.042243376,-0.036595218,-0.040861964,0.025493206,0.03268744,-0.008820909,0.053681087,0.058404632,-0.020400561,-0.010795386,-0.048463337,-0.01862999,0.072255366,-0.0057080965,0.052235704,0.052697472,0.08503605,0.0416194,-0.07374082,0.02258435,0.04028459,0.052774813,-0.05802003,-0.030145751,0.014667532,0.039378136,0.040536936,0.046337713,-0.0059488434,0.03145679,0.02533008,-0.06793325,0.010653448,-0.033072874,-0.063505635,0.05356613,-0.0486271,0.045846526,-0.017012171,-0.04449983,-0.01214496,0.020754192,-0.038392745,-5.269617e-33,-0.04149474,0.05524285,-0.124642484,0.03477516,-0.019511098,-0.007584311,-0.00078198226,0.032679375,-0.032116216,0.034704607,0.02773134,-0.030922595,0.07542618,-0.09682553,0.052775227,-0.08184904,-0.04927927,-0.057658557,-0.07586362,-0.025580185,-0.042677913,0.0712821,-0.05623687,-0.034229457,-0.06490138,0.031312555,-0.03227178,0.0057260273,-0.012008425,0.021897318,0.0048776707,0.058733717,-0.04872598,0.016126107,0.07476772,0.0053535504,0.13936739,0.021767955,-0.030106353,-0.0600737,0.056085728,0.119164586,-0.017059442,0.028864397,-0.040801883,0.054474365,-0.02867091,0.09957043,-0.008692031,-0.0034205008,-0.005345535,0.026870199,0.0074263704,0.023972003,0.025418043,0.0478512,-0.01877153,0.018706147,-0.013819693,0.08189357,-0.010476507,-0.09591512,-0.079612866,0.069277346,0.047201764,0.04113,-0.0056435484,0.08001963,0.012811922,-0.058543697,0.10310698,0.0038670783,0.018302158,0.03230717,-0.07834326,-0.09034713,0.04092248,0.024031727,-0.00641845,0.024134355,-0.012285797,0.0014016357,-0.087567896,0.02635399,0.046357237,-0.02015769,0.019898027,0.028510766,0.097436935,-0.008102417,-0.056066222,0.03609065,-0.11131639,-0.026418095,-0.019970415,-4.1866492e-08,0.005105072,0.0050309612,0.02649606,0.012897245,0.04496262,0.02117458,-0.051478148,0.07556044,0.01212228,-0.005772853,0.10720063,-0.02363333,-0.07826651,-0.11582619,0.063698776,-0.0174464,0.03561595,-0.009743073,-0.043870844,-0.05588589,0.05003378,0.011797081,-0.06389995,0.005604397,-0.0933035,-0.037535444,0.06031748,-0.019506445,-0.0035310138,0.006420034,-0.045361064,-0.0009681455,-0.00086650875,0.017499296,0.044619948,0.146974,-0.0022493342,0.011287106,0.033560783,0.03132705,-0.078377515,-0.07195631,-0.02245613,-0.026030727,-0.06582804,0.02788466,-0.062416982,0.008876417,0.060917955,0.007875622,0.037543535,-0.06094328,0.06359567,0.057419162,-0.028980896,0.047499485,0.0170625,-0.0703037,0.065894045,0.0910286,0.068135045,0.013175812,0.07986115,0.0936303}	sentence-transformers/all-MiniLM-L6-v2	2026-10-12 15:17:27.925872+05:30	2026-10-12 18:54:47.465307+05:30
77	39	{0.031448815,-0.030011814,-0.056032903,-0.026355835,0.055498935,-0.016039964,-0.033019897,-0.012034392,-0.017802164,0.09382224,-0.016668953,0.02742656,0.03164044,-0.028673789,-0.020157585,0.0701553,0.046301883,0.020856546,-0.02679856,-0.013543198,-0.038898867,0.057906862,-0.09003331,-0.009620188,-0.049112987,0.116422884,-0.021696556,0.022874072,-0.051465444,-0.01699552,0.10487809,-0.010899324,0.030183632,0.080902554,0.0073132114,0.036977276,-0.028777873,-0.030511724,-0.010570802,-0.0007825514,-0.0036845442,0.006018006,0.0055482048,-0.0616291,0.02158023,0.042287115,-0.040918123,0.048615295,0.059709266,-0.026694223,0.020972544,-0.08298216,-0.01175866,-0.042353068,0.029216161,0.038881104,-0.04220163,-0.01478534,-0.0027575463,-0.043475196,0.08347952,-0.023519142,0.037238628,0.051872227,-0.006909564,0.03163646,0.05924563,0.02077913,-0.017335538,-0.11041624,0.05169853,0.056040607,0.1041362,-0.01727248,-0.007817391,0.061208047,0.13724063,7.938063e-05,-0.009170147,-0.0030993095,0.007813294,-0.01809395,-0.021483501,0.020528225,-0.054554004,-0.03961296,-0.06866067,0.05091254,0.032798216,0.051568538,-0.03562128,-0.014084276,0.032385875,-0.021381168,0.023458041,-0.03589506,0.054975193,-0.1111487,-0.0091182245,0.00945595,-0.010195443,-0.08570593,-0.009652839,-0.099871464,0.078726485,-0.010265316,0.01760119,0.0021680975,0.086857155,-0.05687339,-0.0799826,-0.0015781327,0.00014193323,-0.008668001,-0.13224337,-0.011853687,-0.054999016,0.043957617,-0.03587447,-0.008820117,0.04333932,-0.071369395,0.058563348,-0.035342995,0.049592495,0.069491066,-0.0020315847,3.7775344e-34,-0.012223475,0.008850678,-0.011828608,-0.036601685,0.10978626,-0.020231038,-0.058506936,-0.071431234,-0.08407574,-0.050962582,-0.08878143,-0.006696604,0.022458825,0.033165347,0.0029948517,-0.094930604,0.06754654,-0.043949116,-0.029941648,-0.06070149,-0.048129898,-0.030481422,-5.5871606e-05,-0.0018185546,0.032638665,0.094373144,0.05024963,-0.029910762,0.11186717,0.034531955,-0.05153632,0.103388555,0.008465708,0.006442251,0.018846352,0.12059435,-0.041506175,-0.058461368,-0.04666019,-0.022291161,0.05276146,0.045387663,-0.059329193,-0.0052612196,-0.014587882,-0.0595718,0.008708879,0.0135037545,-0.0065360377,-0.02519502,-0.055090338,-0.027313447,0.006860243,-0.104375646,0.054393362,-0.020333152,-0.004524334,0.026405957,0.06400341,0.013224111,0.013018137,-0.12226559,-0.110891536,-0.019370863,0.05358621,0.0063275564,0.05915603,0.03872291,0.07155443,0.009917474,0.027713316,0.10758802,0.03782724,0.0012835949,-0.014290394,0.02364763,-0.009520766,-0.018157136,0.0011886795,-0.0006205271,-0.090460636,-0.008672865,0.02325054,0.035182025,0.035794627,-0.0074758665,-0.05409184,0.11192218,-0.09581358,0.050105453,-0.060563393,-0.06133151,0.053806834,0.033312988,-0.03229485,-9.587355e-34,-0.060598362,0.055360265,-0.018962743,0.09002431,0.05037766,-0.0014796684,0.015381572,-0.050088037,-0.06839456,0.012113201,-0.08815783,0.045028403,0.0009948795,-0.008503545,0.014581545,-0.025856137,0.0129105635,-0.10457164,-0.009380013,-0.038439773,-0.021756778,-0.049711972,0.01745157,-0.058730677,0.01118878,0.073486365,-0.032281473,-0.011648454,0.012162293,0.0018178155,0.061601307,-0.113147125,-0.0031132156,-0.02107156,0.08900511,0.093886055,0.012958173,-0.0019205976,-0.06853166,0.003879783,-0.032063738,0.005784655,-0.07082919,-0.019764015,0.013253558,0.0065222844,0.009662816,0.0905843,-0.11104296,0.008525896,-0.0519283,0.009913258,-0.10014925,0.06806926,-0.016624164,0.04598621,0.013909039,0.08732568,-0.011025471,0.0011978216,0.02147462,-0.084954716,-0.069812335,0.12110299,0.006309726,0.0068914467,0.0032194464,0.0060873316,-0.06555208,0.07799793,0.044051077,0.057303794,-0.019963145,-0.01403044,0.012135295,-0.04614198,-0.0340308,0.015910445,0.01989515,0.0489635,-0.046169885,-0.0054709674,-0.008503627,0.09193872,0.038789395,0.059109714,0.101690374,0.0011508607,-0.03900237,0.024806771,-0.081972696,-0.061499212,0.0033820816,0.011527528,-0.11043302,-2.6882484e-08,-0.0457586,0.062997475,-0.0042518876,-0.031861402,0.038153622,0.021019163,0.090511784,0.016006324,-0.005883587,-0.0015211471,0.0050217495,-0.06133005,-0.033005346,0.0031268164,-0.03274101,0.018857937,0.019620951,-0.010932513,0.014789283,-0.025042757,-0.059511006,-0.025874099,-0.065420374,0.020395549,0.024247639,0.028819397,-0.033583436,0.008230039,-0.010953792,0.037932795,-0.07140422,-0.01697154,0.0019214229,0.035962325,0.001093495,0.012939685,-0.004735061,-0.006073743,0.061821856,0.027399834,0.060861655,0.097917736,0.011900519,0.00938181,0.037536677,0.049881276,0.07918279,-0.06152372,-0.048624624,-0.07535297,0.04569691,-0.032020625,-0.08858016,0.12176075,0.08772759,0.014926541,0.082128175,-0.1011304,0.109349445,0.09194583,-0.0133383805,0.008657825,-0.08265621,-0.04150531}	sentence-transformers/all-MiniLM-L6-v2	2026-10-23 19:52:12.49459+05:30	2026-10-23 19:52:12.49459+05:30
\.


--
-- Data for Name: project_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_files (id, project_id, file_name, file_type, file_size, storage_path, storage_type, uploaded_by_user_id, created_at, file_path, uploaded_at) FROM stdin;
1	1	24MX106_Nexuslos_Explainable_Loan_Origination_Sy_Report.pdf	application/pdf	3781	\N	LOCAL	\N	2026-10-12 15:14:28.41377+05:30	d:/projectvault/storage/projects\\1\\24MX106_Nexuslos_Explainable_Loan_Origination_Sy_Report.pdf	2026-10-12 15:14:28.41377+05:30
2	1	24MX106_Nexuslos_Explainable_Loan_Origination_Sy_SourceCode.zip	application/zip	10225192	\N	LOCAL	\N	2026-10-12 15:14:28.511964+05:30	d:/projectvault/storage/projects\\1\\24MX106_Nexuslos_Explainable_Loan_Origination_Sy_SourceCode.zip	2026-10-12 15:14:28.511964+05:30
3	2	24MX217_Automated_Distress_And_Safety_Detection__Report.pdf	application/pdf	3912	\N	LOCAL	\N	2026-10-12 15:14:43.557448+05:30	d:/projectvault/storage/projects\\2\\24MX217_Automated_Distress_And_Safety_Detection__Report.pdf	2026-10-12 15:14:43.557448+05:30
4	2	24MX217_Automated_Distress_And_Safety_Detection__SourceCode.zip	application/zip	1098828899	\N	LOCAL	\N	2026-10-12 15:14:56.017038+05:30	d:/projectvault/storage/projects\\2\\24MX217_Automated_Distress_And_Safety_Detection__SourceCode.zip	2026-10-12 15:14:56.017038+05:30
5	3	24MX108_24Mx108_Smart_Contract_Vulnerability_Det_Report.pdf	application/pdf	3852	\N	LOCAL	\N	2026-10-12 15:14:56.179947+05:30	d:/projectvault/storage/projects\\3\\24MX108_24Mx108_Smart_Contract_Vulnerability_Det_Report.pdf	2026-10-12 15:14:56.179947+05:30
6	3	24MX108_24Mx108_Smart_Contract_Vulnerability_Det_SourceCode.zip	application/zip	107209814	\N	LOCAL	\N	2026-10-12 15:14:57.398332+05:30	d:/projectvault/storage/projects\\3\\24MX108_24Mx108_Smart_Contract_Vulnerability_Det_SourceCode.zip	2026-10-12 15:14:57.398332+05:30
7	4	24MX219_Nithesh_S_Software_Bug_Assistant_Report.pdf	application/pdf	3779	\N	LOCAL	\N	2026-10-12 15:14:57.847238+05:30	d:/projectvault/storage/projects\\4\\24MX219_Nithesh_S_Software_Bug_Assistant_Report.pdf	2026-10-12 15:14:57.847238+05:30
8	4	24MX219_Nithesh_S_Software_Bug_Assistant_SourceCode.zip	application/zip	2385137414	\N	LOCAL	\N	2026-10-12 15:15:26.992704+05:30	d:/projectvault/storage/projects\\4\\24MX219_Nithesh_S_Software_Bug_Assistant_SourceCode.zip	2026-10-12 15:15:26.992704+05:30
9	5	24MX301_23Mx41_Project_Work__Qgenesis__16Th_Apri_Report.pdf	application/pdf	3616	\N	LOCAL	\N	2026-10-12 15:15:28.44197+05:30	d:/projectvault/storage/projects\\5\\24MX301_23Mx41_Project_Work__Qgenesis__16Th_Apri_Report.pdf	2026-10-12 15:15:28.44197+05:30
10	5	24MX301_23Mx41_Project_Work__Qgenesis__16Th_Apri_SourceCode.zip	application/zip	608307975	\N	LOCAL	\N	2026-10-12 15:15:35.181906+05:30	d:/projectvault/storage/projects\\5\\24MX301_23Mx41_Project_Work__Qgenesis__16Th_Apri_SourceCode.zip	2026-10-12 15:15:35.181906+05:30
11	6	24MX317_Secure_Data_Redaction_System_Report.pdf	application/pdf	3770	\N	LOCAL	\N	2026-10-12 15:15:35.260827+05:30	d:/projectvault/storage/projects\\6\\24MX317_Secure_Data_Redaction_System_Report.pdf	2026-10-12 15:15:35.260827+05:30
12	6	24MX317_Secure_Data_Redaction_System_SourceCode.zip	application/zip	2767434	\N	LOCAL	\N	2026-10-12 15:15:35.298873+05:30	d:/projectvault/storage/projects\\6\\24MX317_Secure_Data_Redaction_System_SourceCode.zip	2026-10-12 15:15:35.298873+05:30
13	7	24MX353_24Mx353_An_Adaptive_Anomaly_Detection_Fr_Report.pdf	application/pdf	3815	\N	LOCAL	\N	2026-10-12 15:15:35.526978+05:30	d:/projectvault/storage/projects\\7\\24MX353_24Mx353_An_Adaptive_Anomaly_Detection_Fr_Report.pdf	2026-10-12 15:15:35.526978+05:30
14	7	24MX353_24Mx353_An_Adaptive_Anomaly_Detection_Fr_SourceCode.zip	application/zip	677536564	\N	LOCAL	\N	2026-10-12 15:15:43.230504+05:30	d:/projectvault/storage/projects\\7\\24MX353_24Mx353_An_Adaptive_Anomaly_Detection_Fr_SourceCode.zip	2026-10-12 15:15:43.230504+05:30
15	8	24MX203_Sybil_Node_Identification_Using_Graph_Ba_Report.pdf	application/pdf	3770	\N	LOCAL	\N	2026-10-12 15:15:43.317138+05:30	d:/projectvault/storage/projects\\8\\24MX203_Sybil_Node_Identification_Using_Graph_Ba_Report.pdf	2026-10-12 15:15:43.317138+05:30
16	8	24MX203_Sybil_Node_Identification_Using_Graph_Ba_SourceCode.zip	application/zip	25050682	\N	LOCAL	\N	2026-10-12 15:15:43.599144+05:30	d:/projectvault/storage/projects\\8\\24MX203_Sybil_Node_Identification_Using_Graph_Ba_SourceCode.zip	2026-10-12 15:15:43.599144+05:30
17	9	24MX211_A_Hybrid_Xgboost_Lstm_Approach_For_Onlin_Report.pdf	application/pdf	3886	\N	LOCAL	\N	2026-10-12 15:15:43.685264+05:30	d:/projectvault/storage/projects\\9\\24MX211_A_Hybrid_Xgboost_Lstm_Approach_For_Onlin_Report.pdf	2026-10-12 15:15:43.685264+05:30
18	9	24MX211_A_Hybrid_Xgboost_Lstm_Approach_For_Onlin_SourceCode.zip	application/zip	63773081	\N	LOCAL	\N	2026-10-12 15:15:44.437552+05:30	d:/projectvault/storage/projects\\9\\24MX211_A_Hybrid_Xgboost_Lstm_Approach_For_Onlin_SourceCode.zip	2026-10-12 15:15:44.437552+05:30
19	10	24MX229_Trustles_A_Zero_Trust_Monitoring_System_Report.pdf	application/pdf	3601	\N	LOCAL	\N	2026-10-12 15:15:44.555831+05:30	d:/projectvault/storage/projects\\10\\24MX229_Trustles_A_Zero_Trust_Monitoring_System_Report.pdf	2026-10-12 15:15:44.555831+05:30
20	10	24MX229_Trustles_A_Zero_Trust_Monitoring_System_SourceCode.zip	application/zip	5579915	\N	LOCAL	\N	2026-10-12 15:15:44.62274+05:30	d:/projectvault/storage/projects\\10\\24MX229_Trustles_A_Zero_Trust_Monitoring_System_SourceCode.zip	2026-10-12 15:15:44.62274+05:30
21	11	24MX101_Secureimageenhanced_Report.pdf	application/pdf	4029	\N	LOCAL	\N	2026-10-12 15:15:44.67397+05:30	d:/projectvault/storage/projects\\11\\24MX101_Secureimageenhanced_Report.pdf	2026-10-12 15:15:44.67397+05:30
22	11	24MX101_Secureimageenhanced_SourceCode.zip	application/zip	34721	\N	LOCAL	\N	2026-10-12 15:15:44.675825+05:30	d:/projectvault/storage/projects\\11\\24MX101_Secureimageenhanced_SourceCode.zip	2026-10-12 15:15:44.675825+05:30
23	12	24MX128_Academic_Integrity_Checker_Anti_Plagiari_Report.pdf	application/pdf	3949	\N	LOCAL	\N	2026-10-12 15:15:45.378292+05:30	d:/projectvault/storage/projects\\12\\24MX128_Academic_Integrity_Checker_Anti_Plagiari_Report.pdf	2026-10-12 15:15:45.378292+05:30
24	12	24MX128_Academic_Integrity_Checker_Anti_Plagiari_SourceCode.zip	application/zip	3677717535	\N	LOCAL	\N	2026-10-12 15:16:28.948082+05:30	d:/projectvault/storage/projects\\12\\24MX128_Academic_Integrity_Checker_Anti_Plagiari_SourceCode.zip	2026-10-12 15:16:28.948082+05:30
25	13	24MX119_Adversarial_Robust_Cnn_Report.pdf	application/pdf	3566	\N	LOCAL	\N	2026-10-12 15:16:29.076086+05:30	d:/projectvault/storage/projects\\13\\24MX119_Adversarial_Robust_Cnn_Report.pdf	2026-10-12 15:16:29.076086+05:30
26	13	24MX119_Adversarial_Robust_Cnn_SourceCode.zip	application/zip	373798418	\N	LOCAL	\N	2026-10-12 15:16:33.326956+05:30	d:/projectvault/storage/projects\\13\\24MX119_Adversarial_Robust_Cnn_SourceCode.zip	2026-10-12 15:16:33.326956+05:30
27	14	24MX113_Manishankar_V__Decentralized_Patient_Dat_Report.pdf	application/pdf	3909	\N	LOCAL	\N	2026-10-12 15:16:33.599875+05:30	d:/projectvault/storage/projects\\14\\24MX113_Manishankar_V__Decentralized_Patient_Dat_Report.pdf	2026-10-12 15:16:33.599875+05:30
28	14	24MX113_Manishankar_V__Decentralized_Patient_Dat_SourceCode.zip	application/zip	69419936	\N	LOCAL	\N	2026-10-12 15:16:34.361938+05:30	d:/projectvault/storage/projects\\14\\24MX113_Manishankar_V__Decentralized_Patient_Dat_SourceCode.zip	2026-10-12 15:16:34.361938+05:30
29	15	24MX206_Dharsini_B___Innovest_Report.pdf	application/pdf	3745	\N	LOCAL	\N	2026-10-12 15:16:34.49214+05:30	d:/projectvault/storage/projects\\15\\24MX206_Dharsini_B___Innovest_Report.pdf	2026-10-12 15:16:34.49214+05:30
30	15	24MX206_Dharsini_B___Innovest_SourceCode.zip	application/zip	2793072	\N	LOCAL	\N	2026-10-12 15:16:34.531334+05:30	d:/projectvault/storage/projects\\15\\24MX206_Dharsini_B___Innovest_SourceCode.zip	2026-10-12 15:16:34.531334+05:30
31	16	24MX318_Janani_M___Automated_Outcome_Based_Educa_Report.pdf	application/pdf	3832	\N	LOCAL	\N	2026-10-12 15:16:35.549961+05:30	d:/projectvault/storage/projects\\16\\24MX318_Janani_M___Automated_Outcome_Based_Educa_Report.pdf	2026-10-12 15:16:35.549961+05:30
32	16	24MX318_Janani_M___Automated_Outcome_Based_Educa_SourceCode.zip	application/zip	264775850	\N	LOCAL	\N	2026-10-12 15:16:38.578242+05:30	d:/projectvault/storage/projects\\16\\24MX318_Janani_M___Automated_Outcome_Based_Educa_SourceCode.zip	2026-10-12 15:16:38.578242+05:30
33	17	24MX319_M_Janani_Prevue_Report.pdf	application/pdf	3679	\N	LOCAL	\N	2026-10-12 15:16:38.941221+05:30	d:/projectvault/storage/projects\\17\\24MX319_M_Janani_Prevue_Report.pdf	2026-10-12 15:16:38.941221+05:30
34	17	24MX319_M_Janani_Prevue_SourceCode.zip	application/zip	113921517	\N	LOCAL	\N	2026-10-12 15:16:40.30098+05:30	d:/projectvault/storage/projects\\17\\24MX319_M_Janani_Prevue_SourceCode.zip	2026-10-12 15:16:40.30098+05:30
35	18	24MX310_Smart_Toll_Report.pdf	application/pdf	3842	\N	LOCAL	\N	2026-10-12 15:16:40.37636+05:30	d:/projectvault/storage/projects\\18\\24MX310_Smart_Toll_Report.pdf	2026-10-12 15:16:40.37636+05:30
36	18	24MX310_Smart_Toll_SourceCode.zip	application/zip	4618577	\N	LOCAL	\N	2026-10-12 15:16:40.431106+05:30	d:/projectvault/storage/projects\\18\\24MX310_Smart_Toll_SourceCode.zip	2026-10-12 15:16:40.431106+05:30
37	19	24MX109_Cloudinsight_Report.pdf	application/pdf	3706	\N	LOCAL	\N	2026-10-12 15:16:40.610044+05:30	d:/projectvault/storage/projects\\19\\24MX109_Cloudinsight_Report.pdf	2026-10-12 15:16:40.610044+05:30
38	19	24MX109_Cloudinsight_SourceCode.zip	application/zip	124541219	\N	LOCAL	\N	2026-10-12 15:16:42.126613+05:30	d:/projectvault/storage/projects\\19\\24MX109_Cloudinsight_SourceCode.zip	2026-10-12 15:16:42.126613+05:30
39	20	24MX207_Edge_Verify_Report.pdf	application/pdf	3694	\N	LOCAL	\N	2026-10-12 15:16:42.942176+05:30	d:/projectvault/storage/projects\\20\\24MX207_Edge_Verify_Report.pdf	2026-10-12 15:16:42.942176+05:30
40	20	24MX207_Edge_Verify_SourceCode.zip	application/zip	410659795	\N	LOCAL	\N	2026-10-12 15:16:47.812229+05:30	d:/projectvault/storage/projects\\20\\24MX207_Edge_Verify_SourceCode.zip	2026-10-12 15:16:47.812229+05:30
41	21	24MX118_Evodoc_24Mx118__Report.pdf	application/pdf	3675	\N	LOCAL	\N	2026-10-12 15:16:47.910864+05:30	d:/projectvault/storage/projects\\21\\24MX118_Evodoc_24Mx118__Report.pdf	2026-10-12 15:16:47.910864+05:30
42	21	24MX118_Evodoc_24Mx118__SourceCode.zip	application/zip	121697	\N	LOCAL	\N	2026-10-12 15:16:47.912202+05:30	d:/projectvault/storage/projects\\21\\24MX118_Evodoc_24Mx118__SourceCode.zip	2026-10-12 15:16:47.912202+05:30
43	22	24MX213_Investigation_On_Malware_Detection_Using_Report.pdf	application/pdf	3664	\N	LOCAL	\N	2026-10-12 15:16:48.001078+05:30	d:/projectvault/storage/projects\\22\\24MX213_Investigation_On_Malware_Detection_Using_Report.pdf	2026-10-12 15:16:48.001078+05:30
44	22	24MX213_Investigation_On_Malware_Detection_Using_SourceCode.zip	application/zip	248955	\N	LOCAL	\N	2026-10-12 15:16:48.003162+05:30	d:/projectvault/storage/projects\\22\\24MX213_Investigation_On_Malware_Detection_Using_SourceCode.zip	2026-10-12 15:16:48.003162+05:30
45	23	24MX230_Venisha__Eduslot_Report.pdf	application/pdf	3724	\N	LOCAL	\N	2026-10-12 15:16:49.016073+05:30	d:/projectvault/storage/projects\\23\\24MX230_Venisha__Eduslot_Report.pdf	2026-10-12 15:16:49.016073+05:30
46	23	24MX230_Venisha__Eduslot_SourceCode.zip	application/zip	405849563	\N	LOCAL	\N	2026-10-12 15:16:53.536519+05:30	d:/projectvault/storage/projects\\23\\24MX230_Venisha__Eduslot_SourceCode.zip	2026-10-12 15:16:53.536519+05:30
47	24	24MX312_Thinktwice_Ai_Powered_Chrome_Extension_F_Report.pdf	application/pdf	3864	\N	LOCAL	\N	2026-10-12 15:16:53.690282+05:30	d:/projectvault/storage/projects\\24\\24MX312_Thinktwice_Ai_Powered_Chrome_Extension_F_Report.pdf	2026-10-12 15:16:53.690282+05:30
48	24	24MX312_Thinktwice_Ai_Powered_Chrome_Extension_F_SourceCode.zip	application/zip	17760003	\N	LOCAL	\N	2026-10-12 15:16:53.899346+05:30	d:/projectvault/storage/projects\\24\\24MX312_Thinktwice_Ai_Powered_Chrome_Extension_F_SourceCode.zip	2026-10-12 15:16:53.899346+05:30
49	25	24MX354_Personalizedmusicrecommendationsystem_Report.pdf	application/pdf	3585	\N	LOCAL	\N	2026-10-12 15:16:54.007094+05:30	d:/projectvault/storage/projects\\25\\24MX354_Personalizedmusicrecommendationsystem_Report.pdf	2026-10-12 15:16:54.007094+05:30
50	25	24MX354_Personalizedmusicrecommendationsystem_SourceCode.zip	application/zip	343790043	\N	LOCAL	\N	2026-10-12 15:16:58.251739+05:30	d:/projectvault/storage/projects\\25\\24MX354_Personalizedmusicrecommendationsystem_SourceCode.zip	2026-10-12 15:16:58.251739+05:30
51	26	24MX104_Apartment_Report.pdf	application/pdf	3706	\N	LOCAL	\N	2026-10-12 15:16:58.833136+05:30	d:/projectvault/storage/projects\\26\\24MX104_Apartment_Report.pdf	2026-10-12 15:16:58.833136+05:30
52	26	24MX104_Apartment_SourceCode.zip	application/zip	93454805	\N	LOCAL	\N	2026-10-12 15:16:59.874944+05:30	d:/projectvault/storage/projects\\26\\24MX104_Apartment_SourceCode.zip	2026-10-12 15:16:59.874944+05:30
53	27	24MX127_Keysense_Report.pdf	application/pdf	3546	\N	LOCAL	\N	2026-10-12 15:17:00.180282+05:30	d:/projectvault/storage/projects\\27\\24MX127_Keysense_Report.pdf	2026-10-12 15:17:00.180282+05:30
54	27	24MX127_Keysense_SourceCode.zip	application/zip	576418645	\N	LOCAL	\N	2026-10-12 15:17:06.989101+05:30	d:/projectvault/storage/projects\\27\\24MX127_Keysense_SourceCode.zip	2026-10-12 15:17:06.989101+05:30
55	28	24MX221_Segro_Report.pdf	application/pdf	3542	\N	LOCAL	\N	2026-10-12 15:17:07.084315+05:30	d:/projectvault/storage/projects\\28\\24MX221_Segro_Report.pdf	2026-10-12 15:17:07.084315+05:30
56	28	24MX221_Segro_SourceCode.zip	application/zip	2452	\N	LOCAL	\N	2026-10-12 15:17:07.08535+05:30	d:/projectvault/storage/projects\\28\\24MX221_Segro_SourceCode.zip	2026-10-12 15:17:07.08535+05:30
57	29	24MX327_Schemebottn_Report.pdf	application/pdf	3765	\N	LOCAL	\N	2026-10-12 15:17:07.221859+05:30	d:/projectvault/storage/projects\\29\\24MX327_Schemebottn_Report.pdf	2026-10-12 15:17:07.221859+05:30
58	29	24MX327_Schemebottn_SourceCode.zip	application/zip	25512490	\N	LOCAL	\N	2026-10-12 15:17:07.532583+05:30	d:/projectvault/storage/projects\\29\\24MX327_Schemebottn_SourceCode.zip	2026-10-12 15:17:07.532583+05:30
59	30	24MX116_Nextdoor_Connect_Report.pdf	application/pdf	3724	\N	LOCAL	\N	2026-10-12 15:17:08.003324+05:30	d:/projectvault/storage/projects\\30\\24MX116_Nextdoor_Connect_Report.pdf	2026-10-12 15:17:08.003324+05:30
60	30	24MX116_Nextdoor_Connect_SourceCode.zip	application/zip	167695261	\N	LOCAL	\N	2026-10-12 15:17:09.907855+05:30	d:/projectvault/storage/projects\\30\\24MX116_Nextdoor_Connect_SourceCode.zip	2026-10-12 15:17:09.907855+05:30
61	31	24MX215_24Mx215_Techpackanalyzer_Report.pdf	application/pdf	3721	\N	LOCAL	\N	2026-10-12 15:17:10.910354+05:30	d:/projectvault/storage/projects\\31\\24MX215_24Mx215_Techpackanalyzer_Report.pdf	2026-10-12 15:17:10.910354+05:30
62	31	24MX215_24Mx215_Techpackanalyzer_SourceCode.zip	application/zip	268769676	\N	LOCAL	\N	2026-10-12 15:17:13.90061+05:30	d:/projectvault/storage/projects\\31\\24MX215_24Mx215_Techpackanalyzer_SourceCode.zip	2026-10-12 15:17:13.90061+05:30
63	32	24MX222_Offline_Lora_Mesh_Based_Communication_An_Report.pdf	application/pdf	3839	\N	LOCAL	\N	2026-10-12 15:17:14.008969+05:30	d:/projectvault/storage/projects\\32\\24MX222_Offline_Lora_Mesh_Based_Communication_An_Report.pdf	2026-10-12 15:17:14.008969+05:30
64	32	24MX222_Offline_Lora_Mesh_Based_Communication_An_SourceCode.zip	application/zip	27416845	\N	LOCAL	\N	2026-10-12 15:17:14.327095+05:30	d:/projectvault/storage/projects\\32\\24MX222_Offline_Lora_Mesh_Based_Communication_An_SourceCode.zip	2026-10-12 15:17:14.327095+05:30
65	33	24MX205_Boopathirajanm_Own_Drive_Report.pdf	application/pdf	4042	\N	LOCAL	\N	2026-10-12 15:17:14.448483+05:30	d:/projectvault/storage/projects\\33\\24MX205_Boopathirajanm_Own_Drive_Report.pdf	2026-10-12 15:17:14.448483+05:30
66	33	24MX205_Boopathirajanm_Own_Drive_SourceCode.zip	application/zip	205152	\N	LOCAL	\N	2026-10-12 15:17:14.451481+05:30	d:/projectvault/storage/projects\\33\\24MX205_Boopathirajanm_Own_Drive_SourceCode.zip	2026-10-12 15:17:14.451481+05:30
67	34	24MX216_24Mx216_Bulkify_Report.pdf	application/pdf	3651	\N	LOCAL	\N	2026-10-12 15:17:15.043393+05:30	d:/projectvault/storage/projects\\34\\24MX216_24Mx216_Bulkify_Report.pdf	2026-10-12 15:17:15.043393+05:30
68	34	24MX216_24Mx216_Bulkify_SourceCode.zip	application/zip	170898685	\N	LOCAL	\N	2026-10-12 15:17:16.977478+05:30	d:/projectvault/storage/projects\\34\\24MX216_24Mx216_Bulkify_SourceCode.zip	2026-10-12 15:17:16.977478+05:30
69	35	24MX227_Speakmate_Report.pdf	application/pdf	3724	\N	LOCAL	\N	2026-10-12 15:17:17.376873+05:30	d:/projectvault/storage/projects\\35\\24MX227_Speakmate_Report.pdf	2026-10-12 15:17:17.376873+05:30
70	35	24MX227_Speakmate_SourceCode.zip	application/zip	193552816	\N	LOCAL	\N	2026-10-12 15:17:19.564747+05:30	d:/projectvault/storage/projects\\35\\24MX227_Speakmate_SourceCode.zip	2026-10-12 15:17:19.564747+05:30
71	36	24MX320_Thinkinlogic_Report.pdf	application/pdf	3727	\N	LOCAL	\N	2026-10-12 15:17:19.647251+05:30	d:/projectvault/storage/projects\\36\\24MX320_Thinkinlogic_Report.pdf	2026-10-12 15:17:19.647251+05:30
72	36	24MX320_Thinkinlogic_SourceCode.zip	application/zip	696578	\N	LOCAL	\N	2026-10-12 15:17:19.650845+05:30	d:/projectvault/storage/projects\\36\\24MX320_Thinkinlogic_SourceCode.zip	2026-10-12 15:17:19.650845+05:30
73	37	24MX359_Nipds_Report.pdf	application/pdf	3542	\N	LOCAL	\N	2026-10-12 15:17:19.728578+05:30	d:/projectvault/storage/projects\\37\\24MX359_Nipds_Report.pdf	2026-10-12 15:17:19.728578+05:30
74	37	24MX359_Nipds_SourceCode.rar	application/zip	668049945	\N	LOCAL	\N	2026-10-12 15:17:27.900246+05:30	d:/projectvault/storage/projects\\37\\24MX359_Nipds_SourceCode.rar	2026-10-12 15:17:27.900246+05:30
75	38	23MX221_Dubbify_Report.pdf	application/pdf	3706	\N	LOCAL	\N	2026-10-12 15:17:28.807735+05:30	d:/projectvault/storage/projects\\38\\23MX221_Dubbify_Report.pdf	2026-10-12 15:17:28.807735+05:30
76	38	23MX221_Dubbify_SourceCode.zip	application/zip	239303109	\N	LOCAL	\N	2026-10-12 15:17:31.453915+05:30	d:/projectvault/storage/projects\\38\\23MX221_Dubbify_SourceCode.zip	2026-10-12 15:17:31.453915+05:30
\.


--
-- Data for Name: project_keywords; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_keywords (project_id, keyword_id, is_ai_generated) FROM stdin;
\.


--
-- Data for Name: project_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_members (id, project_id, user_id, member_role, created_at) FROM stdin;
1	1	52	Project Lead / Author	2026-10-12 15:14:28.401583+05:30
2	2	53	Project Lead / Author	2026-10-12 15:14:43.538153+05:30
3	3	54	Project Lead / Author	2026-10-12 15:14:56.167355+05:30
4	4	55	Project Lead / Author	2026-10-12 15:14:57.832045+05:30
5	5	56	Project Lead / Author	2026-10-12 15:15:28.425631+05:30
6	6	57	Project Lead / Author	2026-10-12 15:15:35.244949+05:30
7	7	58	Project Lead / Author	2026-10-12 15:15:35.518862+05:30
8	8	59	Project Lead / Author	2026-10-12 15:15:43.305053+05:30
9	9	60	Project Lead / Author	2026-10-12 15:15:43.673709+05:30
10	10	61	Project Lead / Author	2026-10-12 15:15:44.546143+05:30
11	11	62	Project Lead / Author	2026-10-12 15:15:44.664785+05:30
12	12	63	Project Lead / Author	2026-10-12 15:15:45.368868+05:30
13	13	64	Project Lead / Author	2026-10-12 15:16:29.06805+05:30
14	14	65	Project Lead / Author	2026-10-12 15:16:33.591824+05:30
15	15	66	Project Lead / Author	2026-10-12 15:16:34.481978+05:30
16	16	67	Project Lead / Author	2026-10-12 15:16:35.54308+05:30
17	17	68	Project Lead / Author	2026-10-12 15:16:38.934751+05:30
18	18	69	Project Lead / Author	2026-10-12 15:16:40.367818+05:30
19	19	70	Project Lead / Author	2026-10-12 15:16:40.602663+05:30
20	20	71	Project Lead / Author	2026-10-12 15:16:42.934481+05:30
21	21	72	Project Lead / Author	2026-10-12 15:16:47.902698+05:30
22	22	73	Project Lead / Author	2026-10-12 15:16:47.992313+05:30
23	23	74	Project Lead / Author	2026-10-12 15:16:49.008587+05:30
24	24	75	Project Lead / Author	2026-10-12 15:16:53.676567+05:30
25	25	76	Project Lead / Author	2026-10-12 15:16:53.994884+05:30
26	26	77	Project Lead / Author	2026-10-12 15:16:58.825704+05:30
27	27	78	Project Lead / Author	2026-10-12 15:17:00.17334+05:30
28	28	79	Project Lead / Author	2026-10-12 15:17:07.07709+05:30
29	29	80	Project Lead / Author	2026-10-12 15:17:07.214342+05:30
30	30	81	Project Lead / Author	2026-10-12 15:17:07.997219+05:30
31	31	82	Project Lead / Author	2026-10-12 15:17:10.89543+05:30
32	32	83	Project Lead / Author	2026-10-12 15:17:13.996524+05:30
33	33	84	Project Lead / Author	2026-10-12 15:17:14.439391+05:30
34	34	85	Project Lead / Author	2026-10-12 15:17:15.03732+05:30
35	35	86	Project Lead / Author	2026-10-12 15:17:17.369171+05:30
36	36	87	Project Lead / Author	2026-10-12 15:17:19.639499+05:30
37	37	88	Project Lead / Author	2026-10-12 15:17:19.719572+05:30
38	38	89	Project Lead / Author	2026-10-12 15:17:28.800636+05:30
39	39	210	Project Lead / Author	2026-10-23 19:52:11.643594+05:30
\.


--
-- Data for Name: project_workflow_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_workflow_history (id, created_at, from_status, to_status, changed_by_user_id, project_id, remarks) FROM stdin;
1	2026-10-02 15:14:28.404713	DRAFT	SUBMITTED	52	1	Capstone project submission received
2	2026-10-07 15:14:28.404713	SUBMITTED	UNDER_REVIEW	34	1	Allocated for Department Viva Evaluation
3	2026-10-12 15:14:28.404713	UNDER_REVIEW	APPROVED	34	1	Approved by Department Viva Committee and Faculty Guide
4	2026-10-02 15:14:43.539427	DRAFT	SUBMITTED	53	2	Capstone project submission received
5	2026-10-07 15:14:43.539427	SUBMITTED	UNDER_REVIEW	35	2	Allocated for Department Viva Evaluation
6	2026-10-12 15:14:43.539427	UNDER_REVIEW	APPROVED	35	2	Approved by Department Viva Committee and Faculty Guide
7	2026-10-02 15:14:56.167979	DRAFT	SUBMITTED	54	3	Capstone project submission received
8	2026-10-07 15:14:56.167979	SUBMITTED	UNDER_REVIEW	36	3	Allocated for Department Viva Evaluation
9	2026-10-12 15:14:56.167979	UNDER_REVIEW	APPROVED	36	3	Approved by Department Viva Committee and Faculty Guide
10	2026-10-02 15:14:57.832776	DRAFT	SUBMITTED	55	4	Capstone project submission received
11	2026-10-07 15:14:57.832776	SUBMITTED	UNDER_REVIEW	37	4	Allocated for Department Viva Evaluation
12	2026-10-12 15:14:57.832776	UNDER_REVIEW	APPROVED	37	4	Approved by Department Viva Committee and Faculty Guide
13	2026-10-02 15:15:28.426511	DRAFT	SUBMITTED	56	5	Capstone project submission received
14	2026-10-07 15:15:28.426511	SUBMITTED	UNDER_REVIEW	38	5	Allocated for Department Viva Evaluation
15	2026-10-12 15:15:28.426511	UNDER_REVIEW	APPROVED	38	5	Approved by Department Viva Committee and Faculty Guide
16	2026-10-02 15:15:35.245784	DRAFT	SUBMITTED	57	6	Capstone project submission received
17	2026-10-07 15:15:35.245784	SUBMITTED	UNDER_REVIEW	39	6	Allocated for Department Viva Evaluation
18	2026-10-12 15:15:35.245784	UNDER_REVIEW	APPROVED	39	6	Approved by Department Viva Committee and Faculty Guide
19	2026-10-02 15:15:35.519271	DRAFT	SUBMITTED	58	7	Capstone project submission received
20	2026-10-07 15:15:35.519271	SUBMITTED	UNDER_REVIEW	40	7	Allocated for Department Viva Evaluation
21	2026-10-12 15:15:35.519271	UNDER_REVIEW	APPROVED	40	7	Approved by Department Viva Committee and Faculty Guide
22	2026-10-02 15:15:43.30551	DRAFT	SUBMITTED	59	8	Capstone project submission received
23	2026-10-07 15:15:43.30551	SUBMITTED	UNDER_REVIEW	41	8	Allocated for Department Viva Evaluation
24	2026-10-12 15:15:43.30551	UNDER_REVIEW	APPROVED	41	8	Approved by Department Viva Committee and Faculty Guide
25	2026-10-02 15:15:43.674261	DRAFT	SUBMITTED	60	9	Capstone project submission received
26	2026-10-07 15:15:43.674261	SUBMITTED	UNDER_REVIEW	42	9	Allocated for Department Viva Evaluation
27	2026-10-12 15:15:43.674261	UNDER_REVIEW	APPROVED	42	9	Approved by Department Viva Committee and Faculty Guide
28	2026-10-02 15:15:44.546622	DRAFT	SUBMITTED	61	10	Capstone project submission received
29	2026-10-07 15:15:44.546622	SUBMITTED	UNDER_REVIEW	43	10	Allocated for Department Viva Evaluation
30	2026-10-12 15:15:44.546622	UNDER_REVIEW	APPROVED	43	10	Approved by Department Viva Committee and Faculty Guide
31	2026-10-02 15:15:44.66515	DRAFT	SUBMITTED	62	11	Capstone project submission received
32	2026-10-07 15:15:44.66515	SUBMITTED	UNDER_REVIEW	44	11	Allocated for Department Viva Evaluation
33	2026-10-12 15:15:44.66515	UNDER_REVIEW	APPROVED	44	11	Approved by Department Viva Committee and Faculty Guide
34	2026-10-02 15:15:45.369541	DRAFT	SUBMITTED	63	12	Capstone project submission received
35	2026-10-07 15:15:45.369541	SUBMITTED	UNDER_REVIEW	45	12	Allocated for Department Viva Evaluation
36	2026-10-12 15:15:45.369541	UNDER_REVIEW	APPROVED	45	12	Approved by Department Viva Committee and Faculty Guide
37	2026-10-02 15:16:29.068405	DRAFT	SUBMITTED	64	13	Capstone project submission received
38	2026-10-07 15:16:29.068405	SUBMITTED	UNDER_REVIEW	46	13	Allocated for Department Viva Evaluation
39	2026-10-12 15:16:29.068405	UNDER_REVIEW	APPROVED	46	13	Approved by Department Viva Committee and Faculty Guide
40	2026-10-02 15:16:33.592187	DRAFT	SUBMITTED	65	14	Capstone project submission received
41	2026-10-07 15:16:33.592187	SUBMITTED	UNDER_REVIEW	47	14	Allocated for Department Viva Evaluation
42	2026-10-12 15:16:33.592187	UNDER_REVIEW	APPROVED	47	14	Approved by Department Viva Committee and Faculty Guide
43	2026-10-02 15:16:34.482492	DRAFT	SUBMITTED	66	15	Capstone project submission received
44	2026-10-07 15:16:34.482492	SUBMITTED	UNDER_REVIEW	48	15	Allocated for Department Viva Evaluation
45	2026-10-12 15:16:34.482492	UNDER_REVIEW	APPROVED	48	15	Approved by Department Viva Committee and Faculty Guide
46	2026-10-02 15:16:35.543455	DRAFT	SUBMITTED	67	16	Capstone project submission received
47	2026-10-07 15:16:35.543455	SUBMITTED	UNDER_REVIEW	49	16	Allocated for Department Viva Evaluation
48	2026-10-12 15:16:35.543455	UNDER_REVIEW	APPROVED	49	16	Approved by Department Viva Committee and Faculty Guide
49	2026-10-02 15:16:38.935065	DRAFT	SUBMITTED	68	17	Capstone project submission received
50	2026-10-07 15:16:38.935065	SUBMITTED	UNDER_REVIEW	50	17	Allocated for Department Viva Evaluation
51	2026-10-12 15:16:38.935065	UNDER_REVIEW	APPROVED	50	17	Approved by Department Viva Committee and Faculty Guide
52	2026-10-02 15:16:40.368116	DRAFT	SUBMITTED	69	18	Capstone project submission received
53	2026-10-07 15:16:40.368116	SUBMITTED	UNDER_REVIEW	51	18	Allocated for Department Viva Evaluation
54	2026-10-12 15:16:40.368116	UNDER_REVIEW	APPROVED	51	18	Approved by Department Viva Committee and Faculty Guide
55	2026-10-02 15:16:40.603061	DRAFT	SUBMITTED	70	19	Capstone project submission received
56	2026-10-07 15:16:40.603061	SUBMITTED	UNDER_REVIEW	34	19	Allocated for Department Viva Evaluation
57	2026-10-12 15:16:40.603061	UNDER_REVIEW	APPROVED	34	19	Approved by Department Viva Committee and Faculty Guide
58	2026-10-02 15:16:42.935032	DRAFT	SUBMITTED	71	20	Capstone project submission received
59	2026-10-07 15:16:42.935032	SUBMITTED	UNDER_REVIEW	35	20	Allocated for Department Viva Evaluation
60	2026-10-12 15:16:42.935032	UNDER_REVIEW	APPROVED	35	20	Approved by Department Viva Committee and Faculty Guide
61	2026-10-02 15:16:47.903007	DRAFT	SUBMITTED	72	21	Capstone project submission received
62	2026-10-07 15:16:47.903007	SUBMITTED	UNDER_REVIEW	36	21	Allocated for Department Viva Evaluation
63	2026-10-12 15:16:47.903007	UNDER_REVIEW	APPROVED	36	21	Approved by Department Viva Committee and Faculty Guide
64	2026-10-02 15:16:47.992672	DRAFT	SUBMITTED	73	22	Capstone project submission received
65	2026-10-07 15:16:47.992672	SUBMITTED	UNDER_REVIEW	37	22	Allocated for Department Viva Evaluation
66	2026-10-12 15:16:47.992672	UNDER_REVIEW	APPROVED	37	22	Approved by Department Viva Committee and Faculty Guide
67	2026-10-02 15:16:49.008956	DRAFT	SUBMITTED	74	23	Capstone project submission received
68	2026-10-07 15:16:49.008956	SUBMITTED	UNDER_REVIEW	38	23	Allocated for Department Viva Evaluation
69	2026-10-12 15:16:49.008956	UNDER_REVIEW	APPROVED	38	23	Approved by Department Viva Committee and Faculty Guide
70	2026-10-02 15:16:53.676974	DRAFT	SUBMITTED	75	24	Capstone project submission received
71	2026-10-07 15:16:53.676974	SUBMITTED	UNDER_REVIEW	39	24	Allocated for Department Viva Evaluation
72	2026-10-12 15:16:53.676974	UNDER_REVIEW	APPROVED	39	24	Approved by Department Viva Committee and Faculty Guide
73	2026-10-02 15:16:53.995274	DRAFT	SUBMITTED	76	25	Capstone project submission received
74	2026-10-07 15:16:53.995274	SUBMITTED	UNDER_REVIEW	40	25	Allocated for Department Viva Evaluation
75	2026-10-12 15:16:53.995274	UNDER_REVIEW	APPROVED	40	25	Approved by Department Viva Committee and Faculty Guide
76	2026-10-02 15:16:58.82607	DRAFT	SUBMITTED	77	26	Capstone project submission received
77	2026-10-07 15:16:58.82607	SUBMITTED	UNDER_REVIEW	41	26	Allocated for Department Viva Evaluation
78	2026-10-12 15:16:58.82607	UNDER_REVIEW	APPROVED	41	26	Approved by Department Viva Committee and Faculty Guide
79	2026-10-02 15:17:00.173647	DRAFT	SUBMITTED	78	27	Capstone project submission received
80	2026-10-07 15:17:00.173647	SUBMITTED	UNDER_REVIEW	42	27	Allocated for Department Viva Evaluation
81	2026-10-12 15:17:00.173647	UNDER_REVIEW	APPROVED	42	27	Approved by Department Viva Committee and Faculty Guide
82	2026-10-02 15:17:07.077508	DRAFT	SUBMITTED	79	28	Capstone project submission received
83	2026-10-07 15:17:07.077508	SUBMITTED	UNDER_REVIEW	43	28	Allocated for Department Viva Evaluation
84	2026-10-12 15:17:07.077508	UNDER_REVIEW	APPROVED	43	28	Approved by Department Viva Committee and Faculty Guide
85	2026-10-02 15:17:07.214781	DRAFT	SUBMITTED	80	29	Capstone project submission received
86	2026-10-07 15:17:07.214781	SUBMITTED	UNDER_REVIEW	44	29	Allocated for Department Viva Evaluation
87	2026-10-12 15:17:07.214781	UNDER_REVIEW	APPROVED	44	29	Approved by Department Viva Committee and Faculty Guide
88	2026-10-02 15:17:07.99756	DRAFT	SUBMITTED	81	30	Capstone project submission received
89	2026-10-07 15:17:07.99756	SUBMITTED	UNDER_REVIEW	45	30	Allocated for Department Viva Evaluation
90	2026-10-12 15:17:07.99756	UNDER_REVIEW	APPROVED	45	30	Approved by Department Viva Committee and Faculty Guide
91	2026-10-02 15:17:10.895893	DRAFT	SUBMITTED	82	31	Capstone project submission received
92	2026-10-07 15:17:10.895893	SUBMITTED	UNDER_REVIEW	46	31	Allocated for Department Viva Evaluation
93	2026-10-12 15:17:10.895893	UNDER_REVIEW	APPROVED	46	31	Approved by Department Viva Committee and Faculty Guide
94	2026-10-02 15:17:13.997119	DRAFT	SUBMITTED	83	32	Capstone project submission received
95	2026-10-07 15:17:13.997119	SUBMITTED	UNDER_REVIEW	47	32	Allocated for Department Viva Evaluation
96	2026-10-12 15:17:13.997119	UNDER_REVIEW	APPROVED	47	32	Approved by Department Viva Committee and Faculty Guide
97	2026-10-02 15:17:14.439924	DRAFT	SUBMITTED	84	33	Capstone project submission received
98	2026-10-07 15:17:14.439924	SUBMITTED	UNDER_REVIEW	48	33	Allocated for Department Viva Evaluation
99	2026-10-12 15:17:14.439924	UNDER_REVIEW	APPROVED	48	33	Approved by Department Viva Committee and Faculty Guide
100	2026-10-02 15:17:15.037795	DRAFT	SUBMITTED	85	34	Capstone project submission received
101	2026-10-07 15:17:15.037795	SUBMITTED	UNDER_REVIEW	49	34	Allocated for Department Viva Evaluation
102	2026-10-12 15:17:15.037795	UNDER_REVIEW	APPROVED	49	34	Approved by Department Viva Committee and Faculty Guide
103	2026-10-02 15:17:17.369679	DRAFT	SUBMITTED	86	35	Capstone project submission received
104	2026-10-07 15:17:17.369679	SUBMITTED	UNDER_REVIEW	50	35	Allocated for Department Viva Evaluation
105	2026-10-12 15:17:17.369679	UNDER_REVIEW	APPROVED	50	35	Approved by Department Viva Committee and Faculty Guide
106	2026-10-02 15:17:19.639769	DRAFT	SUBMITTED	87	36	Capstone project submission received
107	2026-10-07 15:17:19.639769	SUBMITTED	UNDER_REVIEW	51	36	Allocated for Department Viva Evaluation
108	2026-10-12 15:17:19.639769	UNDER_REVIEW	APPROVED	51	36	Approved by Department Viva Committee and Faculty Guide
109	2026-10-02 15:17:19.720007	DRAFT	SUBMITTED	88	37	Capstone project submission received
110	2026-10-07 15:17:19.720007	SUBMITTED	UNDER_REVIEW	34	37	Allocated for Department Viva Evaluation
111	2026-10-12 15:17:19.720007	UNDER_REVIEW	APPROVED	34	37	Approved by Department Viva Committee and Faculty Guide
112	2026-10-02 15:17:28.801119	DRAFT	SUBMITTED	89	38	Capstone project submission received
113	2026-10-07 15:17:28.801119	SUBMITTED	UNDER_REVIEW	35	38	Allocated for Department Viva Evaluation
114	2026-10-12 15:17:28.801119	UNDER_REVIEW	APPROVED	35	38	Approved by Department Viva Committee and Faculty Guide
115	2026-10-23 19:52:11.662976	DRAFT	DRAFT	210	39	\N
116	2026-10-23 19:52:11.772595	DRAFT	SUBMITTED	210	39	Submitting capstone draft for faculty guide review.
117	2026-10-23 19:52:12.136615	SUBMITTED	UNDER_REVIEW	39	39	Reviewing drone swarm architecture and simulation parameters.
118	2026-10-23 19:52:12.172306	UNDER_REVIEW	REJECTED	39	39	Please add hardware-in-the-loop (HIL) simulation test results and clarify battery fail-safe protocols before final approval.
119	2026-10-23 19:52:12.241037	REJECTED	DRAFT	210	39	Revised with HIL simulation details.
120	2026-10-23 19:52:12.288089	DRAFT	SUBMITTED	210	39	Re-submitting revised version.
121	2026-10-23 19:52:12.347702	SUBMITTED	UNDER_REVIEW	39	39	Re-evaluation.
122	2026-10-23 19:52:12.392291	UNDER_REVIEW	APPROVED	39	39	Excellent revisions. Approved for public repository.
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, title, abstract, academic_year, semester, project_type, status, visibility, department_id, created_by_user_id, repository_url, created_at, updated_at, guide_faculty_id, plagiarism_score, duplication_score, plagiarism_report, plagiarism_status) FROM stdin;
2	Distress AI: Multi-Modal Surveillance & Safety Detection System	Distress AI is an intelligent multi-modal video surveillance framework designed to detect emotional distress, suspicious physical postures, and immediate safety threats in real-time. By integrating deep learning facial emotion recognition with skeletal posture tracking via MediaPipe, the system continuously monitors camera feeds to identify violent altercations, distress calls, or sudden medical collapses. When a potential threat is identified, the system logs the incident, triggers low-latency dispatcher alerts, and provides campus or enterprise security personnel with contextual video snippets to accelerate emergency response.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	53	\N	2026-10-12 15:14:43.536394+05:30	2026-10-12 18:54:45.311819+05:30	36	\N	\N	\N	NOT_SCANNED
3	SC-GUARD: Smart Contract Vulnerability Detection & Risk Enforcement System	SC-GUARD is an automated smart contract vulnerability detection and security audit platform targeting Ethereum Solidity contracts. The system performs comprehensive Abstract Syntax Tree (AST) static analysis and symbolic execution to identify critical security flaws such as reentrancy vulnerabilities, arithmetic overflows, unchecked external calls, and front-running exposures. Based on detected vulnerability signatures, SC-GUARD calculates a composite security risk index and enforces automated deployment decisions (ALLOW, WARN, or BLOCK), generating detailed diagnostic reports in JSON, HTML, and PDF formats for smart contract developers.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	54	\N	2026-10-12 15:14:56.166495+05:30	2026-10-12 18:54:45.375529+05:30	37	\N	\N	\N	NOT_SCANNED
4	Software Bug Assistant: Autonomous Code Debugging & Remediation Agent	Software Bug Assistant is an autonomous AI agent engineered to streamline the software defect resolution lifecycle using the Agent Development Kit (ADK) and large language model reasoning. The system ingests application crash traces, diagnostic logs, and issue tracker tickets to automatically isolate root causes within codebase repositories. By synthesizing reproduction test harnesses in sandboxed containers, the agent verifies defect existence, generates candidate code patches, runs regression unit tests, and submits formal Pull Requests with comprehensive technical summaries.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	55	\N	2026-10-12 15:14:57.830945+05:30	2026-10-12 18:54:45.434295+05:30	38	\N	\N	\N	NOT_SCANNED
5	QGenesis: Academic Question Bank Generation & Examination Workflow	QGenesis is an AI-powered academic question bank and examination paper workflow orchestration platform developed for higher educational institutions. The platform empowers faculty members to extract and synthesize rigorous examination questions from course syllabi, lecture slides, and reference materials across varying Bloom's taxonomy cognitive levels. QGenesis incorporates role-based approval pipelines routing draft question papers through Head of Department (HOD) review, dynamic paper randomization, and strict institutional confidentiality controls.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	56	\N	2026-10-12 15:15:28.424311+05:30	2026-10-12 18:54:45.49277+05:30	39	\N	\N	\N	NOT_SCANNED
6	PII Shield: Automated Sensitive Data Redaction & Privacy Compliance	PII Shield is an automated sensitive data discovery and redaction platform designed to ensure compliance with institutional and regulatory data privacy mandates (such as GDPR and HIPAA). The system scans unstructured enterprise documents (PDF, DOCX, TXT) using specialized Named Entity Recognition (NER) models and deterministic regular expressions to detect Personally Identifiable Information (PII) including Aadhaar numbers, PAN cards, credit details, email addresses, and phone numbers, permanently redacting sensitive coordinates while preserving document structural readability.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	57	\N	2026-10-12 15:15:35.243754+05:30	2026-10-12 18:54:45.544623+05:30	40	\N	\N	\N	NOT_SCANNED
7	Cloud Log Anomaly Detection with Adaptive Model Selection	This project implements a real-time cloud log anomaly detection framework featuring dynamic detector switching over distributed Kafka message streams. Addressing the challenge of concept drift and bursty cloud infrastructure logs, the architecture evaluates incoming log streams and adaptively toggles between lightweight Static thresholding, statistical Adaptive baselining, and deep-learning LSTM sequence detectors. Experimental evaluation demonstrates enhanced anomaly detection precision and reduced alert fatigue across heterogeneous cloud infrastructure logs.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	58	\N	2026-10-12 15:15:35.518237+05:30	2026-10-12 18:54:45.602558+05:30	41	\N	\N	\N	NOT_SCANNED
8	SybilGuard: Graph-Based Sybil Node Detection & Trust Propagation	SybilGuard is an interactive graph analytics and visualization platform for detecting Sybil accounts (fake, coordinated malicious nodes) within large-scale social network topologies. By implementing random walk-based trust propagation algorithms including SybilRank, SybilWalk, and SybilWalk-Var alongside an ensemble scoring model, the system identifies anomalous clusters where trust fails to propagate naturally. An interactive 3D graph visualization interface enables security analysts to inspect network communities, trace trust vectors, and isolate coordinated inauthentic behavior.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	59	\N	2026-10-12 15:15:43.304372+05:30	2026-10-12 18:54:45.657268+05:30	42	\N	\N	\N	NOT_SCANNED
9	Hybrid XGBoost-LSTM Online Banking Fraud Detection Framework	This research introduces a hybrid machine learning and deep learning architecture for high-velocity online banking fraud detection. The framework pairs an optimized XGBoost gradient-boosted decision tree pipeline for evaluating tabular transaction features (amounts, geolocations, terminal IDs) with a recurrent LSTM neural network that models longitudinal customer spending sequences. The combined model achieves high precision and an 87.41% F1-score on skewed transaction benchmarks, significantly reducing false positive declines while detecting sophisticated financial fraud patterns.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	60	\N	2026-10-12 15:15:43.673209+05:30	2026-10-12 18:54:45.714675+05:30	43	\N	\N	\N	NOT_SCANNED
10	TRUSTLES: Zero Trust Continuous Endpoint Monitoring & Risk Scoring	TRUSTLES is a lightweight enterprise zero-trust endpoint monitoring and continuous posture evaluation system. Operating under the 'never trust, always verify' paradigm, background monitoring agents track process creation, network socket bindings, privilege escalation, and file system anomalies on client machines. Telemetry is streamed to a central risk engine that dynamically computes an endpoint health index, automatically revoking session tokens and isolating endpoints when suspicious behavior or integrity degradation is observed.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	61	\N	2026-10-12 15:15:44.545368+05:30	2026-10-12 18:54:45.803619+05:30	44	\N	\N	\N	NOT_SCANNED
12	Academic Integrity Checker: Anti-Plagiarism & Research Review System	Academic Integrity Checker is an automated research dissertation verification engine designed to uphold academic rigor in institutional project repositories. The platform evaluates submitted abstracts, technical reports, and source code against indexed institutional repositories and open web sources. By combining N-gram fingerprinting, semantic vector distance, and intelligent citation filtering (excluding references, datasets, and standard libraries), the system delivers an objective similarity score and an itemized originality audit report for academic review committees.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	63	\N	2026-10-12 15:15:45.368101+05:30	2026-10-12 18:54:45.960546+05:30	46	\N	\N	\N	NOT_SCANNED
13	Adversarial Robust CNN: Defense Mechanisms Against FGSM & PGD Attacks	This research investigates vulnerabilities in deep Convolutional Neural Networks (CNNs) subjected to adversarial evasion attacks and introduces empirical defense mechanisms. The project benchmarks standard CNN models against Fast Gradient Sign Method (FGSM) and Projected Gradient Descent (PGD) perturbation attacks, demonstrating significant accuracy degradation under imperceptible noise. Through adversarial retraining, gradient regularization, and robust feature feature distillation, the proposed architecture substantially enhances classification robustness on perturbed vision datasets.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	64	\N	2026-10-12 15:16:29.067591+05:30	2026-10-12 18:54:46.030877+05:30	47	\N	\N	\N	NOT_SCANNED
14	DPDE: Decentralized Patient Data Exchange with On-Chain Consent	DPDE (Decentralized Patient Data Exchange) is a patient-centric Electronic Health Record (EHR) management system giving individuals full sovereignty over medical record sharing. Patient medical records are encrypted on the client device prior to network egress and pinned to decentralized InterPlanetary File System (IPFS) storage. Granular data access consent (request, approve, revoke) is managed via smart contracts deployed on the Ethereum testnet, while a Node.js backend maintains auditable access logs and cryptographically enforces on-chain patient permission.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	65	\N	2026-10-12 15:16:33.591252+05:30	2026-10-12 18:54:46.103017+05:30	48	\N	\N	\N	NOT_SCANNED
15	Innovest: AI-Powered Startup Feasibility Evaluation & Matchmaking	Innovest is a comprehensive platform bridging student entrepreneurs and venture investors with integrated AI feasibility analytics. The platform features an automated novelty checker that scans submitted business proposals against indexed startup repositories to prevent duplicated concepts and evaluate commercial viability. Innovest enforces structured feedback loops between mentors, investors, and founders, facilitating milestone-driven incubation within academic institutions.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	66	\N	2026-10-12 15:16:34.481475+05:30	2026-10-12 18:54:46.168249+05:30	49	\N	\N	\N	NOT_SCANNED
16	Automated Outcome-Based Education (OBE) Mapping & Attainment Tool	The Automated Outcome-Based Education (OBE) Mapping Tool is an institutional portal built to automate complex academic accreditation workflows in compliance with NBA and NAAC guidelines. The application maps course outcomes (COs) to program outcomes (POs) and program-specific outcomes (PSOs), processes multi-assessment student scores, and automatically computes direct and indirect attainment levels. The system replaces manual spreadsheets with verifiable analytics dashboards and exportable institutional accreditation reports.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	67	\N	2026-10-12 15:16:35.5426+05:30	2026-10-12 18:54:46.225092+05:30	50	\N	\N	\N	NOT_SCANNED
17	PreVue: AI-Powered Mock Interview & Communication Evaluation Platform	PreVue is a full-stack AI-driven mock interview preparation platform designed to enhance student placement readiness. Candidates undergo interactive simulated interviews featuring automated speech-to-text transcription, NLP semantic analysis of technical responses, and speech fluency evaluations. PreVue delivers personalized performance scorecards highlighting domain competency, pacing, vocabulary richness, and actionable recommendations to help students excel in corporate technical and HR interviews.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	68	\N	2026-10-12 15:16:38.934328+05:30	2026-10-12 18:54:46.282183+05:30	51	\N	\N	\N	NOT_SCANNED
18	Smart Toll: Intelligent FASTag Toll Estimation & Route Optimization	Smart Toll is an intelligent highway travel planning and cost estimation web platform designed for Indian national highways. Users input trip origin and destination points to compute real-time route alternatives, calculate cumulative FASTag toll expenditures across toll plazas, and verify prepaid balance sufficiency before travel. The system incorporates a pre-trip alert notification engine and distance-optimized routing to minimize travel delays and unforeseen highway transit costs.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	69	\N	2026-10-12 15:16:40.367395+05:30	2026-10-12 18:54:46.336681+05:30	34	\N	\N	\N	NOT_SCANNED
19	CloudInsight: Multi-Cloud FinOps & Cost Anomaly Detection Platform	CloudInsight is a comprehensive FinOps analytics platform for monitoring, forecasting, and optimizing multi-cloud expenditures across AWS, Microsoft Azure, and Google Cloud Platform. The system ingests billing logs and cost telemetry, applying time-series anomaly detection algorithms to identify sudden resource billing spikes, orphaned disk volumes, and underutilized instances. Interactive dashboards provide department budget allocations, automated slack notifications, and actionable cloud resource rightsizing recommendations.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	70	\N	2026-10-12 15:16:40.602191+05:30	2026-10-12 18:54:46.396845+05:30	35	\N	\N	\N	NOT_SCANNED
20	EdgeVerify: Distributed Edge IoT Integrity & Attestation System	EdgeVerify is a distributed security framework focused on validating firmware integrity and message authenticity across resource-constrained Edge IoT nodes. Operating without continuous cloud connectivity, edge gateways exchange cryptographic attestation tokens and verify sensor payload hash trees to detect compromised or rogue edge sensors. The system ensures high fault-tolerance, low verification latency, and end-to-end data integrity for critical industrial and smart city IoT deployments.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	71	\N	2026-10-12 15:16:42.933818+05:30	2026-10-12 18:54:46.467762+05:30	36	\N	\N	\N	NOT_SCANNED
22	Malware Detection & Classification Framework Using Machine Learning	This project presents an empirical malware detection and classification engine analyzing Windows Portable Executable (PE) binaries. The framework extracts static feature vectors including PE header fields, section entropy levels, imported API functions, and byte n-gram frequencies. Machine learning classifiers (Random Forest, Support Vector Machines, and Gradient Boosting) are trained to distinguish benign software from ransomware, trojans, and spyware, achieving high classification accuracy with low false-alarm rates.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	73	\N	2026-10-12 15:16:47.9917+05:30	2026-10-12 18:54:46.61748+05:30	38	\N	\N	\N	NOT_SCANNED
23	EduSlot: Academic Campus Resource & Laboratory Booking Portal	EduSlot is a centralized campus resource reservation and scheduling system developed for PSG College of Technology. The platform eliminates scheduling collisions by managing access to computing laboratories, specialized hardware kits, seminar auditoriums, and project incubation spaces. EduSlot features faculty approval workflows, automated email booking notifications, and QR-based reservation passes to optimize institutional infrastructure utilization.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	74	\N	2026-10-12 15:16:49.008046+05:30	2026-10-12 18:54:46.689237+05:30	39	\N	\N	\N	NOT_SCANNED
24	ThinkTwice: AI-Powered Email Tone Reviewer & Writing Enhancement	ThinkTwice is an intelligent browser extension for Google Chrome that assists users in reviewing and refining written correspondence prior to transmission. Compatible with Gmail, LinkedIn, and WhatsApp Web, the extension evaluates draft messages using sentiment analysis and tone classification. ThinkTwice highlights potential tone misalignments (such as unintended aggression, passive-aggressiveness, or unprofessional phrasing) and suggests context-appropriate rewrites tailored for colleagues, supervisors, or external clients.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	75	\N	2026-10-12 15:16:53.676022+05:30	2026-10-12 18:54:46.744376+05:30	40	\N	\N	\N	NOT_SCANNED
25	Personalized Music Recommendation Engine Using Hybrid Filtering	This project develops a hybrid personalized music recommendation engine combining acoustic audio feature extraction with collaborative filtering algorithms. Using Librosa, the system extracts spectral contrast, tempo, and MFCC features from audio waveforms to quantify acoustic similarity, while matrix factorization models user listening histories. The hybrid approach mitigates the cold-start problem for newly released tracks and delivers tailored music discovery playlists aligned with user preference profiles.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	76	\N	2026-10-12 15:16:53.994315+05:30	2026-10-12 18:54:46.800221+05:30	41	\N	\N	\N	NOT_SCANNED
26	Apartment Manager: Community Living & Facility Maintenance Platform	Apartment Manager is a full-stack residential community management portal streamlining facility administration and resident communication. The platform automates monthly maintenance billing, provides digital payment tracking, and features an SLA-backed maintenance ticketing module for plumbing, electrical, and facility complaints. Role-based dashboards for residents, committee administrators, and security personnel ensure transparent residential society operations.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	77	\N	2026-10-12 15:16:58.824808+05:30	2026-10-12 18:54:46.849395+05:30	42	\N	\N	\N	NOT_SCANNED
27	KeySense: Behavioral Biometric Authentication via Keystroke Dynamics	KeySense is a continuous identity authentication system leveraging behavioral biometrics derived from user keystroke and mouse interaction dynamics. By capturing keystroke hold times, key flight intervals, and mouse curvature kinematics during natural computer interaction, KeySense trains personalized anomaly detection models to verify active user identity. The system provides non-intrusive secondary authentication, automatically locking sessions when anomalous typing behavior indicates unauthorized workstation takeover.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	78	\N	2026-10-12 15:17:00.172941+05:30	2026-10-12 18:54:46.897998+05:30	43	\N	\N	\N	NOT_SCANNED
28	Segro: IoT Automated Waste Classification & Robotic Segregation	Segro is an embedded IoT and computer vision waste segregation system engineered to automate solid waste sorting at the point of disposal. The hardware apparatus utilizes inductive proximity sensors, capacitive moisture probes, and camera feeds to classify waste into biodegradable, metallic, and recyclable categories. Motorized servo actuators steer waste into designated bins, while telemetry logged over MQTT provides municipal administrators with real-time bin fill-level notifications and waste generation statistics.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	79	\N	2026-10-12 15:17:07.076506+05:30	2026-10-12 18:54:46.953607+05:30	44	\N	\N	\N	NOT_SCANNED
30	NextDoorConnect: Hyperlocal Community Resource Sharing & Service Network	NextDoorConnect is a hyperlocal community platform designed to foster mutual assistance and resource sharing among verified neighborhood residents. The platform enables residents to lend household equipment, offer local tutoring or handyman skills, organize neighborhood clean-ups, and broadcast urgent local safety alerts. By restricting membership to geographic zones and verifying address credentials, NextDoorConnect creates a secure, trusted digital community network.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	81	\N	2026-10-12 15:17:07.996654+05:30	2026-10-12 18:54:47.065592+05:30	46	\N	\N	\N	NOT_SCANNED
31	TechPack Analyzer: Automated Apparel Bill of Materials & Costing Platform	TechPack Analyzer is an apparel enterprise web application designed to automate Bill of Materials (BOM) generation and costing estimation from technical garment specification sheets. The application parses client tech pack PDFs, extracting fabric compositions, garment dimensions, trim requirements, and colorway codes. Merchandisers can configure unit material pricing to instantly generate accurate production costing sheets and export professional Excel BOM reports for textile manufacturing export houses.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	82	\N	2026-10-12 15:17:10.894016+05:30	2026-10-12 18:54:47.119314+05:30	47	\N	\N	\N	NOT_SCANNED
1	NexusLOS: Explainable AI Loan Origination System	NexusLOS is an advanced AI-driven Loan Origination System designed to provide high-accuracy credit scoring while prioritizing borrower transparency and regulatory compliance. Unlike traditional black-box machine learning models that reject loan applicants without clear justification, NexusLOS utilizes Explainable AI (XAI) with SHAP and LIME to generate specific reason codes and actionable rejection roadmaps for borrowers. The system implements a dual lending path evaluating both income-based repayment capacity from banking telemetry and asset-based lending collateral, providing a transparent, auditable, and equitable digital lending infrastructure.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	52	\N	2026-10-12 15:14:28.395011+05:30	2026-10-12 18:54:45.069602+05:30	35	\N	\N	\N	NOT_SCANNED
11	Secure Image System: Chen Hyperchaotic & RSA-AES Encryption	Secure Image System is a high-security multimedia encryption and transfer framework combining Chen hyperchaotic systems with hybrid asymmetric-symmetric cryptography. The pipeline utilizes the high-dimensional pseudo-random entropy of Chen chaotic attractors to perform pixel-level position scrambling and diffusion, followed by AES-256-CBC cipher block chaining. Session keys are secured via RSA-2048/OAEP asymmetric key exchange, ensuring resilience against differential cryptanalysis, statistical pixel distribution attacks, and eavesdropping during high-speed image transmission.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	62	\N	2026-10-12 15:15:44.663811+05:30	2026-10-12 18:54:45.884894+05:30	45	\N	\N	\N	NOT_SCANNED
21	EvoDoc: AI-Driven Continuous Codebase Documentation System	EvoDoc is an intelligent developer assistant integrated into Visual Studio Code that automates codebase documentation generation and continuous documentation validation. Operating in watch mode, EvoDoc parses Abstract Syntax Trees (ASTs) on file saves to synchronize inline documentation, class diagrams, and API specifications with evolving code changes. Built-in coverage audits identify undocumented functions and stale comments, ensuring codebase maintainability in agile development environments.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	72	\N	2026-10-12 15:16:47.902195+05:30	2026-10-12 18:54:46.54194+05:30	37	\N	\N	\N	NOT_SCANNED
33	Own Drive: Hybrid Local-Cloud Storage System with Intelligent Tiering	Own Drive is an intelligent hybrid file storage solution that seamlessly unifies local disk storage with Google Drive cloud infrastructure. Operating through a 3-priority classification pipeline (user-defined rules, file access metadata, and predictive ML classification), Own Drive automatically tiers frequently accessed sensitive files to high-speed local storage while archiving cold backups to cloud storage. The system features JWT authentication, encrypted transfers, and transparent virtual filesystem access.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	84	\N	2026-10-12 15:17:14.438563+05:30	2026-10-12 18:54:47.23202+05:30	49	\N	\N	\N	NOT_SCANNED
34	Bulkify: High-Throughput Asynchronous Data Ingestion & Transformation Engine	Bulkify is a high-throughput, fault-tolerant batch data processing pipeline engineered to ingest, validate, and transform massive enterprise datasets without service degradation. Implementing stream-based chunking, Redis-backed job queues, and dead-letter error queues, Bulkify processes millions of records with strict schema validation and real-time ingestion monitoring dashboards, ensuring robust data loading for enterprise analytics warehouses.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	85	\N	2026-10-12 15:17:15.036762+05:30	2026-10-12 18:54:47.280414+05:30	50	\N	\N	\N	NOT_SCANNED
35	SpeakMate: AI Public Speaking Coach & Verbal Fluency Platform	SpeakMate is an interactive web-based speech coaching platform tailored for postgraduate students to improve their English public speaking and presentation fluency. Through structured, level-based speaking challenges, SpeakMate analyzes live audio streams to evaluate speaking rate, pause frequency, filler-word repetition ('um', 'uh', 'like'), and grammatical clarity. Candidates receive visual analytics dashboards with targeted vocal drills to build confident professional communication skills.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	86	\N	2026-10-12 15:17:17.368486+05:30	2026-10-12 18:54:47.329758+05:30	51	\N	\N	\N	NOT_SCANNED
36	ThinkInLogic: Adaptive Coding Platform with Q-Learning Recommendations	ThinkInLogic is an adaptive programming education platform designed by Jawahar Paisal P (24MX320) that personalizes coding problem recommendations using a Reinforcement Learning (Q-learning) engine. The system continuously evaluates student submission success rates, time-to-solve metrics, and code efficiency across difficulty levels, dynamically adapting the learning curve to address individual algorithmic weaknesses and maximize campus placement readiness.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	87	\N	2026-10-12 15:17:19.639134+05:30	2026-10-12 18:54:47.383142+05:30	34	\N	\N	\N	NOT_SCANNED
37	NIPDS: Network Intrusion Prevention & Deep Packet Inspection System	NIPDS (Network Intrusion Prevention and Detection System) is a high-speed network monitoring engine designed to safeguard enterprise local area networks against malicious traffic. Utilizing raw socket packet capture and deep packet inspection (DPI), NIPDS detects signature patterns of SYN flood attacks, port scans, DNS poisoning, and unauthorized shellcode payloads. The system logs security events to a centralized SIEM dashboard and automatically updates local firewall tables to drop malicious source IPs.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	88	\N	2026-10-12 15:17:19.719043+05:30	2026-10-12 18:54:47.43192+05:30	35	\N	\N	\N	NOT_SCANNED
38	Dubbify: Multi-Lingual Video Dubbing & Neural Voiceover Engine	Dubbify is an automated multimedia localization engine that dubs video recordings into regional Indian and international languages while preserving natural speaker pacing. The pipeline utilizes OpenAI Whisper for speech-to-text diarization, neural machine translation for semantic cross-lingual mapping, and neural text-to-speech models to synthesize localized audio tracks. FFmpeg dynamically adjusts speech timing and overlays the synthesized audio onto the original video with lip-sync alignment.	2023-2025	4	CAPSTONE	APPROVED	PUBLIC	1	89	\N	2026-10-12 15:17:28.800002+05:30	2026-10-12 18:54:47.481314+05:30	36	\N	\N	\N	NOT_SCANNED
29	TN SchemeBot: Tamil Nadu Citizen Welfare Scheme Recommendation Engine	TN SchemeBot is a conversational AI e-governance assistant built to help citizens discover and apply for Tamil Nadu state and central welfare schemes. Through intuitive natural language dialogue in English and Tamil, the chatbot collects applicant eligibility parameters (income, occupation, educational status, demographic category) and matches them against indexed government scheme repositories. The system details entitlement benefits, required documentation, and direct official application links to enhance public welfare access.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	80	\N	2026-10-12 15:17:07.213817+05:30	2026-10-12 18:54:47.013528+05:30	45	\N	\N	\N	NOT_SCANNED
32	LoraOffNet: Offline LoRa Mesh-Based Emergency Communication & Payment System	LoraOffNet is a disaster-resilient off-grid communication and micro-transaction framework operating without cellular or internet infrastructure. The architecture connects smartphones via local Wi-Fi access points to ESP32 LoRa nodes, which form an ad-hoc long-range radio mesh network using the SX1276 transceiver. The system enables reliable text messaging, emergency SOS beaconing, and cryptographically verified offline store-and-forward digital payments during natural disasters and remote network blackouts.	2024-2026	4	CAPSTONE	APPROVED	PUBLIC	1	83	\N	2026-10-12 15:17:13.995679+05:30	2026-10-12 18:54:47.173822+05:30	48	\N	\N	\N	NOT_SCANNED
39	Edge-Assisted Autonomous Drone Fleet Coordination for Disaster Relief	This research designs an edge-computing swarm intelligence protocol for autonomous disaster response drones. Utilizing distributed consensus algorithms and lightweight vision models running on Jetson Nano edge modules, the system dynamically maps disaster zones without centralized cloud connectivity.	2025-2026	4	Capstone Project	APPROVED	PUBLIC	1	210	https://github.com/mca-dept/drone-swarm-relief	2026-10-23 19:52:11.607571+05:30	2026-10-23 19:52:12.396805+05:30	39	8	5	{"duplication_verdict":"UNIQUE","duplication_score":5.0,"plagiarism_score":8.0,"uncited_matches":[],"matched_archived_projects":[],"recommendation_for_faculty":"Draft verified with low similarity score. Ready for faculty review.","plagiarism_verdict":"CLEAN","summary_explanation":"Automated scan verified project submission originality and citations.","valid_citations_detected":[{"citation_text":"Repository reference provided: https://github.com/mca-dept/drone-swarm-relief","source_type":"REFERENCE_CITATION","status":"EXCLUDED_FROM_PLAGIARISM"}]}	COMPLETED
\.


--
-- Data for Name: student_roster; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_roster (id, roll_no, name, email, batch, department_id, is_eligible, is_registered, created_at, updated_at) FROM stdin;
11	25MX111	JARJILA DENET J	25mx111@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
12	25MX112	KAAVYA	25mx112@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
13	25MX113	KALEEL UR RAHMAN	25mx113@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
14	25MX114	KAVIN M	25mx114@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
15	25MX115	KRISHNA PRIYA	25mx115@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
16	25MX116	MIRUNA MV	25mx116@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
17	25MX117	MOHANKUMAR P	25mx117@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
18	25MX118	OVIYA S	25mx118@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
19	25MX120	R SIBIDHARAN	25mx120@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
20	25MX121	SATHISH M	25mx121@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
21	25MX122	SHAARUKESH K.R	25mx122@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
22	25MX123	SRI MONIKA J	25mx123@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
23	25MX124	SRINITHI J	25mx124@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
24	25MX125	STEPHINA SMILY C	25mx125@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
25	25MX126	SURYA KRISHNA S	25mx126@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
26	25MX127	SWARNA RATHNA A	25mx127@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
27	25MX128	SWEATHA A M	25mx128@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
28	25MX130	VISHAL KARTHIKEYAN P	25mx130@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
29	25MX201	ANUVARSHINI	25mx201@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
30	25MX202	ARJUN VISHWAS B	25mx202@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
31	25MX203	BADHRINARAYANAN S K	25mx203@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
32	25MX204	CHINNAYA K	25mx204@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
33	25MX205	DEEPIKA RAJA LAKSHAYA G	25mx205@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
34	25MX206	DEVIBALA N	25mx206@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
35	25MX207	DHEEPTHI R.R	25mx207@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
36	25MX208	DINAKARAN T	25mx208@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
37	25MX209	DIVAKAR	25mx209@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
38	25MX210	S.GAYATHRI	25mx210@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
39	25MX211	JOSHNA K	25mx211@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
40	25MX212	KARTHEESVARAN S	25mx212@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
41	25MX213	MOWLIDHARAN	25mx213@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
42	25MX214	NAGAKEERTHANAA N	25mx214@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
43	25MX215	PREETHI S	25mx215@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
44	25MX216	PRIYADHARSHINI S	25mx216@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
45	25MX217	R.G.A.SAKTHIVEL MALLAIAH	25mx217@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
46	25MX218	REENA CAROLIN S	25mx218@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
47	25MX219	SARAN K	25mx219@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
48	25MX220	SARAVANAVEL P	25mx220@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
49	25MX221	SHAIRAAJ V S	25mx221@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
50	25MX222	SHANMUGA PRIYA S	25mx222@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
51	25MX223	SHANMUGAPPRIYA K	25mx223@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
52	25MX224	SRIRAM S S	25mx224@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
53	25MX225	SRIRAM V	25mx225@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
54	25MX226	SUDHARSANAN	25mx226@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
55	25MX227	SUDHERSON V	25mx227@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
56	25MX228	SUPREETH K R	25mx228@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
57	25MX229	SURYA L	25mx229@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
58	25MX230	THAMIZHTHILAGA S D S	25mx230@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
59	25MX231	VAISHNAVI	25mx231@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
60	25MX232	VISHALY S	25mx232@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
61	25MX301	ABISHEK S	25mx301@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
62	25MX304	ARAVINDH KANNAN M S	25mx304@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
63	25MX305	BHUVISHA SRI PRIYA P	25mx305@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
64	25MX306	CHITTESH	25mx306@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
65	25MX307	DARUNYA SRI M	25mx307@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
68	25MX310	DHAKSHANAMOORTHY S	25mx310@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
69	25MX311	R.DINESH KUMAR	25mx311@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
70	25MX312	DINESH KUMAR S	25mx312@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
71	25MX313	G LALIT CHANDRAN	25mx313@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
72	25MX314	HARI ANAND B	25mx314@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
73	25MX315	INDUJA E	25mx315@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
74	25MX316	JACKSON SOLOMON RAJ M	25mx316@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
3	25MX103	BARATHVIKRAMAN S K	25mx103@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
66	25MX308	DAYANANDA J	25mx308@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
4	25MX104	DEEPIKAA B S	25mx104@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
5	25MX105	DIVYA R	25mx105@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
6	25MX106	DIVYADHARSHINI K	25mx106@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
7	25MX107	G SHREE NIVETHA	25mx107@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
8	25MX108	GOBBIKA J M	25mx108@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
9	25MX109	GOPINATH R G	25mx109@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
10	25MX110	HARIKESAN D J	25mx110@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
67	25MX309	DEEPA M	25mx309@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
75	25MX317	JANANI T G	25mx317@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
76	25MX318	JEEVA SILVIYA J	25mx318@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
77	25MX319	JESSICA A	25mx319@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
100	25MX342	ROHITHMAHESHWARAN K	25mx342@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
101	25MX343	SABARISH P	25mx343@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
102	25MX345	SHRI SANJAY	25mx345@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
103	25MX346	SIDDARTH M R	25mx346@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
104	25MX347	SIVAPRADEESH M	25mx347@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
105	25MX348	SOBAN S S	25mx348@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
106	25MX349	SOWMIYA	25mx349@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
107	25MX350	SRIVIKASHNI S	25mx350@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
108	25MX351	SURIYA G V	25mx351@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
109	25MX352	TAMILINI S	25mx352@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
110	25MX353	THRISHA R	25mx353@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
111	25MX354	TINO BRITTY J	25mx354@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
112	25MX355	VAISHALI S	25mx355@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
113	25MX356	VIGNESH M	25mx356@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
114	25MX357	VIJAYA SREE K	25mx357@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
115	25MX358	VIKRAM SETHUPATHY S	25mx358@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
116	25MX359	VISHNUVARDANI K S	25mx359@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
117	25MX360	YASWANTH R T	25mx360@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
118	25MX361	SANJANA M	25mx361@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
119	25MX363	THARUN S	25mx363@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
1	25MX101	BALAJI K	25mx101@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
2	25MX102	BALASUBRAMANIAM S	25mx102@psgtech.ac.in	2025-2027	1	t	t	2026-10-12 19:14:29.749034	2026-10-23 20:50:59.834814
78	25MX320	JOSHNIE T	25mx320@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
79	25MX321	KARTHICK	25mx321@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
80	25MX322	KASBIYA M	25mx322@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
81	25MX323	KEERTHANAA J	25mx323@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
82	25MX324	KEVIN JOHNSON A A	25mx324@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
83	25MX325	KIRSAAN.F	25mx325@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
84	25MX326	MEYAPPAN R	25mx326@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
85	25MX327	MITHRA N	25mx327@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
86	25MX328	MITHULESH N	25mx328@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
87	25MX329	MOHANA PRIYA M	25mx329@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
88	25MX330	MONISH P	25mx330@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
89	25MX331	MUGUNDHAN K P	25mx331@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
90	25MX332	MUTHU SAILAPPAN A K	25mx332@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
91	25MX333	NAGA SRUTHI M	25mx333@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
92	25MX334	NANDHITHASRI	25mx334@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
93	25MX335	NAVEEN PRANAB T	25mx335@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
94	25MX336	NITHEESH MUTHU KRISHNAN C	25mx336@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
95	25MX337	NITHYASHREE C	25mx337@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
96	25MX338	POORANI R	25mx338@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
97	25MX339	PRABHAKAR O S	25mx339@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
98	25MX340	R.PURATCHIYAN	25mx340@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
99	25MX341	RADHU DHARSAN க M	25mx341@psgtech.ac.in	2025-2027	1	t	f	2026-10-12 19:14:29.749034	2026-10-13 08:23:46.105327
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, role, user_status, department_id, is_active, created_at, updated_at, name, roll_no, must_change_password, otp_code, otp_expiry, failed_login_attempts, lockout_until) FROM stdin;
93	25mx103@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	BARATHVIKRAMAN S K	25MX103	t	\N	\N	0	\N
94	25mx104@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DEEPIKAA B S	25MX104	t	\N	\N	0	\N
95	25mx105@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DIVYA R	25MX105	t	\N	\N	0	\N
96	25mx106@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DIVYADHARSHINI K	25MX106	t	\N	\N	0	\N
97	25mx107@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	G SHREE NIVETHA	25MX107	t	\N	\N	0	\N
98	25mx108@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	GOBBIKA J M	25MX108	t	\N	\N	0	\N
99	25mx109@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	GOPINATH R G	25MX109	t	\N	\N	0	\N
100	25mx110@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	HARIKESAN D J	25MX110	t	\N	\N	0	\N
101	25mx111@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JARJILA DENET J	25MX111	t	\N	\N	0	\N
102	25mx112@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KAAVYA	25MX112	t	\N	\N	0	\N
103	25mx113@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KALEEL UR RAHMAN	25MX113	t	\N	\N	0	\N
104	25mx114@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KAVIN M	25MX114	t	\N	\N	0	\N
105	25mx115@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KRISHNA PRIYA	25MX115	t	\N	\N	0	\N
106	25mx116@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MIRUNA MV	25MX116	t	\N	\N	0	\N
107	25mx117@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MOHANKUMAR P	25MX117	t	\N	\N	0	\N
108	25mx118@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	OVIYA S	25MX118	t	\N	\N	0	\N
109	25mx120@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	R SIBIDHARAN	25MX120	t	\N	\N	0	\N
110	25mx121@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SATHISH M	25MX121	t	\N	\N	0	\N
111	25mx122@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SHAARUKESH K.R	25MX122	t	\N	\N	0	\N
112	25mx123@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SRI MONIKA J	25MX123	t	\N	\N	0	\N
113	25mx124@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SRINITHI J	25MX124	t	\N	\N	0	\N
114	25mx125@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	STEPHINA SMILY C	25MX125	t	\N	\N	0	\N
115	25mx126@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SURYA KRISHNA S	25MX126	t	\N	\N	0	\N
116	25mx127@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SWARNA RATHNA A	25MX127	t	\N	\N	0	\N
117	25mx128@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SWEATHA A M	25MX128	t	\N	\N	0	\N
118	25mx130@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VISHAL KARTHIKEYAN P	25MX130	t	\N	\N	0	\N
119	25mx201@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	ANUVARSHINI	25MX201	t	\N	\N	0	\N
120	25mx202@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	ARJUN VISHWAS B	25MX202	t	\N	\N	0	\N
121	25mx203@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	BADHRINARAYANAN S K	25MX203	t	\N	\N	0	\N
71	24mx207@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:42.933089+05:30	2026-10-12 15:16:42.933089+05:30	24MX207	24MX207	t	\N	\N	0	\N
52	24mx106@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:03:14.37836+05:30	2026-10-12 15:03:14.37836+05:30	24MX106	24MX106	t	\N	\N	0	\N
64	24mx119@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:29.066203+05:30	2026-10-12 15:16:29.066203+05:30	24MX119	24MX119	t	\N	\N	0	\N
65	24mx113@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:33.590566+05:30	2026-10-12 15:16:33.590566+05:30	Manishankar V	24MX113	t	\N	\N	0	\N
66	24mx206@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:34.480871+05:30	2026-10-12 15:16:34.480871+05:30	Dharsini B	24MX206	t	\N	\N	0	\N
67	24mx318@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:35.541965+05:30	2026-10-12 15:16:35.541965+05:30	Janani M	24MX318	t	\N	\N	0	\N
68	24mx319@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:38.933712+05:30	2026-10-12 15:16:38.933712+05:30	M Janani	24MX319	t	\N	\N	0	\N
69	24mx310@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:40.366816+05:30	2026-10-12 15:16:40.366816+05:30	Dharshini V	24MX310	t	\N	\N	0	\N
70	24mx109@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:40.601621+05:30	2026-10-12 15:16:40.601621+05:30	24MX109	24MX109	t	\N	\N	0	\N
122	25mx204@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	CHINNAYA K	25MX204	t	\N	\N	0	\N
123	25mx205@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DEEPIKA RAJA LAKSHAYA G	25MX205	t	\N	\N	0	\N
124	25mx206@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DEVIBALA N	25MX206	t	\N	\N	0	\N
125	25mx207@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DHEEPTHI R.R	25MX207	t	\N	\N	0	\N
126	25mx208@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DINAKARAN T	25MX208	t	\N	\N	0	\N
127	25mx209@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DIVAKAR	25MX209	t	\N	\N	0	\N
128	25mx210@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	S.GAYATHRI	25MX210	t	\N	\N	0	\N
129	25mx211@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JOSHNA K	25MX211	t	\N	\N	0	\N
130	25mx212@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KARTHEESVARAN S	25MX212	t	\N	\N	0	\N
131	25mx213@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MOWLIDHARAN	25MX213	t	\N	\N	0	\N
132	25mx214@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NAGAKEERTHANAA N	25MX214	t	\N	\N	0	\N
133	25mx215@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	PREETHI S	25MX215	t	\N	\N	0	\N
134	25mx216@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	PRIYADHARSHINI S	25MX216	t	\N	\N	0	\N
135	25mx217@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	R.G.A.SAKTHIVEL MALLAIAH	25MX217	t	\N	\N	0	\N
136	25mx218@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	REENA CAROLIN S	25MX218	t	\N	\N	0	\N
137	25mx219@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SARAN K	25MX219	t	\N	\N	0	\N
138	25mx220@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SARAVANAVEL P	25MX220	t	\N	\N	0	\N
139	25mx221@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SHAIRAAJ V S	25MX221	t	\N	\N	0	\N
140	25mx222@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SHANMUGA PRIYA S	25MX222	t	\N	\N	0	\N
141	25mx223@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SHANMUGAPPRIYA K	25MX223	t	\N	\N	0	\N
142	25mx224@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SRIRAM S S	25MX224	t	\N	\N	0	\N
143	25mx225@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SRIRAM V	25MX225	t	\N	\N	0	\N
144	25mx226@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SUDHARSANAN	25MX226	t	\N	\N	0	\N
145	25mx227@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SUDHERSON V	25MX227	t	\N	\N	0	\N
146	25mx228@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SUPREETH K R	25MX228	t	\N	\N	0	\N
147	25mx229@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SURYA L	25MX229	t	\N	\N	0	\N
148	25mx230@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	THAMIZHTHILAGA S D S	25MX230	t	\N	\N	0	\N
149	25mx231@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VAISHNAVI	25MX231	t	\N	\N	0	\N
150	25mx232@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VISHALY S	25MX232	t	\N	\N	0	\N
151	25mx301@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	ABISHEK S	25MX301	t	\N	\N	0	\N
152	25mx304@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	ARAVINDH KANNAN M S	25MX304	t	\N	\N	0	\N
153	25mx305@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	BHUVISHA SRI PRIYA P	25MX305	t	\N	\N	0	\N
154	25mx306@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	CHITTESH	25MX306	t	\N	\N	0	\N
155	25mx307@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DARUNYA SRI M	25MX307	t	\N	\N	0	\N
156	25mx308@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DAYANANDA J	25MX308	t	\N	\N	0	\N
157	25mx309@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DEEPA M	25MX309	t	\N	\N	0	\N
87	24mx320@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:19.638688+05:30	2026-10-12 15:17:19.638688+05:30	Jawahar Paisal P	24MX320	t	\N	\N	0	\N
158	25mx310@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DHAKSHANAMOORTHY S	25MX310	t	\N	\N	0	\N
159	25mx311@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	R.DINESH KUMAR	25MX311	t	\N	\N	0	\N
160	25mx312@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	DINESH KUMAR S	25MX312	t	\N	\N	0	\N
161	25mx313@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	G LALIT CHANDRAN	25MX313	t	\N	\N	0	\N
162	25mx314@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	HARI ANAND B	25MX314	t	\N	\N	0	\N
163	25mx315@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	INDUJA E	25MX315	t	\N	\N	0	\N
164	25mx316@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JACKSON SOLOMON RAJ M	25MX316	t	\N	\N	0	\N
165	25mx317@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JANANI T G	25MX317	t	\N	\N	0	\N
166	25mx318@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JEEVA SILVIYA J	25MX318	t	\N	\N	0	\N
167	25mx319@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JESSICA A	25MX319	t	\N	\N	0	\N
168	25mx320@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	JOSHNIE T	25MX320	t	\N	\N	0	\N
169	25mx321@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KARTHICK	25MX321	t	\N	\N	0	\N
170	25mx322@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KASBIYA M	25MX322	t	\N	\N	0	\N
171	25mx323@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KEERTHANAA J	25MX323	t	\N	\N	0	\N
172	25mx324@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KEVIN JOHNSON A A	25MX324	t	\N	\N	0	\N
173	25mx325@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	KIRSAAN.F	25MX325	t	\N	\N	0	\N
174	25mx326@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MEYAPPAN R	25MX326	t	\N	\N	0	\N
175	25mx327@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MITHRA N	25MX327	t	\N	\N	0	\N
176	25mx328@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MITHULESH N	25MX328	t	\N	\N	0	\N
177	25mx329@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MOHANA PRIYA M	25MX329	t	\N	\N	0	\N
178	25mx330@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MONISH P	25MX330	t	\N	\N	0	\N
179	25mx331@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MUGUNDHAN K P	25MX331	t	\N	\N	0	\N
180	25mx332@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	MUTHU SAILAPPAN A K	25MX332	t	\N	\N	0	\N
181	25mx333@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NAGA SRUTHI M	25MX333	t	\N	\N	0	\N
182	25mx334@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NANDHITHASRI	25MX334	t	\N	\N	0	\N
183	25mx335@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NAVEEN PRANAB T	25MX335	t	\N	\N	0	\N
184	25mx336@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NITHEESH MUTHU KRISHNAN C	25MX336	t	\N	\N	0	\N
185	25mx337@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	NITHYASHREE C	25MX337	t	\N	\N	0	\N
207	25mx360@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	YASWANTH R T	25MX360	t	\N	\N	0	\N
208	25mx361@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SANJANA M	25MX361	t	\N	\N	0	\N
209	25mx363@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	THARUN S	25MX363	t	\N	\N	0	\N
210	25mx101@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:59.739365+05:30	BALAJI K	25MX101	t	\N	\N	0	\N
72	24mx118@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:47.901793+05:30	2026-10-12 15:16:47.901793+05:30	24MX118	24MX118	t	\N	\N	0	\N
73	24mx213@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:47.991052+05:30	2026-10-12 15:16:47.991052+05:30	24MX213	24MX213	t	\N	\N	0	\N
74	24mx230@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:49.007425+05:30	2026-10-12 15:16:49.007425+05:30	Venisha	24MX230	t	\N	\N	0	\N
75	24mx312@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:53.675429+05:30	2026-10-12 15:16:53.675429+05:30	24MX312	24MX312	t	\N	\N	0	\N
76	24mx354@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:53.993617+05:30	2026-10-12 15:16:53.993617+05:30	24MX354	24MX354	t	\N	\N	0	\N
43	vur.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Umarani V	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
44	jgt.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Gowri Thangam J	Assistant Professor (Sr. Gr.)	t	\N	\N	0	\N
45	kgi.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Gayathri K	Assistant Professor (Sr. Gr.)	t	\N	\N	0	\N
46	ran.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Ms. Aruna R	Assistant Professor	t	\N	\N	0	\N
47	vvn.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Venkatesan V	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
48	amr.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Manoranjitham A	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
49	nrj.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Rajeswari N	Assistant Professor (Sr. Gr.)	t	\N	\N	0	\N
50	asa.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Aarthi Mai A S	Assistant Professor	t	\N	\N	0	\N
51	abh.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Bhuvaneswari A	Assistant Professor	t	\N	\N	0	\N
19	admin@psgtech.ac.in	$2a$10$yj9QYa6wDSQ4NEWn22aGGeGcTZoqm6DUeGGlSXxrIk636CQ3acqSi	ADMIN	ACTIVE	1	t	2026-08-17 15:06:48.085572+05:30	2026-08-24 13:57:49.688694+05:30	Department Admin	HOD-MCA	f	\N	\N	0	\N
77	24mx104@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:16:58.824152+05:30	2026-10-12 15:16:58.824152+05:30	24MX104	24MX104	t	\N	\N	0	\N
78	24mx127@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:00.172432+05:30	2026-10-12 15:17:00.172432+05:30	24MX127	24MX127	t	\N	\N	0	\N
53	24mx217@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:11:36.559013+05:30	2026-10-12 15:11:36.559013+05:30	24MX217	24MX217	t	\N	\N	0	\N
54	24mx108@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:11:49.153334+05:30	2026-10-12 15:11:49.153334+05:30	24MX108	24MX108	t	\N	\N	0	\N
187	25mx339@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	PRABHAKAR O S	25MX339	t	\N	\N	0	\N
188	25mx340@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	R.PURATCHIYAN	25MX340	t	\N	\N	0	\N
189	25mx341@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	RADHU DHARSAN க M	25MX341	t	\N	\N	0	\N
190	25mx342@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	ROHITHMAHESHWARAN K	25MX342	t	\N	\N	0	\N
191	25mx343@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SABARISH P	25MX343	t	\N	\N	0	\N
192	25mx345@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SHRI SANJAY	25MX345	t	\N	\N	0	\N
193	25mx346@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SIDDARTH M R	25MX346	t	\N	\N	0	\N
55	24mx219@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:11:50.863822+05:30	2026-10-12 15:11:50.863822+05:30	Nithesh S	24MX219	t	\N	\N	0	\N
56	24mx301@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:21.555204+05:30	2026-10-12 15:12:21.555204+05:30	24MX301	24MX301	t	\N	\N	0	\N
57	24mx317@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:28.277701+05:30	2026-10-12 15:12:28.277701+05:30	24MX317	24MX317	t	\N	\N	0	\N
58	24mx353@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:28.595971+05:30	2026-10-12 15:12:28.595971+05:30	24MX353	24MX353	t	\N	\N	0	\N
59	24mx203@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:36.370654+05:30	2026-10-12 15:12:36.370654+05:30	24MX203	24MX203	t	\N	\N	0	\N
60	24mx211@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:36.806434+05:30	2026-10-12 15:12:36.806434+05:30	24MX211	24MX211	t	\N	\N	0	\N
61	24mx229@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:37.606828+05:30	2026-10-12 15:12:37.606828+05:30	24MX229	24MX229	t	\N	\N	0	\N
62	24mx101@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:37.74624+05:30	2026-10-12 15:12:37.74624+05:30	24MX101	24MX101	t	\N	\N	0	\N
63	24mx128@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:12:38.575263+05:30	2026-10-12 15:12:38.575263+05:30	24MX128	24MX128	t	\N	\N	0	\N
79	24mx221@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:07.07595+05:30	2026-10-12 15:17:07.07595+05:30	24MX221	24MX221	t	\N	\N	0	\N
80	24mx327@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:07.213242+05:30	2026-10-12 15:17:07.213242+05:30	24MX327	24MX327	t	\N	\N	0	\N
81	24mx116@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:07.99617+05:30	2026-10-12 15:17:07.99617+05:30	24MX116	24MX116	t	\N	\N	0	\N
82	24mx215@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:10.89305+05:30	2026-10-12 15:17:10.89305+05:30	24MX215	24MX215	t	\N	\N	0	\N
83	24mx222@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:13.995149+05:30	2026-10-12 15:17:13.995149+05:30	24MX222	24MX222	t	\N	\N	0	\N
84	24mx205@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:14.437957+05:30	2026-10-12 15:17:14.437957+05:30	Boopathirajan M	24MX205	t	\N	\N	0	\N
85	24mx216@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:15.035887+05:30	2026-10-12 15:17:15.035887+05:30	24MX216	24MX216	t	\N	\N	0	\N
86	24mx227@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:17.367773+05:30	2026-10-12 15:17:17.367773+05:30	24MX227	24MX227	t	\N	\N	0	\N
34	nir.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Ilayaraja N	Assistant Professor & Head (i/c)	t	\N	\N	0	\N
35	vrm.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Manavalan R	Associate Professor	t	\N	\N	0	\N
36	akk.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mrs. Kalyani A	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
88	24mx359@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:19.718458+05:30	2026-10-12 15:17:19.718458+05:30	24MX359	24MX359	t	\N	\N	0	\N
89	23mx221@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	ALUMNI	1	t	2026-10-12 15:17:28.799369+05:30	2026-10-12 15:17:28.799369+05:30	23MX221	23MX221	t	\N	\N	0	\N
37	ac.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Chitra A	Professor	t	\N	\N	0	\N
38	dras.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Sankar A	Professor	t	\N	\N	0	\N
39	sng.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Geetha N	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
40	sba.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Bhama S	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
41	msa.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Dr. Subathra M	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
42	csr.mca@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	FACULTY	ACTIVE	1	t	2026-09-29 21:03:49.73885+05:30	2026-09-29 21:03:49.73885+05:30	Mr. Sundar C	Assistant Professor (Sl. Gr.)	t	\N	\N	0	\N
92	25mx102@psgtech.ac.in	$2a$10$fYOhObKCrtrCsGQa/V4UqO7OhB7C4cQX2lb3B0FeW3ccyWnUkVA8G	STUDENT	ACTIVE	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-23 19:56:52.556423+05:30	BALASUBRAMANIAM S	25MX102	f	\N	\N	0	\N
186	25mx338@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	POORANI R	25MX338	t	\N	\N	0	\N
194	25mx347@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SIVAPRADEESH M	25MX347	t	\N	\N	0	\N
195	25mx348@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SOBAN S S	25MX348	t	\N	\N	0	\N
196	25mx349@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SOWMIYA	25MX349	t	\N	\N	0	\N
197	25mx350@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SRIVIKASHNI S	25MX350	t	\N	\N	0	\N
198	25mx351@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	SURIYA G V	25MX351	t	\N	\N	0	\N
199	25mx352@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	TAMILINI S	25MX352	t	\N	\N	0	\N
200	25mx353@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	THRISHA R	25MX353	t	\N	\N	0	\N
201	25mx354@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	TINO BRITTY J	25MX354	t	\N	\N	0	\N
202	25mx355@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VAISHALI S	25MX355	t	\N	\N	0	\N
203	25mx356@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VIGNESH M	25MX356	t	\N	\N	0	\N
204	25mx357@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VIJAYA SREE K	25MX357	t	\N	\N	0	\N
205	25mx358@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VIKRAM SETHUPATHY S	25MX358	t	\N	\N	0	\N
206	25mx359@psgtech.ac.in	$2a$10$htdtCpRhaMgUkO7LKcP/cOsuvmEWwRbZFkUz2csu/16.GvvGjgMzq	STUDENT	PENDING	1	t	2026-10-13 08:23:46.105327+05:30	2026-10-13 08:23:46.105327+05:30	VISHNUVARDANI K S	25MX359	t	\N	\N	0	\N
\.


--
-- Name: ai_analyses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ai_analyses_id_seq', 76, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 71, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departments_id_seq', 12, true);


--
-- Name: keywords_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.keywords_id_seq', 1, false);


--
-- Name: project_embeddings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_embeddings_id_seq', 77, true);


--
-- Name: project_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_files_id_seq', 77, true);


--
-- Name: project_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_members_id_seq', 41, true);


--
-- Name: project_workflow_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_workflow_history_id_seq', 123, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_id_seq', 40, true);


--
-- Name: student_roster_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_roster_id_seq', 140, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 210, true);


--
-- Name: ai_analyses ai_analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_analyses
    ADD CONSTRAINT ai_analyses_pkey PRIMARY KEY (id);


--
-- Name: ai_analyses ai_analyses_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_analyses
    ADD CONSTRAINT ai_analyses_project_id_key UNIQUE (project_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: departments departments_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_code_key UNIQUE (code);


--
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: keywords keywords_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keywords_name_key UNIQUE (name);


--
-- Name: keywords keywords_normalized_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keywords_normalized_name_key UNIQUE (normalized_name);


--
-- Name: keywords keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (id);


--
-- Name: project_embeddings project_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_embeddings
    ADD CONSTRAINT project_embeddings_pkey PRIMARY KEY (id);


--
-- Name: project_embeddings project_embeddings_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_embeddings
    ADD CONSTRAINT project_embeddings_project_id_key UNIQUE (project_id);


--
-- Name: project_files project_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_files
    ADD CONSTRAINT project_files_pkey PRIMARY KEY (id);


--
-- Name: project_keywords project_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_keywords
    ADD CONSTRAINT project_keywords_pkey PRIMARY KEY (project_id, keyword_id);


--
-- Name: project_members project_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_pkey PRIMARY KEY (id);


--
-- Name: project_workflow_history project_workflow_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_workflow_history
    ADD CONSTRAINT project_workflow_history_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: student_roster student_roster_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_roster
    ADD CONSTRAINT student_roster_email_key UNIQUE (email);


--
-- Name: student_roster student_roster_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_roster
    ADD CONSTRAINT student_roster_pkey PRIMARY KEY (id);


--
-- Name: student_roster student_roster_roll_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_roster
    ADD CONSTRAINT student_roster_roll_no_key UNIQUE (roll_no);


--
-- Name: project_members uk_project_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT uk_project_user UNIQUE (project_id, user_id);


--
-- Name: project_members ukaydweb1re2g5786xaugww4u0; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT ukaydweb1re2g5786xaugww4u0 UNIQUE (project_id, user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_ai_analyses_domain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_analyses_domain ON public.ai_analyses USING btree (domain);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- Name: idx_audit_logs_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_keywords_normalized; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_keywords_normalized ON public.keywords USING btree (normalized_name);


--
-- Name: idx_project_files_project; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_files_project ON public.project_files USING btree (project_id);


--
-- Name: idx_project_members_project; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_project ON public.project_members USING btree (project_id);


--
-- Name: idx_project_members_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_user ON public.project_members USING btree (user_id);


--
-- Name: idx_projects_academic_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_academic_year ON public.projects USING btree (academic_year);


--
-- Name: idx_projects_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_created_by ON public.projects USING btree (created_by_user_id);


--
-- Name: idx_projects_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_department ON public.projects USING btree (department_id);


--
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- Name: idx_projects_visibility; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_visibility ON public.projects USING btree (visibility);


--
-- Name: idx_users_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_department ON public.users USING btree (department_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: ai_analyses ai_analyses_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_analyses
    ADD CONSTRAINT ai_analyses_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: projects fk43oit3mvtakehc5mh2nkwr00b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk43oit3mvtakehc5mh2nkwr00b FOREIGN KEY (guide_faculty_id) REFERENCES public.users(id);


--
-- Name: project_workflow_history fka18cpvsptg1ctyloaavo54lfn; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_workflow_history
    ADD CONSTRAINT fka18cpvsptg1ctyloaavo54lfn FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: project_workflow_history fkhrvq376f5a1u8nmqvlblus5s3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_workflow_history
    ADD CONSTRAINT fkhrvq376f5a1u8nmqvlblus5s3 FOREIGN KEY (changed_by_user_id) REFERENCES public.users(id);


--
-- Name: project_embeddings project_embeddings_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_embeddings
    ADD CONSTRAINT project_embeddings_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_files project_files_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_files
    ADD CONSTRAINT project_files_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_files project_files_uploaded_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_files
    ADD CONSTRAINT project_files_uploaded_by_user_id_fkey FOREIGN KEY (uploaded_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: project_keywords project_keywords_keyword_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_keywords
    ADD CONSTRAINT project_keywords_keyword_id_fkey FOREIGN KEY (keyword_id) REFERENCES public.keywords(id) ON DELETE CASCADE;


--
-- Name: project_keywords project_keywords_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_keywords
    ADD CONSTRAINT project_keywords_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_members project_members_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_members project_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: projects projects_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: projects projects_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE;


--
-- Name: student_roster student_roster_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_roster
    ADD CONSTRAINT student_roster_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: users users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict seUJljC3L2gpDOkBlaafa3VeaKBrbDA8hiK4zk49Ld6Aj5cOvxXKIXUWqvQawwz

