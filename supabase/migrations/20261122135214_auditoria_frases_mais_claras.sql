CREATE OR REPLACE FUNCTION auditoria.registrar()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_proj text := tg_argv[0];
  v_col text := tg_argv[1];
  v_pref text := coalesce(tg_argv[3], '');
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_reg text; v_usuario text; v_partes text[] := '{}';
  v_k text; v_rot text; v_de text; v_para text; v_acao text; v_desc text;
begin
  if tg_argv[2] = 'so_login' and (select auth.uid()) is null then
    return coalesce(new, old);
  end if;
  v_usuario := acesso.nome_usuario(v_proj);
  v_reg := trim(v_pref || ' ' || coalesce((select coalesce(v_new ->> c, v_old ->> c) from unnest(string_to_array(v_col, ',')) with ordinality u(c, n) where coalesce(v_new ->> c, v_old ->> c) is not null order by n limit 1), v_new ->> 'id', v_old ->> 'id', ''));
  if tg_op = 'UPDATE' then
    for v_k in select key from jsonb_each(v_new) loop
      continue when v_k in ('atualizado_em','atualizado_por','updated_at');
      if (v_new -> v_k) is distinct from (v_old -> v_k) then
        select r.rotulo into v_rot from auditoria.rotulos r where r.projeto = v_proj and r.tabela = tg_table_name and r.coluna = v_k;
        v_de := coalesce(nullif(v_old ->> v_k, ''), 'vazio');
        v_para := coalesce(nullif(v_new ->> v_k, ''), 'vazio');
        if v_de ~ '^\d{4}-\d{2}-\d{2}$' then v_de := to_char(v_de::date, 'DD/MM/YYYY'); end if;
        if v_para ~ '^\d{4}-\d{2}-\d{2}$' then v_para := to_char(v_para::date, 'DD/MM/YYYY'); end if;
        v_partes := v_partes || case
          when v_de = 'vazio' then format('%s definida como "%s"', coalesce(v_rot, v_k), left(v_para, 120))
          when v_para = 'vazio' then format('%s apagada (era "%s")', coalesce(v_rot, v_k), left(v_de, 120))
          else format('%s mudou de "%s" para "%s"', coalesce(v_rot, v_k), left(v_de, 120), left(v_para, 120)) end;
      end if;
    end loop;
    if cardinality(v_partes) = 0 then return new; end if;
    v_acao := 'alterou';
    v_desc := format('%s alterou %s: %s.', v_usuario, v_reg, array_to_string(v_partes, '; '));
  elsif tg_op = 'INSERT' then
    v_acao := 'criou'; v_desc := format('%s criou %s.', v_usuario, v_reg);
  else
    v_acao := 'excluiu'; v_desc := format('%s excluiu %s.', v_usuario, v_reg);
  end if;
  insert into auditoria.eventos (projeto, user_id, usuario, acao, tabela, registro_id, registro, descricao, antes, depois)
  values (v_proj, (select auth.uid()), v_usuario, v_acao, tg_table_name,
          coalesce(v_new ->> 'id', v_old ->> 'id'), v_reg, v_desc, v_old, v_new);
  return coalesce(new, old);
end $function$
