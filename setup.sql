
-- 1. Create docs table if it doesn't exist
create table if not exists public.docs (
  path text primary key,
  data jsonb not null,
  updated_at timestamptz default now()
);

-- 2. Enable Row Level Security
alter table public.docs enable row level security;

-- 3. Remove existing policies before recreating them
drop policy if exists "staff can read" on public.docs;
drop policy if exists "admin can insert" on public.docs;
drop policy if exists "admin can update" on public.docs;
drop policy if exists "admin can delete" on public.docs;

-- 4. Create security policies
create policy "staff can read"
on public.docs
for select
to authenticated
using (
  (auth.jwt()->'app_metadata'->>'role') in ('admin','monitor')
);

create policy "admin can insert"
on public.docs
for insert
to authenticated
with check (
  (auth.jwt()->'app_metadata'->>'role') = 'admin'
);

create policy "admin can update"
on public.docs
for update
to authenticated
using (
  (auth.jwt()->'app_metadata'->>'role') = 'admin'
)
with check (
  (auth.jwt()->'app_metadata'->>'role') = 'admin'
);

create policy "admin can delete"
on public.docs
for delete
to authenticated
using (
  (auth.jwt()->'app_metadata'->>'role') = 'admin'
);

-- 5. Add docs to Supabase Realtime if not already added
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'docs'
  ) then
    alter publication supabase_realtime add table public.docs;
  end if;
end $$;

-- 6. Assign user roles

update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) ||
  '{"role":"admin"}'::jsonb
where email = 'michaelomariakowuah@gmail.com';

update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) ||
  '{"role":"admin"}'::jsonb
where email = 'maryoagyeman347@gmail.com';

update auth.users
set raw_app_meta_data =
  coalesce(raw_app_meta_data, '{}'::jsonb) ||
  '{"role":"monitor"}'::jsonb
where email = 'headteacher@yourschool.edu.gh';
