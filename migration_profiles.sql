create table user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null unique,
  email text,
  nome text,
  perfil text not null default 'pendente',
  created_at timestamptz default now()
);

create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from user_profiles
    where user_id = auth.uid() and perfil = 'administrador'
  );
$$;

create or replace function ensure_profile()
returns json
language plpgsql
security definer
as $$
declare
  _profile user_profiles%rowtype;
  _email text;
  _role text;
  _has_admin boolean;
begin
  select * into _profile from user_profiles where user_id = auth.uid();
  if found then
    return row_to_json(_profile);
  end if;

  select exists(select 1 from user_profiles where perfil = 'administrador') into _has_admin;
  if _has_admin then
    _role := 'pendente';
  else
    _role := 'administrador';
  end if;

  select email into _email from auth.users where id = auth.uid();

  insert into user_profiles (user_id, email, perfil)
  values (auth.uid(), _email, _role)
  returning * into _profile;

  return row_to_json(_profile);
end;
$$;

alter table user_profiles enable row level security;

create policy "Users read own or admin reads all" on user_profiles
  for select using (auth.uid() = user_id or is_admin());

create policy "Users insert own" on user_profiles
  for insert with check (auth.uid() = user_id);

create policy "Users update own or admin updates all" on user_profiles
  for update using (auth.uid() = user_id or is_admin());

create policy "Admin deletes" on user_profiles
  for delete using (is_admin());
