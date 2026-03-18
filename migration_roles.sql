-- =============================================
-- Migracao: Sistema de Permissoes Granulares
-- Execute no SQL Editor do Supabase
-- =============================================

-- 1. Constraint de perfil (4 perfis validos)
ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_perfil_check;
ALTER TABLE user_profiles
  ADD CONSTRAINT user_profiles_perfil_check
  CHECK (perfil IN ('administrador', 'operador', 'operador_auxiliar', 'pendente'));

-- 2. Funcao: verificar se usuario eh ativo (nao pendente)
CREATE OR REPLACE FUNCTION is_active_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_id = auth.uid() AND perfil <> 'pendente'
  );
$$;

-- 3. Funcao: retornar perfil do usuario logado
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT perfil FROM user_profiles
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

-- =============================================
-- 4. Novas RLS policies para tabelas de dados
-- Substituem a policy unica "Users manage own data"
-- =============================================

-- Helper: lista de tabelas de dados
-- Aplicar para: orcamento_lancamentos, investimento_linhas,
--               investimento_transacoes, investimento_categorias

-- ── orcamento_lancamentos ───────────────────────
DROP POLICY IF EXISTS "Users manage own data" ON orcamento_lancamentos;

CREATE POLICY "select_orcamento" ON orcamento_lancamentos
  FOR SELECT USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "insert_orcamento" ON orcamento_lancamentos
  FOR INSERT WITH CHECK (
    is_active_user() AND auth.uid() = user_id
  );

CREATE POLICY "update_orcamento" ON orcamento_lancamentos
  FOR UPDATE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "delete_orcamento" ON orcamento_lancamentos
  FOR DELETE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN user_id = auth.uid()
      ELSE false
    END
  );

-- ── investimento_linhas ─────────────────────────
DROP POLICY IF EXISTS "Users manage own data" ON investimento_linhas;

CREATE POLICY "select_inv_linhas" ON investimento_linhas
  FOR SELECT USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "insert_inv_linhas" ON investimento_linhas
  FOR INSERT WITH CHECK (
    is_active_user() AND auth.uid() = user_id
  );

CREATE POLICY "update_inv_linhas" ON investimento_linhas
  FOR UPDATE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "delete_inv_linhas" ON investimento_linhas
  FOR DELETE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN user_id = auth.uid()
      ELSE false
    END
  );

-- ── investimento_transacoes ─────────────────────
DROP POLICY IF EXISTS "Users manage own data" ON investimento_transacoes;

CREATE POLICY "select_inv_trans" ON investimento_transacoes
  FOR SELECT USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "insert_inv_trans" ON investimento_transacoes
  FOR INSERT WITH CHECK (
    is_active_user() AND auth.uid() = user_id
  );

CREATE POLICY "update_inv_trans" ON investimento_transacoes
  FOR UPDATE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "delete_inv_trans" ON investimento_transacoes
  FOR DELETE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN user_id = auth.uid()
      ELSE false
    END
  );

-- ── investimento_categorias ─────────────────────
DROP POLICY IF EXISTS "Users manage own data" ON investimento_categorias;

CREATE POLICY "select_inv_cats" ON investimento_categorias
  FOR SELECT USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "insert_inv_cats" ON investimento_categorias
  FOR INSERT WITH CHECK (
    is_active_user() AND auth.uid() = user_id
  );

CREATE POLICY "update_inv_cats" ON investimento_categorias
  FOR UPDATE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN true
      WHEN 'operador_auxiliar' THEN user_id = auth.uid()
      ELSE false
    END
  );

CREATE POLICY "delete_inv_cats" ON investimento_categorias
  FOR DELETE USING (
    CASE get_user_role()
      WHEN 'administrador' THEN true
      WHEN 'operador' THEN user_id = auth.uid()
      ELSE false
    END
  );

-- =============================================
-- 5. Funcao para admin criar perfil de usuario
-- Usada apos criar o usuario via Auth API
-- =============================================

CREATE OR REPLACE FUNCTION admin_create_profile(p_user_id uuid, p_email text, p_nome text, p_perfil text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _profile user_profiles%rowtype;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem criar perfis';
  END IF;

  INSERT INTO user_profiles (user_id, email, nome, perfil)
  VALUES (p_user_id, p_email, p_nome, p_perfil)
  ON CONFLICT (user_id) DO UPDATE SET
    perfil = EXCLUDED.perfil,
    nome = COALESCE(EXCLUDED.nome, user_profiles.nome)
  RETURNING * INTO _profile;

  RETURN row_to_json(_profile);
END;
$$;
