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
-- Migracao: adicionar coluna provisorio
-- Execute se a tabela orcamento_lancamentos ja existe:
-- alter table orcamento_lancamentos add column if not exists provisorio boolean default false;
-- =============================================
