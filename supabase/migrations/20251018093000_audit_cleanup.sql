-- Consolidate duplicate audit triggers and drop orphaned function
-- Safe & idempotent (uses catalog checks and conditional create).

------------------------------
-- Partners: audit trigger(s)
------------------------------
do $$
begin
  -- Drop any duplicate/legacy names if they exist
  if exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'partners'
      and t.tgname in ('tr_partners_audit_biud','trg_partners_audit_biu','trg_partners_audit_biud')
  ) then
    execute 'drop trigger if exists tr_partners_audit_biud on public.partners';
    execute 'drop trigger if exists trg_partners_audit_biu on public.partners';
    execute 'drop trigger if exists trg_partners_audit_biud on public.partners';
  end if;

  -- Ensure a single canonical trigger exists
  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'partners'
      and t.tgname = 'audit_biu'
  ) then
    execute 'create trigger audit_biu
             before insert or update on public.partners
             for each row execute function public.set_audit_fields()';
  end if;
end
$$;

------------------------------
-- Profiles: audit trigger(s)
------------------------------
do $$
begin
  -- Drop any duplicate/legacy names if they exist
  if exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'profiles'
      and t.tgname in ('tr_profiles_audit_biud','trg_profiles_audit_biud')
  ) then
    execute 'drop trigger if exists tr_profiles_audit_biud on public.profiles';
    execute 'drop trigger if exists trg_profiles_audit_biud on public.profiles';
  end if;

  -- Ensure a single canonical trigger exists
  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'profiles'
      and t.tgname = 'audit_biu'
  ) then
    execute 'create trigger audit_biu
             before insert or update on public.profiles
             for each row execute function public.set_audit_fields()';
  end if;
end
$$;

-----------------------------------------
-- Orphaned helper (not referenced now)
-----------------------------------------
-- Only drop if it exists; safe if absent
drop function if exists public.enforce_org_on_insert_user_roles();
