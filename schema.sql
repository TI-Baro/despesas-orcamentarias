-- =============================================
-- Schema para Controle Orcamentario TI
-- Execute no SQL Editor do Supabase
-- =============================================

-- Tabela de lancamentos do orcamento
create table orcamento_lancamentos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  mes text,
  tipo text,
  responsavel text,
  subgrupo_oxr text,
  grupo_oxr text,
  descricao_conta text,
  grupo_conta text,
  conta_contabil text,
  historico text,
  centro_custo text,
  nome_ccusto text,
  dc text,
  orcado numeric default 0,
  real_valor numeric default 0,
  valor numeric default 0,
  valor_final numeric default 0,
  lote text,
  origem text,
  data text,
  estrutura text,
  provisorio boolean default false,
  created_at timestamptz default now()
);

-- Tabela de linhas de investimento
create table investimento_linhas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  nome text not null,
  descricao text,
  categoria text not null,
  responsavel text not null,
  valor_orcado numeric not null default 0,
  status text not null default 'ativo',
  data_criacao date default current_date,
  data_previsao date,
  observacao text,
  provisorio boolean default false,
  created_at timestamptz default now()
);

-- Tabela de transacoes de investimento
create table investimento_transacoes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  linha_id uuid references investimento_linhas(id) on delete cascade not null,
  descricao text not null,
  valor numeric not null default 0,
  data date not null,
  tipo text not null default 'despesa',
  fornecedor text,
  nota_fiscal text,
  observacao text,
  provisorio boolean default false,
  created_at timestamptz default now()
);

-- Tabela de categorias de investimento
create table investimento_categorias (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  nome text not null,
  created_at timestamptz default now(),
  unique(user_id, nome)
);

-- =============================================
-- Row Level Security (RLS)
-- Cada usuario so ve/edita seus proprios dados
-- =============================================

-- orcamento_lancamentos
alter table orcamento_lancamentos enable row level security;
create policy "Users manage own data" on orcamento_lancamentos
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- investimento_linhas
alter table investimento_linhas enable row level security;
create policy "Users manage own data" on investimento_linhas
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- investimento_transacoes
alter table investimento_transacoes enable row level security;
create policy "Users manage own data" on investimento_transacoes
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- investimento_categorias
alter table investimento_categorias enable row level security;
create policy "Users manage own data" on investimento_categorias
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================
-- Tabela de perfis de usuario
-- =============================================

create table user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null unique,
  email text,
  nome text,
  perfil text not null default 'pendente',
  created_at timestamptz default now()
);

-- Funcao para verificar se o usuario logado eh admin
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

-- Funcao para garantir que o usuario tem perfil (chamada no login)
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

  -- Se nao existe nenhum admin ainda, o usuario vira admin automaticamente
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

-- RLS para user_profiles
alter table user_profiles enable row level security;

create policy "Users read own or admin reads all" on user_profiles
  for select using (auth.uid() = user_id or is_admin());

create policy "Users insert own" on user_profiles
  for insert with check (auth.uid() = user_id);

create policy "Users update own or admin updates all" on user_profiles
  for update using (auth.uid() = user_id or is_admin());

create policy "Admin deletes" on user_profiles
  for delete using (is_admin());

-- =============================================
-- Migracao: tornar usuarios existentes administradores
-- Execute apos criar a tabela user_profiles:
-- INSERT INTO user_profiles (user_id, email, perfil)
-- SELECT id, email, 'administrador' FROM auth.users
-- WHERE id NOT IN (SELECT user_id FROM user_profiles);
-- =============================================

-- =============================================
-- Migracoes: adicionar coluna provisorio
-- Execute se as tabelas ja existem:
-- alter table orcamento_lancamentos add column if not exists provisorio boolean default false;
-- alter table investimento_linhas add column if not exists provisorio boolean default false;
-- alter table investimento_transacoes add column if not exists provisorio boolean default false;
-- =============================================

-- =============================================
-- Migracao: Permissoes Granulares por Perfil
-- Execute migration_roles.sql para:
-- - Adicionar constraint de perfil (administrador/operador/operador_auxiliar/pendente)
-- - Criar funcoes is_active_user() e get_user_role()
-- - Substituir RLS policies por policies granulares
-- =============================================
