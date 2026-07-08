-- =============================================
-- Migracao: Sincroniza email/nome do perfil a cada login
-- Execute no SQL Editor do Supabase
--
-- ensure_profile() so preenchia email/nome na criacao do perfil.
-- Perfis criados antes do login via Authentik estar 100% ajustado
-- (ex.: durante os testes, quando o email ainda vinha vazio do
-- provider) ficaram com email/nome em branco para sempre. Agora a
-- funcao atualiza o email a cada login (usando o auth.users ou,
-- se ainda nao sincronizado, os claims brutos do OIDC) e preenche
-- o nome automaticamente se ainda estiver vazio.
-- =============================================

create or replace function ensure_profile()
returns json
language plpgsql
security definer
as $$
declare
  _profile user_profiles%rowtype;
  _email text;
  _nome text;
  _role text;
  _has_admin boolean;
begin
  select coalesce(u.email, u.raw_user_meta_data->>'email'),
         coalesce(u.raw_user_meta_data->>'name', u.raw_user_meta_data->>'given_name')
    into _email, _nome
    from auth.users u where u.id = auth.uid();

  select * into _profile from user_profiles where user_id = auth.uid();
  if found then
    update user_profiles
      set email = coalesce(nullif(_email, ''), email),
          nome = coalesce(nome, nullif(_nome, ''))
      where user_id = auth.uid()
      returning * into _profile;
    return row_to_json(_profile);
  end if;

  select exists(select 1 from user_profiles where perfil = 'administrador') into _has_admin;
  if _has_admin then
    _role := 'operador_auxiliar';
  else
    _role := 'administrador';
  end if;

  insert into user_profiles (user_id, email, nome, perfil)
  values (auth.uid(), _email, _nome, _role)
  returning * into _profile;

  return row_to_json(_profile);
end;
$$;
