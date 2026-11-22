
-- 1. Catálogo de projetos, perfis e log central
create schema if not exists acesso;
create schema if not exists auditoria;
create schema if not exists jogo_confea;
create schema if not exists arquivo;
create schema if not exists manutencao;

create table acesso.projetos (
  codigo text primary key,
  nome text not null,
  descricao text,
  paginas text[] not null default '{}',
  criado_em timestamptz not null default now()
);
insert into acesso.projetos (codigo,nome,descricao,paginas) values
 ('jogo_confea','Jogo CONFEA','Quiz do CONFEA: jogo, painel PostIt e administração',
  array['https://cnfpresiddata.github.io/gameCONFEA/','https://cnfpresiddata.github.io/AdmGameCONFEA/','https://cnfpresiddata.github.io/PostitGameCONFEA/']);

create table acesso.perfis (
  user_id uuid not null references auth.users(id) on delete cascade,
  projeto text not null references acesso.projetos(codigo),
  papel text not null check (papel in ('admin','editor','leitor')),
  nome text not null,
  usuario text not null,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  primary key (user_id, projeto)
);
create index perfis_projeto_idx on acesso.perfis (projeto);

create or replace function acesso.tem_papel(p_projeto text, p_papeis text[] default array['admin','editor','leitor'])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from acesso.perfis p
    where p.user_id = (select auth.uid()) and p.projeto = p_projeto and p.ativo and p.papel = any(p_papeis));
$$;

create or replace function acesso.nome_usuario(p_projeto text)
returns text language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select p.nome from acesso.perfis p where p.user_id = (select auth.uid()) and p.projeto = p_projeto),
    (select p.nome from acesso.perfis p where p.user_id = (select auth.uid()) limit 1),
    case when (select auth.uid()) is null then 'Visitante sem login' else 'Usuário sem perfil' end);
$$;

alter table acesso.projetos enable row level security;
alter table acesso.perfis enable row level security;
create policy perfis_le_o_proprio on acesso.perfis for select to authenticated using (user_id = (select auth.uid()));
create policy projetos_le on acesso.projetos for select to authenticated using (true);

-- Rótulos legíveis das colunas, usados nas frases do log
create table auditoria.rotulos (
  projeto text not null, tabela text not null, coluna text not null, rotulo text not null,
  primary key (projeto, tabela, coluna)
);

create table auditoria.eventos (
  id bigint generated always as identity primary key,
  projeto text not null,
  quando timestamptz not null default now(),
  user_id uuid,
  usuario text not null,
  acao text not null check (acao in ('criou','alterou','excluiu','entrou','saiu','importou')),
  tabela text,
  registro_id text,
  registro text,
  descricao text not null,
  antes jsonb,
  depois jsonb
);
create index eventos_projeto_quando_idx on auditoria.eventos (projeto, quando desc);
create index eventos_registro_idx on auditoria.eventos (projeto, tabela, registro_id);
alter table auditoria.eventos enable row level security;
alter table auditoria.rotulos enable row level security;
create policy eventos_le_do_projeto on auditoria.eventos for select to authenticated using (acesso.tem_papel(projeto));
create policy rotulos_le on auditoria.rotulos for select to authenticated using (true);

-- Gatilho genérico: TG_ARGV[0] = projeto, TG_ARGV[1] = coluna que identifica o registro, TG_ARGV[2] = 'so_login' para ignorar ações sem usuário
create or replace function auditoria.registrar() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_proj text := tg_argv[0];
  v_col text := tg_argv[1];
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_reg text;
  v_usuario text;
  v_partes text[] := '{}';
  v_k text;
  v_rot text;
  v_de text; v_para text;
  v_acao text;
  v_desc text;
begin
  if tg_argv[2] = 'so_login' and (select auth.uid()) is null then
    return coalesce(new, old);
  end if;
  v_usuario := acesso.nome_usuario(v_proj);
  v_reg := coalesce(v_new ->> v_col, v_old ->> v_col, v_new ->> 'id', v_old ->> 'id');
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
    v_desc := format('%s alterou %s: %s.', v_usuario, coalesce(v_reg, 'registro'), array_to_string(v_partes, '; '));
  elsif tg_op = 'INSERT' then
    v_acao := 'criou';
    v_desc := format('%s criou %s.', v_usuario, coalesce(v_reg, 'registro'));
  else
    v_acao := 'excluiu';
    v_desc := format('%s excluiu %s.', v_usuario, coalesce(v_reg, 'registro'));
  end if;
  insert into auditoria.eventos (projeto, user_id, usuario, acao, tabela, registro_id, registro, descricao, antes, depois)
  values (v_proj, (select auth.uid()), v_usuario, v_acao, tg_table_name,
          coalesce(v_new ->> 'id', v_old ->> 'id'), v_reg, v_desc, v_old, v_new);
  return coalesce(new, old);
end $$;

-- 2. Jogo CONFEA: tabelas, view e funções vão para o schema próprio (dados, regras, gatilhos e Realtime seguem junto)
alter table public.players set schema jogo_confea;
alter table public.player_phones set schema jogo_confea;
alter table public.player_badges set schema jogo_confea;
alter table public.badges set schema jogo_confea;
alter table public.questions set schema jogo_confea;
alter table public.answers set schema jogo_confea;
alter table public.suggestions set schema jogo_confea;
alter view public.ranking_view set schema jogo_confea;

do $$
declare d text;
begin
  d := pg_get_functiondef('public.submit_answer(uuid,uuid,integer,boolean,integer,integer)'::regprocedure);
  drop function public.submit_answer(uuid,uuid,integer,boolean,integer,integer);
  execute replace(d, 'public.', 'jogo_confea.');
  d := pg_get_functiondef('public.register_or_login_with_phone(text,text,boolean,text)'::regprocedure);
  drop function public.register_or_login_with_phone(text,text,boolean,text);
  execute replace(d, 'public.', 'jogo_confea.');
  d := pg_get_functiondef('public.keepalive_enviar(text,jsonb)'::regprocedure);
  d := replace(d, 'public."keepAlive"', 'manutencao."keepAlive"');
  d := replace(d, 'SET search_path TO ''public''', 'SET search_path TO ''manutencao''');
  execute d;
end $$;
alter function jogo_confea.submit_answer(uuid,uuid,integer,boolean,integer,integer) set search_path = jogo_confea;
alter function jogo_confea.register_or_login_with_phone(text,text,boolean,text) set search_path = jogo_confea;

-- Ações de administração do jogo: só quem tem papel admin no projeto
drop policy admin_delete_players on jogo_confea.players;
create policy admin_delete_players on jogo_confea.players for delete to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));
drop policy admin_delete_questions on jogo_confea.questions;
drop policy admin_insert_questions on jogo_confea.questions;
drop policy admin_update_questions on jogo_confea.questions;
create policy admin_delete_questions on jogo_confea.questions for delete to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));
create policy admin_insert_questions on jogo_confea.questions for insert to authenticated with check (acesso.tem_papel('jogo_confea', array['admin']));
create policy admin_update_questions on jogo_confea.questions for update to authenticated using (acesso.tem_papel('jogo_confea', array['admin'])) with check (acesso.tem_papel('jogo_confea', array['admin']));
drop policy admin_delete_suggestions on jogo_confea.suggestions;
create policy admin_delete_suggestions on jogo_confea.suggestions for delete to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));
drop policy admin_delete_badges on jogo_confea.badges;
drop policy admin_insert_badges on jogo_confea.badges;
drop policy admin_update_badges on jogo_confea.badges;
create policy admin_delete_badges on jogo_confea.badges for delete to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));
create policy admin_insert_badges on jogo_confea.badges for insert to authenticated with check (acesso.tem_papel('jogo_confea', array['admin']));
create policy admin_update_badges on jogo_confea.badges for update to authenticated using (acesso.tem_papel('jogo_confea', array['admin'])) with check (acesso.tem_papel('jogo_confea', array['admin']));
drop policy admin_delete_player_phones on jogo_confea.player_phones;
drop policy admin_read_player_phones on jogo_confea.player_phones;
create policy admin_delete_player_phones on jogo_confea.player_phones for delete to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));
create policy admin_read_player_phones on jogo_confea.player_phones for select to authenticated using (acesso.tem_papel('jogo_confea', array['admin']));

-- Log das ações dos administradores do jogo (a jogada dos participantes não entra)
insert into auditoria.rotulos values
 ('jogo_confea','questions','question','Pergunta'),('jogo_confea','questions','active','Ativa'),
 ('jogo_confea','badges','name','Nome'),('jogo_confea','badges','active','Ativa'),
 ('jogo_confea','players','name','Nome'),('jogo_confea','suggestions','text','Texto');
create trigger log_questions after insert or update or delete on jogo_confea.questions for each row execute function auditoria.registrar('jogo_confea','question','so_login');
create trigger log_badges after insert or update or delete on jogo_confea.badges for each row execute function auditoria.registrar('jogo_confea','name','so_login');
create trigger log_suggestions after delete on jogo_confea.suggestions for each row execute function auditoria.registrar('jogo_confea','id','so_login');
create trigger log_players after delete on jogo_confea.players for each row execute function auditoria.registrar('jogo_confea','name','so_login');
create trigger log_player_phones after delete on jogo_confea.player_phones for each row execute function auditoria.registrar('jogo_confea','player_id','so_login');

grant usage on schema jogo_confea to anon, authenticated, service_role;
grant select, insert, update, delete on all tables in schema jogo_confea to anon, authenticated, service_role;
grant usage, select on all sequences in schema jogo_confea to anon, authenticated, service_role;
grant execute on all functions in schema jogo_confea to anon, authenticated, service_role;

-- 3. Cópias de segurança antigas: guardadas, fora da API
alter table public.answers_backup_20260917 set schema arquivo;
alter table public.players_backup_20260917 set schema arquivo;
alter table public.questions_backup_comparativas set schema arquivo;
revoke all on all tables in schema arquivo from anon, authenticated;

-- 4. Manutenção: tabela do sinal de atividade; a função de entrada continua em public para não quebrar quem a chama
alter table public."keepAlive" set schema manutencao;
revoke all on all tables in schema manutencao from anon, authenticated;

grant usage on schema acesso, auditoria to authenticated, service_role;
grant select on acesso.perfis, acesso.projetos, auditoria.eventos, auditoria.rotulos to authenticated;
grant all on all tables in schema acesso, auditoria to service_role;
grant execute on function acesso.tem_papel(text, text[]), acesso.nome_usuario(text) to anon, authenticated;
