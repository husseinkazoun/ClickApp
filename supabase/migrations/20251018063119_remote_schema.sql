drop trigger if exists "set_project_code_bi" on "public"."projects";

drop policy "tenant_delete_policy" on "public"."projects";

drop policy "tenant_insert_policy" on "public"."projects";

drop policy "tenant_select_policy" on "public"."projects";

drop policy "tenant_update_policy" on "public"."projects";

revoke delete on table "public"."organizations" from "anon";

revoke insert on table "public"."organizations" from "anon";

revoke references on table "public"."organizations" from "anon";

revoke select on table "public"."organizations" from "anon";

revoke trigger on table "public"."organizations" from "anon";

revoke truncate on table "public"."organizations" from "anon";

revoke update on table "public"."organizations" from "anon";

revoke delete on table "public"."organizations" from "authenticated";

revoke insert on table "public"."organizations" from "authenticated";

revoke references on table "public"."organizations" from "authenticated";

revoke select on table "public"."organizations" from "authenticated";

revoke trigger on table "public"."organizations" from "authenticated";

revoke truncate on table "public"."organizations" from "authenticated";

revoke update on table "public"."organizations" from "authenticated";

revoke delete on table "public"."organizations" from "service_role";

revoke insert on table "public"."organizations" from "service_role";

revoke references on table "public"."organizations" from "service_role";

revoke select on table "public"."organizations" from "service_role";

revoke trigger on table "public"."organizations" from "service_role";

revoke truncate on table "public"."organizations" from "service_role";

revoke update on table "public"."organizations" from "service_role";

revoke delete on table "public"."partners" from "anon";

revoke insert on table "public"."partners" from "anon";

revoke references on table "public"."partners" from "anon";

revoke select on table "public"."partners" from "anon";

revoke trigger on table "public"."partners" from "anon";

revoke truncate on table "public"."partners" from "anon";

revoke update on table "public"."partners" from "anon";

revoke delete on table "public"."partners" from "authenticated";

revoke insert on table "public"."partners" from "authenticated";

revoke references on table "public"."partners" from "authenticated";

revoke select on table "public"."partners" from "authenticated";

revoke trigger on table "public"."partners" from "authenticated";

revoke truncate on table "public"."partners" from "authenticated";

revoke update on table "public"."partners" from "authenticated";

revoke delete on table "public"."partners" from "service_role";

revoke insert on table "public"."partners" from "service_role";

revoke references on table "public"."partners" from "service_role";

revoke select on table "public"."partners" from "service_role";

revoke trigger on table "public"."partners" from "service_role";

revoke truncate on table "public"."partners" from "service_role";

revoke update on table "public"."partners" from "service_role";

revoke delete on table "public"."profiles" from "anon";

revoke insert on table "public"."profiles" from "anon";

revoke references on table "public"."profiles" from "anon";

revoke select on table "public"."profiles" from "anon";

revoke trigger on table "public"."profiles" from "anon";

revoke truncate on table "public"."profiles" from "anon";

revoke update on table "public"."profiles" from "anon";

revoke delete on table "public"."profiles" from "authenticated";

revoke insert on table "public"."profiles" from "authenticated";

revoke references on table "public"."profiles" from "authenticated";

revoke select on table "public"."profiles" from "authenticated";

revoke trigger on table "public"."profiles" from "authenticated";

revoke truncate on table "public"."profiles" from "authenticated";

revoke update on table "public"."profiles" from "authenticated";

revoke delete on table "public"."profiles" from "service_role";

revoke insert on table "public"."profiles" from "service_role";

revoke references on table "public"."profiles" from "service_role";

revoke select on table "public"."profiles" from "service_role";

revoke trigger on table "public"."profiles" from "service_role";

revoke truncate on table "public"."profiles" from "service_role";

revoke update on table "public"."profiles" from "service_role";

revoke delete on table "public"."projects" from "anon";

revoke insert on table "public"."projects" from "anon";

revoke references on table "public"."projects" from "anon";

revoke select on table "public"."projects" from "anon";

revoke trigger on table "public"."projects" from "anon";

revoke truncate on table "public"."projects" from "anon";

revoke update on table "public"."projects" from "anon";

revoke delete on table "public"."projects" from "authenticated";

revoke insert on table "public"."projects" from "authenticated";

revoke references on table "public"."projects" from "authenticated";

revoke select on table "public"."projects" from "authenticated";

revoke trigger on table "public"."projects" from "authenticated";

revoke truncate on table "public"."projects" from "authenticated";

revoke update on table "public"."projects" from "authenticated";

revoke delete on table "public"."projects" from "service_role";

revoke insert on table "public"."projects" from "service_role";

revoke references on table "public"."projects" from "service_role";

revoke select on table "public"."projects" from "service_role";

revoke trigger on table "public"."projects" from "service_role";

revoke truncate on table "public"."projects" from "service_role";

revoke update on table "public"."projects" from "service_role";

drop function if exists "public"."generate_project_code"(n integer);

create table "public"."user_roles" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "org_id" uuid not null,
    "role" text not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone,
    "created_by" uuid,
    "updated_by" uuid
);


alter table "public"."user_roles" enable row level security;

alter table "public"."partners" add column "updated_at" timestamp with time zone not null;

alter table "public"."partners" add column "updated_by" uuid not null;

alter table "public"."profiles" add column "created_at" timestamp with time zone default now();

alter table "public"."profiles" add column "created_by" uuid;

alter table "public"."profiles" add column "name" text;

alter table "public"."profiles" add column "updated_at" timestamp with time zone default now();

alter table "public"."profiles" add column "updated_by" uuid;

alter table "public"."projects" add column "project_stage" text default 'draft'::text;

alter table "public"."projects" add column "updated_at" timestamp with time zone;

alter table "public"."projects" add column "updated_by" uuid;

alter table "public"."projects" alter column "code" set default generate_project_code();

CREATE UNIQUE INDEX user_roles_pkey ON public.user_roles USING btree (id);

CREATE UNIQUE INDEX user_roles_user_org_uniq ON public.user_roles USING btree (user_id, org_id);

alter table "public"."user_roles" add constraint "user_roles_pkey" PRIMARY KEY using index "user_roles_pkey";

alter table "public"."user_roles" add constraint "user_roles_user_org_uniq" UNIQUE using index "user_roles_user_org_uniq";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.enforce_org_on_insert_user_roles()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.generate_project_code0(len integer)
 RETURNS text
 LANGUAGE sql
AS $function$
  select upper(substr(replace(gen_random_uuid()::text,'-',''), 1, len));
$function$
;

CREATE OR REPLACE FUNCTION public.get_active_projects()
 RETURNS SETOF projects
 LANGUAGE sql
 STABLE
AS $function$
  select * 
  from public.projects
  where coalesce(project_stage, 'draft') not in ('draft', 'archived');
$function$
;

CREATE OR REPLACE FUNCTION public.set_audit_fields()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.current_organization()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_org_on_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.org_id is null then
    new.org_id := (current_setting('request.jwt.claims', true)::jsonb ->> 'org_id')::uuid;
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_project_code()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.code IS NULL OR length(trim(NEW.code)) = 0 THEN
    NEW.code := public.generate_project_code();
  ELSE
    NEW.code := upper(NEW.code);
  END IF;
  RETURN NEW;
END
$function$
;

CREATE OR REPLACE FUNCTION public.generate_project_code()
 RETURNS text
 LANGUAGE sql
AS $function$
  select encode(gen_random_bytes(6), 'hex')
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE((auth.jwt() ->> 'is_admin')::boolean, false);
$function$
;

create policy "organizations_admin_read_all"
on "public"."organizations"
as permissive
for select
to public
using ((COALESCE(((auth.jwt() ->> 'is_super_admin'::text))::boolean, false) = true));


create policy "organizations_select_member"
on "public"."organizations"
as permissive
for select
to public
using ((EXISTS ( SELECT 1
   FROM user_roles ur
  WHERE ((ur.org_id = organizations.id) AND (ur.user_id = auth.uid())))));


create policy "partners_admin_read_all"
on "public"."partners"
as permissive
for select
to public
using ((COALESCE(((auth.jwt() ->> 'is_super_admin'::text))::boolean, false) = true));


create policy "partners_delete_same_org"
on "public"."partners"
as permissive
for delete
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "partners_insert_same_org"
on "public"."partners"
as permissive
for insert
to public
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "partners_select_same_org"
on "public"."partners"
as permissive
for select
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "partners_update_same_org"
on "public"."partners"
as permissive
for update
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid))
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "profiles_delete_same_org"
on "public"."profiles"
as permissive
for delete
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "profiles_insert_same_org"
on "public"."profiles"
as permissive
for insert
to public
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "profiles_select_same_org"
on "public"."profiles"
as permissive
for select
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "profiles_update_same_org"
on "public"."profiles"
as permissive
for update
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid))
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "projects_delete_same_org"
on "public"."projects"
as permissive
for delete
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "projects_insert_same_org"
on "public"."projects"
as permissive
for insert
to public
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "projects_select_same_org"
on "public"."projects"
as permissive
for select
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "projects_update_same_org"
on "public"."projects"
as permissive
for update
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid))
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "user_roles_delete_same_org"
on "public"."user_roles"
as permissive
for delete
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "user_roles_insert_same_org"
on "public"."user_roles"
as permissive
for insert
to public
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "user_roles_select_same_org"
on "public"."user_roles"
as permissive
for select
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "user_roles_update_same_org"
on "public"."user_roles"
as permissive
for update
to public
using ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid))
with check ((org_id = (((current_setting('request.jwt.claims'::text, true))::jsonb ->> 'org_id'::text))::uuid));


create policy "tenant_delete_policy"
on "public"."projects"
as permissive
for delete
to public
using ((org_id = current_organization()));


create policy "tenant_insert_policy"
on "public"."projects"
as permissive
for insert
to public
with check ((org_id = current_organization()));


create policy "tenant_select_policy"
on "public"."projects"
as permissive
for select
to public
using ((org_id = current_organization()));


create policy "tenant_update_policy"
on "public"."projects"
as permissive
for update
to public
using ((org_id = current_organization()))
with check ((org_id = current_organization()));


CREATE TRIGGER set_org_id_partners_bi BEFORE INSERT ON public.partners FOR EACH ROW EXECUTE FUNCTION enforce_org_on_insert();

CREATE TRIGGER tr_partners_audit_biud BEFORE INSERT OR UPDATE ON public.partners FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_partners_audit_biu BEFORE INSERT OR UPDATE ON public.partners FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_partners_audit_biud BEFORE INSERT OR UPDATE ON public.partners FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER set_org_id_profiles_bi BEFORE INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION enforce_org_on_insert();

CREATE TRIGGER tr_profiles_audit_biud BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_profiles_audit_biud BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER a_set_org_id_projects_bi BEFORE INSERT ON public.projects FOR EACH ROW EXECUTE FUNCTION enforce_org_on_insert();

CREATE TRIGGER tr_projects_audit_biud BEFORE INSERT OR UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_projects_audit_biud BEFORE INSERT OR UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER z_set_project_code_bi BEFORE INSERT ON public.projects FOR EACH ROW EXECUTE FUNCTION ensure_project_code();

CREATE TRIGGER set_org_id_user_roles_bi BEFORE INSERT ON public.user_roles FOR EACH ROW EXECUTE FUNCTION enforce_org_on_insert();

CREATE TRIGGER tr_user_roles_audit_biud BEFORE INSERT OR UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION set_audit_fields();

CREATE TRIGGER trg_user_roles_audit_biud BEFORE INSERT OR UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION set_audit_fields();


