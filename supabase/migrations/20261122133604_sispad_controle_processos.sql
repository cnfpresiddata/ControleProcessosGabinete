
-- Rótulo com prefixo (TG_ARGV[3]) nas frases do log
create or replace function auditoria.registrar() returns trigger
language plpgsql security definer set search_path = '' as $$
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
  v_reg := trim(v_pref || ' ' || coalesce(v_new ->> v_col, v_old ->> v_col, v_new ->> 'id', v_old ->> 'id', ''));
  if tg_op = 'UPDATE' then
    for v_k in select key from jsonb_each(v_new) loop
      continue when v_k in ('atualizado_em','atualizado_por','updated_at');
      if (v_new -> v_k) is distinct from (v_old -> v_k) then
        select r.rotulo into v_rot from auditoria.rotulos r where r.projeto = v_proj and r.tabela = tg_table_name and r.coluna = v_k;
        v_de := coalesce(nullif(v_old ->> v_k, ''), 'vazio');
        v_para := coalesce(nullif(v_new ->> v_k, ''), 'vazio');
        if v_de ~ '^\d{4}-\d{2}-\d{2}$' then v_de := to_char(v_de::date, 'DD/MM/YYYY'); end if;
        if v_para ~ '^\d{4}-\d{2}-\d{2}$' then v_para := to_char(v_para::date, 'DD/MM/YYYY'); end if;
        v_partes := v_partes || format('%s de "%s" para "%s"', coalesce(v_rot, v_k), left(v_de, 120), left(v_para, 120));
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
end $$;

insert into acesso.projetos (codigo,nome,descricao,paginas) values
 ('sispad','Controle de Processos do Gabinete','Processos de órgãos de controle (TCU, MPF, PF e outros) acompanhados pelo Gabinete da Presidência; base SISPAD',
  array['https://cnfpresiddata.github.io/ControleProcessosGabinete/']);

create schema sispad;

create table sispad.processos (
  id bigint generated always as identity primary key,
  processo_sei text,
  processo_orgao text not null,
  orgao_demandante text not null,
  uf text check (uf ~ '^[A-Z]{2}$'),
  localidade text,
  assunto text,
  situacao_ags text,
  relator text,
  tipo_procedimento text,
  situacao text check (situacao in ('Recebido pelo Gabinete','Encaminhado à unidade responsável','Aguardando assinatura do Ofício','Respondido','Arquivado')),
  prioridade text check (prioridade in ('Crítica','Alta','Normal')),
  data_recebimento date,
  prazo_resposta date,
  observacao text,
  linha_planilha integer,
  origem jsonb,
  criado_em timestamptz not null default now(),
  criado_por uuid default auth.uid(),
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid default auth.uid()
);
comment on column sispad.processos.origem is 'Linha original da planilha CONSULTA_GERAL_SISPAD_2026-11-17.xlsx, sem nenhuma alteração';
create index processos_prazo_idx on sispad.processos (prazo_resposta) where prazo_resposta is not null;

create or replace function sispad.carimbar() returns trigger language plpgsql set search_path = '' as $$
begin
  new.atualizado_em := now();
  new.atualizado_por := (select auth.uid());
  if tg_op = 'INSERT' then new.criado_por := (select auth.uid()); end if;
  return new;
end $$;
create trigger carimbar before insert or update on sispad.processos for each row execute function sispad.carimbar();
create trigger log_processos after insert or update or delete on sispad.processos
  for each row execute function auditoria.registrar('sispad','processo_orgao','so_login','o processo');

insert into auditoria.rotulos values
 ('sispad','processos','processo_sei','Processo SEI'),
 ('sispad','processos','processo_orgao','Processo do órgão de controle'),
 ('sispad','processos','orgao_demandante','Órgão demandante'),
 ('sispad','processos','uf','UF'),
 ('sispad','processos','localidade','Localidade'),
 ('sispad','processos','assunto','Assunto'),
 ('sispad','processos','situacao_ags','Situação histórica (AGS)'),
 ('sispad','processos','relator','Autoridade / Relator'),
 ('sispad','processos','tipo_procedimento','Tipo de procedimento'),
 ('sispad','processos','situacao','Situação do processo'),
 ('sispad','processos','prioridade','Prioridade'),
 ('sispad','processos','data_recebimento','Data de recebimento'),
 ('sispad','processos','prazo_resposta','Prazo para resposta'),
 ('sispad','processos','observacao','Observação');

alter table sispad.processos enable row level security;
create policy le on sispad.processos for select to authenticated using (acesso.tem_papel('sispad'));
create policy cria on sispad.processos for insert to authenticated with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy altera on sispad.processos for update to authenticated using (acesso.tem_papel('sispad', array['admin','editor'])) with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy exclui on sispad.processos for delete to authenticated using (acesso.tem_papel('sispad', array['admin']));

-- Histórico legível do projeto (respeita as regras do usuário)
create view sispad.historico with (security_invoker = true) as
  select id, quando, usuario, acao, registro, descricao, registro_id
  from auditoria.eventos where projeto = 'sispad';

create or replace function sispad.meu_perfil() returns table (nome text, usuario text, papel text)
language sql stable security definer set search_path = '' as $$
  select p.nome, p.usuario, p.papel from acesso.perfis p
  where p.user_id = (select auth.uid()) and p.projeto = 'sispad' and p.ativo;
$$;

create or replace function sispad.registrar_acesso(p_acao text default 'entrou') returns void
language plpgsql security definer set search_path = '' as $$
declare v_nome text;
begin
  if not acesso.tem_papel('sispad') or p_acao not in ('entrou','saiu') then return; end if;
  v_nome := acesso.nome_usuario('sispad');
  insert into auditoria.eventos (projeto, user_id, usuario, acao, descricao)
  values ('sispad', (select auth.uid()), v_nome, p_acao,
          format('%s %s no sistema.', v_nome, case p_acao when 'entrou' then 'entrou' else 'saiu' end));
end $$;

revoke all on all tables in schema sispad from anon;
revoke execute on all functions in schema sispad from anon, public;
grant usage on schema sispad to authenticated, service_role;
grant select, insert, update, delete on sispad.processos to authenticated;
grant select on sispad.historico to authenticated;
grant all on all tables in schema sispad to service_role;
grant execute on function sispad.meu_perfil(), sispad.registrar_acesso(text) to authenticated;

alter publication supabase_realtime add table sispad.processos, auditoria.eventos;
