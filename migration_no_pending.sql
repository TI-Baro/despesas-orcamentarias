-- =============================================
-- Migracao: Remove aprovacao manual de novos usuarios
-- Execute no SQL Editor do Supabase
--
-- O acesso agora ja e controlado pelo Authentik (so quem tem
-- permissao na Application consegue logar), entao novos usuarios
-- nao precisam mais ficar com perfil 'pendente' aguardando um
-- administrador aprovar manualmente. Entram direto como
-- 'operador_auxiliar' (menor privilegio) e podem ser promovidos
-- depois na tela de Configuracoes.
-- =============================================

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
    _role := 'operador_auxiliar';
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

-- Opcional: promove quem ja estiver com perfil 'pendente' hoje
-- update user_profiles set perfil = 'operador_auxiliar' where perfil = 'pendente';
