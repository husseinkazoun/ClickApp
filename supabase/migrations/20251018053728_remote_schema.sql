


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


CREATE SCHEMA IF NOT EXISTS "Partners+Joins";


ALTER SCHEMA "Partners+Joins" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "wrappers" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."current_organization"() RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  js jsonb;
  v  uuid;
BEGIN
  js := NULLIF(current_setting('request.jwt.claims', true), '')::jsonb;

  -- accept both key names
  v := COALESCE(
    NULLIF(js->>'org_id','')::uuid,
    NULLIF(js->>'organization_id','')::uuid
  );

  IF v IS NOT NULL THEN
    RETURN v;
  END IF;

  -- fallback: caller's profile row with a non-null org
  SELECT org_id INTO v
  FROM public.profiles
  WHERE id = auth.uid() AND org_id IS NOT NULL
  LIMIT 1;

  RETURN v;
END
$$;


ALTER FUNCTION "public"."current_organization"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_org_on_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.org_id is null then
    new.org_id := (current_setting('request.jwt.claims', true)::jsonb ->> 'org_id')::uuid;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_org_on_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_org_on_insert_user_roles"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  ctx uuid;
BEGIN
  IF (to_jsonb(NEW)->>'org_id') IS NULL AND (to_jsonb(NEW)->>'organization_id') IS NULL THEN
    ctx := public.current_organization();
    IF ctx IS NULL THEN
      RAISE EXCEPTION 'Missing org context (provide JWT claims org_id or set NEW.org_id/organization_id)'
        USING errcode = 'P0001';
    END IF;

    NEW.org_id := COALESCE(NEW.org_id, ctx);
    NEW.organization_id := COALESCE(NEW.organization_id, ctx);
  END IF;

  RETURN NEW;
END
$$;


ALTER FUNCTION "public"."enforce_org_on_insert_user_roles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ensure_project_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.code IS NULL OR length(trim(NEW.code)) = 0 THEN
    NEW.code := public.generate_project_code();
  ELSE
    NEW.code := upper(NEW.code);
  END IF;
  RETURN NEW;
END
$$;


ALTER FUNCTION "public"."ensure_project_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_project_code"() RETURNS "text"
    LANGUAGE "sql"
    AS $$
  select encode(gen_random_bytes(6), 'hex')
$$;


ALTER FUNCTION "public"."generate_project_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_project_code0"("len" integer) RETURNS "text"
    LANGUAGE "sql"
    AS $$
  select upper(substr(replace(gen_random_uuid()::text,'-',''), 1, len));
$$;


ALTER FUNCTION "public"."generate_project_code0"("len" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE((auth.jwt() ->> 'is_admin')::boolean, false);
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_audit_fields"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  -- timestamps
  if TG_OP = 'INSERT' then
    if new.created_at is null then new.created_at := now(); end if;
  end if;
  new.updated_at := now();

  -- user ids
  if TG_OP = 'INSERT' then
    if new.created_by is null then new.created_by := auth.uid(); end if;
  end if;
  if new.updated_by is null then new.updated_by := auth.uid(); end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."set_audit_fields"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."partners" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid",
    "name" "text" NOT NULL,
    "email" "text",
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "updated_by" "uuid" NOT NULL
);


ALTER TABLE "public"."partners" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "org_id" "uuid",
    "email" "text",
    "full_name" "text",
    "user_id" "uuid",
    "name" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "organization_id" "uuid",
    "code" "text" DEFAULT "public"."generate_project_code"(),
    "updated_at" timestamp with time zone,
    "updated_by" "uuid"
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "org_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partners"
    ADD CONSTRAINT "partners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_org_uniq" UNIQUE ("user_id", "org_id");



CREATE UNIQUE INDEX "idx_projects_org_code_unique" ON "public"."projects" USING "btree" ("org_id", "code");



CREATE INDEX "projects_organization_id_idx" ON "public"."projects" USING "btree" ("organization_id");



CREATE OR REPLACE TRIGGER "a_set_org_id_projects_bi" BEFORE INSERT ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_org_on_insert"();



CREATE OR REPLACE TRIGGER "set_org_id_partners_bi" BEFORE INSERT ON "public"."partners" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_org_on_insert"();



CREATE OR REPLACE TRIGGER "set_org_id_profiles_bi" BEFORE INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_org_on_insert"();



CREATE OR REPLACE TRIGGER "set_org_id_projects_bi" BEFORE INSERT ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_org_on_insert"();



CREATE OR REPLACE TRIGGER "set_org_id_user_roles_bi" BEFORE INSERT ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_org_on_insert"();



CREATE OR REPLACE TRIGGER "tr_partners_audit_biud" BEFORE INSERT OR UPDATE ON "public"."partners" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "tr_profiles_audit_biud" BEFORE INSERT OR UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "tr_projects_audit_biud" BEFORE INSERT OR UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "tr_user_roles_audit_biud" BEFORE INSERT OR UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_partners_audit_biu" BEFORE INSERT OR UPDATE ON "public"."partners" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_partners_audit_biud" BEFORE INSERT OR UPDATE ON "public"."partners" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_profiles_audit_biud" BEFORE INSERT OR UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_projects_audit_biud" BEFORE INSERT OR UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_user_roles_audit_biud" BEFORE INSERT OR UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_fields"();



CREATE OR REPLACE TRIGGER "z_set_project_code_bi" BEFORE INSERT ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."ensure_project_code"();



ALTER TABLE ONLY "public"."partners"
    ADD CONSTRAINT "partners_org_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "organizations_admin_read_all" ON "public"."organizations" FOR SELECT USING ((COALESCE((("auth"."jwt"() ->> 'is_super_admin'::"text"))::boolean, false) = true));



CREATE POLICY "organizations_select_member" ON "public"."organizations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."user_roles" "ur"
  WHERE (("ur"."org_id" = "organizations"."id") AND ("ur"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."partners" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "partners_admin_read_all" ON "public"."partners" FOR SELECT USING ((COALESCE((("auth"."jwt"() ->> 'is_super_admin'::"text"))::boolean, false) = true));



CREATE POLICY "partners_delete_same_org" ON "public"."partners" FOR DELETE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "partners_insert_same_org" ON "public"."partners" FOR INSERT WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "partners_select_same_org" ON "public"."partners" FOR SELECT USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "partners_update_same_org" ON "public"."partners" FOR UPDATE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid")) WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_delete_same_org" ON "public"."profiles" FOR DELETE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "profiles_insert_own" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_insert_same_org" ON "public"."profiles" FOR INSERT WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "profiles_select_own" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_select_same_org" ON "public"."profiles" FOR SELECT USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "profiles_update_same_org" ON "public"."profiles" FOR UPDATE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid")) WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "projects_delete_same_org" ON "public"."projects" FOR DELETE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "projects_insert_same_org" ON "public"."projects" FOR INSERT WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "projects_select_same_org" ON "public"."projects" FOR SELECT USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "projects_update_same_org" ON "public"."projects" FOR UPDATE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid")) WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "tenant_delete_policy" ON "public"."projects" FOR DELETE USING (("org_id" = "public"."current_organization"()));



CREATE POLICY "tenant_insert_policy" ON "public"."projects" FOR INSERT WITH CHECK (("org_id" = "public"."current_organization"()));



CREATE POLICY "tenant_select_policy" ON "public"."projects" FOR SELECT USING (("org_id" = "public"."current_organization"()));



CREATE POLICY "tenant_update_policy" ON "public"."projects" FOR UPDATE USING (("org_id" = "public"."current_organization"())) WITH CHECK (("org_id" = "public"."current_organization"()));



ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_roles_delete_same_org" ON "public"."user_roles" FOR DELETE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "user_roles_insert_same_org" ON "public"."user_roles" FOR INSERT WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "user_roles_select_same_org" ON "public"."user_roles" FOR SELECT USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));



CREATE POLICY "user_roles_update_same_org" ON "public"."user_roles" FOR UPDATE USING (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid")) WITH CHECK (("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
































































































































































































































































































GRANT ALL ON FUNCTION "public"."current_organization"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_organization"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_organization"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_org_on_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_org_on_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_org_on_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_org_on_insert_user_roles"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_org_on_insert_user_roles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_org_on_insert_user_roles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_project_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_project_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_project_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_project_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_project_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_project_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_project_code0"("len" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."generate_project_code0"("len" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_project_code0"("len" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_audit_fields"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_audit_fields"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_audit_fields"() TO "service_role";





















GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."partners" TO "anon";
GRANT ALL ON TABLE "public"."partners" TO "authenticated";
GRANT ALL ON TABLE "public"."partners" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;

