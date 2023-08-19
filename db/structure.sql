SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: extract_tags_from_blob(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extract_tags_from_blob(blob jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
        select
          array_agg(replace(tags, '_', '/'))
        from (
          select jsonb_array_elements_text(jsonb_array_elements(blob->'ingredients')->'tags') as tags
        ) t;
      $$;


--
-- Name: my_array_replace_each(text[], text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_array_replace_each(arr text[], source_string text, rep_string text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
        SELECT array_agg(replace(item, source_string, rep_string)) FROM unnest(arr) AS item;
      $$;


--
-- Name: my_array_to_string(text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_array_to_string(arr text[], sep text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
          SELECT array_to_string(arr, sep);
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audits (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    info jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audits_id_seq OWNED BY public.audits.id;


--
-- Name: cocktail_families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cocktail_families (
    id bigint NOT NULL,
    name character varying NOT NULL,
    facts jsonb DEFAULT '{}'::jsonb NOT NULL,
    description character varying,
    user_id bigint
);


--
-- Name: cocktail_families_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cocktail_families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cocktail_families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cocktail_families_id_seq OWNED BY public.cocktail_families.id;


--
-- Name: cocktail_family_joiners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cocktail_family_joiners (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    cocktail_family_id bigint NOT NULL,
    user_id bigint
);


--
-- Name: cocktail_family_joiners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cocktail_family_joiners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cocktail_family_joiners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cocktail_family_joiners_id_seq OWNED BY public.cocktail_family_joiners.id;


--
-- Name: reagent_amounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_amounts (
    id bigint NOT NULL,
    recipe_id bigint,
    amount numeric(10,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    unit character varying NOT NULL,
    description text,
    user_id bigint,
    tags character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: reagent_amounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reagent_amounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagent_amounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reagent_amounts_id_seq OWNED BY public.reagent_amounts.id;


--
-- Name: reagent_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagent_categories (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    external_id character varying NOT NULL
);


--
-- Name: reagent_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reagent_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagent_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reagent_categories_id_seq OWNED BY public.reagent_categories.id;


--
-- Name: reagents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reagents (
    id bigint NOT NULL,
    name character varying,
    cost numeric,
    purchase_location character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    user_id bigint,
    max_volume_unit character varying NOT NULL,
    max_volume_value numeric(10,2) NOT NULL,
    current_volume_value numeric(10,2) NOT NULL,
    current_volume_unit character varying NOT NULL,
    external_id character varying NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: reagents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reagents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reagents_id_seq OWNED BY public.reagents.id;


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    category character varying NOT NULL,
    description text,
    extras jsonb,
    user_id bigint,
    parent_id bigint,
    source character varying DEFAULT ''::character varying,
    ingredients_blob jsonb DEFAULT '{}'::jsonb,
    searchable tsvector GENERATED ALWAYS AS (array_to_tsvector(public.extract_tags_from_blob(ingredients_blob))) STORED
);


--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipes_id_seq OWNED BY public.recipes.id;


--
-- Name: reference_bottles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference_bottles (
    id bigint NOT NULL,
    name character varying NOT NULL,
    cost_reference numeric,
    description character varying,
    main_image_url character varying,
    reagent_category_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reference_bottles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reference_bottles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reference_bottles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reference_bottles_id_seq OWNED BY public.reference_bottles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    roles character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits ALTER COLUMN id SET DEFAULT nextval('public.audits_id_seq'::regclass);


--
-- Name: cocktail_families id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_families ALTER COLUMN id SET DEFAULT nextval('public.cocktail_families_id_seq'::regclass);


--
-- Name: cocktail_family_joiners id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_family_joiners ALTER COLUMN id SET DEFAULT nextval('public.cocktail_family_joiners_id_seq'::regclass);


--
-- Name: reagent_amounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_amounts ALTER COLUMN id SET DEFAULT nextval('public.reagent_amounts_id_seq'::regclass);


--
-- Name: reagent_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_categories ALTER COLUMN id SET DEFAULT nextval('public.reagent_categories_id_seq'::regclass);


--
-- Name: reagents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagents ALTER COLUMN id SET DEFAULT nextval('public.reagents_id_seq'::regclass);


--
-- Name: recipes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes ALTER COLUMN id SET DEFAULT nextval('public.recipes_id_seq'::regclass);


--
-- Name: reference_bottles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_bottles ALTER COLUMN id SET DEFAULT nextval('public.reference_bottles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: cocktail_families cocktail_families_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_families
    ADD CONSTRAINT cocktail_families_pkey PRIMARY KEY (id);


--
-- Name: cocktail_family_joiners cocktail_family_joiners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_family_joiners
    ADD CONSTRAINT cocktail_family_joiners_pkey PRIMARY KEY (id);


--
-- Name: reagent_amounts reagent_amounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_amounts
    ADD CONSTRAINT reagent_amounts_pkey PRIMARY KEY (id);


--
-- Name: reagent_categories reagent_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagent_categories
    ADD CONSTRAINT reagent_categories_pkey PRIMARY KEY (id);


--
-- Name: reagents reagents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reagents
    ADD CONSTRAINT reagents_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: reference_bottles reference_bottles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_bottles
    ADD CONSTRAINT reference_bottles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_audits_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_recipe_id ON public.audits USING btree (recipe_id);


--
-- Name: index_audits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_user_id ON public.audits USING btree (user_id);


--
-- Name: index_cocktail_families_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cocktail_families_on_user_id ON public.cocktail_families USING btree (user_id);


--
-- Name: index_cocktail_family_joiners_on_cocktail_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cocktail_family_joiners_on_cocktail_family_id ON public.cocktail_family_joiners USING btree (cocktail_family_id);


--
-- Name: index_cocktail_family_joiners_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cocktail_family_joiners_on_recipe_id ON public.cocktail_family_joiners USING btree (recipe_id);


--
-- Name: index_cocktail_family_joiners_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cocktail_family_joiners_on_user_id ON public.cocktail_family_joiners USING btree (user_id);


--
-- Name: index_reagent_amounts_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reagent_amounts_on_recipe_id ON public.reagent_amounts USING btree (recipe_id);


--
-- Name: index_reagent_amounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reagent_amounts_on_user_id ON public.reagent_amounts USING btree (user_id);


--
-- Name: index_reagent_categories_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reagent_categories_on_external_id ON public.reagent_categories USING btree (external_id);


--
-- Name: index_reagent_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reagent_categories_on_name ON public.reagent_categories USING btree (name);


--
-- Name: index_reagents_on_external_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reagents_on_external_id_and_user_id ON public.reagents USING btree (external_id, user_id);


--
-- Name: index_reagents_on_name_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reagents_on_name_and_user_id ON public.reagents USING btree (name, user_id);


--
-- Name: index_reagents_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reagents_on_user_id ON public.reagents USING btree (user_id);


--
-- Name: index_recipes_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipes_on_parent_id ON public.recipes USING btree (parent_id);


--
-- Name: index_recipes_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipes_on_searchable ON public.recipes USING gin (searchable);


--
-- Name: index_recipes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipes_on_user_id ON public.recipes USING btree (user_id);


--
-- Name: index_reference_bottles_on_reagent_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reference_bottles_on_reagent_category_id ON public.reference_bottles USING btree (reagent_category_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: cocktail_families fk_rails_9bd8f8f980; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_families
    ADD CONSTRAINT fk_rails_9bd8f8f980 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cocktail_family_joiners fk_rails_e00db25b8b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cocktail_family_joiners
    ADD CONSTRAINT fk_rails_e00db25b8b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210922142122'),
('20210922142348'),
('20210922142524'),
('20211126222525'),
('20211229165810'),
('20211229170225'),
('20211230205720'),
('20211230213757'),
('20220113223657'),
('20220117195926'),
('20220403180505'),
('20220409192502'),
('20220515010109'),
('20220603151212'),
('20220603193713'),
('20220920000410'),
('20220922224814'),
('20220922230909'),
('20220923222955'),
('20221221233756'),
('20221223230832'),
('20221227230345'),
('20230117235427'),
('20230305223154'),
('20230308032620'),
('20230314020057'),
('20230314020058'),
('20230314020059'),
('20230328022702'),
('20230530224057'),
('20230530224058'),
('20230601030145'),
('20230804185415'),
('20230808220621'),
('20230819005650');


