-- Regras de prazo por órgão e tipo, feriados e cálculo automático do prazo para resposta

create table sispad.feriados (
  data date primary key,
  nome text not null check (length(nome) between 2 and 120),
  rotulo_feriado text
);
create or replace function sispad.rotular_feriado() returns trigger language plpgsql set search_path = '' as $$
begin new.rotulo_feriado := to_char(new.data, 'DD/MM/YYYY') || ' ' || new.nome; return new; end $$;
create trigger rotular before insert or update on sispad.feriados for each row execute function sispad.rotular_feriado();

create table sispad.regras_prazo (
  id bigint generated always as identity primary key,
  orgao_demandante text,
  tipo_procedimento text,
  dias integer not null check (dias between 1 and 3650),
  contagem text not null check (contagem in ('corridos','uteis')),
  prorrogar boolean not null default true,
  rotulo_regra text generated always as (coalesce(orgao_demandante, 'Qualquer órgão') || ' / ' || coalesce(tipo_procedimento, 'qualquer tipo')) stored,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid default auth.uid(),
  unique nulls not distinct (orgao_demandante, tipo_procedimento)
);
comment on table sispad.regras_prazo is 'Prazo padrão para resposta. A regra mais específica vale: órgão e tipo, depois só tipo, depois só órgão, depois a regra geral.';

alter table sispad.processos
  add column prazo_modo text not null default 'regra' check (prazo_modo in ('regra','manual')),
  add column regra_id bigint references sispad.regras_prazo(id) on delete set null;
create index processos_regra_idx on sispad.processos (regra_id);

-- Dia útil: segunda a sexta e fora da tabela de feriados
create or replace function sispad.dia_util(p date) returns boolean
language sql stable set search_path = '' as $$
  select extract(isodow from p) < 6 and not exists (select 1 from sispad.feriados f where f.data = p);
$$;

-- Conta a partir do dia seguinte ao recebimento (Lei 9.784/1999, art. 66)
create or replace function sispad.somar_prazo(p_inicio date, p_dias integer, p_contagem text, p_prorrogar boolean)
returns date language plpgsql stable set search_path = '' as $$
declare v date := p_inicio; n integer := 0;
begin
  if p_inicio is null or p_dias is null then return null; end if;
  if p_contagem = 'uteis' then
    while n < p_dias loop
      v := v + 1;
      if sispad.dia_util(v) then n := n + 1; end if;
    end loop;
  else
    v := p_inicio + p_dias;
    if p_prorrogar then
      while not sispad.dia_util(v) loop v := v + 1; end loop;
    end if;
  end if;
  return v;
end $$;

create or replace function sispad.regra_para(p_orgao text, p_tipo text) returns bigint
language sql stable set search_path = '' as $$
  select r.id from sispad.regras_prazo r
  where (r.orgao_demandante is null or r.orgao_demandante = p_orgao)
    and (r.tipo_procedimento is null or r.tipo_procedimento = p_tipo)
  order by (r.orgao_demandante is not null and r.tipo_procedimento is not null) desc,
           (r.tipo_procedimento is not null) desc,
           (r.orgao_demandante is not null) desc
  limit 1;
$$;

create or replace function sispad.calcular_prazo() returns trigger
language plpgsql set search_path = '' as $$
declare r sispad.regras_prazo;
begin
  if new.prazo_modo = 'regra' then
    new.regra_id := sispad.regra_para(new.orgao_demandante, new.tipo_procedimento);
    select * into r from sispad.regras_prazo where id = new.regra_id;
    new.prazo_resposta := case when r.id is null then null
      else sispad.somar_prazo(new.data_recebimento, r.dias, r.contagem, r.prorrogar) end;
  else
    new.regra_id := null;
  end if;
  return new;
end $$;
create trigger calcular_prazo before insert or update on sispad.processos
  for each row execute function sispad.calcular_prazo();

-- Recalcula os processos que seguem regra quando muda uma regra ou um feriado
create or replace function sispad.recalcular_prazos() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_n integer; v_nome text;
begin
  perform set_config('auditoria.silenciar', 'sim', true);
  with alvo as (
    select p.id from sispad.processos p
    left join sispad.regras_prazo r on r.id = sispad.regra_para(p.orgao_demandante, p.tipo_procedimento)
    where p.prazo_modo = 'regra'
      and (p.regra_id is distinct from r.id
           or p.prazo_resposta is distinct from case when r.id is null then null
                else sispad.somar_prazo(p.data_recebimento, r.dias, r.contagem, r.prorrogar) end)
  )
  update sispad.processos p set prazo_modo = 'regra' from alvo where p.id = alvo.id;
  get diagnostics v_n = row_count;
  perform set_config('auditoria.silenciar', '', true);
  if v_n > 0 then
    v_nome := acesso.nome_usuario('sispad');
    insert into auditoria.eventos (projeto, user_id, usuario, acao, tabela, descricao)
    values ('sispad', (select auth.uid()), v_nome, 'alterou', 'processos',
      format('Prazo para resposta recalculado em %s processo%s pela mudança nas regras de prazo ou nos feriados.', v_n, case when v_n = 1 then '' else 's' end));
  end if;
  return null;
end $$;
create trigger recalcular after insert or update or delete on sispad.regras_prazo
  for each statement execute function sispad.recalcular_prazos();
create trigger recalcular after insert or update or delete on sispad.feriados
  for each statement execute function sispad.recalcular_prazos();

create or replace function sispad.carimbar_regra() returns trigger language plpgsql set search_path = '' as $$
begin new.atualizado_em := now(); new.atualizado_por := (select auth.uid()); return new; end $$;
create trigger carimbar before insert or update on sispad.regras_prazo for each row execute function sispad.carimbar_regra();

-- Log: silêncio durante o recálculo em lote; colunas técnicas fora da frase
do $$
declare d text;
begin
  d := pg_get_functiondef('auditoria.registrar()'::regprocedure);
  d := replace(d, $a$  if tg_argv[2] = 'so_login' and (select auth.uid()) is null then$a$,
                  $a$  if current_setting('auditoria.silenciar', true) = 'sim' then
    return coalesce(new, old);
  end if;
  if tg_argv[2] = 'so_login' and (select auth.uid()) is null then$a$);
  d := replace(d, $a$continue when v_k in ('atualizado_em','atualizado_por','updated_at');$a$,
                  $a$continue when v_k in ('atualizado_em','atualizado_por','updated_at','regra_id') or v_k like 'rotulo\_%';$a$);
  if d not like '%auditoria.silenciar%' or d not like '%regra_id%' then raise exception 'auditoria.registrar não foi alterada'; end if;
  execute d;
end $$;

create trigger log_regras after insert or update or delete on sispad.regras_prazo
  for each row execute function auditoria.registrar('sispad', 'rotulo_regra', 'so_login', 'a regra de prazo');
create trigger log_feriados after insert or update or delete on sispad.feriados
  for each row execute function auditoria.registrar('sispad', 'rotulo_feriado', 'so_login', 'o feriado');

insert into auditoria.rotulos values
 ('sispad','processos','prazo_modo','Forma do prazo'),
 ('sispad','regras_prazo','orgao_demandante','Órgão'),
 ('sispad','regras_prazo','tipo_procedimento','Tipo de procedimento'),
 ('sispad','regras_prazo','dias','Dias'),
 ('sispad','regras_prazo','contagem','Contagem'),
 ('sispad','regras_prazo','prorrogar','Prorrogar para o próximo dia útil'),
 ('sispad','feriados','nome','Nome'),
 ('sispad','feriados','data','Data');

alter table sispad.regras_prazo enable row level security;
alter table sispad.feriados enable row level security;
create policy le on sispad.regras_prazo for select to authenticated using (acesso.tem_papel('sispad'));
create policy cria on sispad.regras_prazo for insert to authenticated with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy altera on sispad.regras_prazo for update to authenticated using (acesso.tem_papel('sispad', array['admin','editor'])) with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy exclui on sispad.regras_prazo for delete to authenticated using (acesso.tem_papel('sispad', array['admin','editor']));
create policy le on sispad.feriados for select to authenticated using (acesso.tem_papel('sispad'));
create policy cria on sispad.feriados for insert to authenticated with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy altera on sispad.feriados for update to authenticated using (acesso.tem_papel('sispad', array['admin','editor'])) with check (acesso.tem_papel('sispad', array['admin','editor']));
create policy exclui on sispad.feriados for delete to authenticated using (acesso.tem_papel('sispad', array['admin','editor']));

grant select, insert, update, delete on sispad.regras_prazo, sispad.feriados to authenticated;
grant all on sispad.regras_prazo, sispad.feriados to service_role;
revoke execute on function sispad.recalcular_prazos() from public, anon, authenticated;

alter publication supabase_realtime add table sispad.regras_prazo, sispad.feriados;

-- Feriados nacionais 2025 a 2030 (Lei 662/1949, Lei 6.802/1980, Lei 14.759/2023; Paixão de Cristo pela data da Páscoa)
insert into sispad.feriados (data, nome) values
('2025-01-01','Confraternização Universal'),
('2025-04-18','Paixão de Cristo'),
('2025-04-21','Tiradentes'),
('2025-05-01','Dia do Trabalho'),
('2025-09-07','Independência do Brasil'),
('2025-10-12','Nossa Senhora Aparecida'),
('2025-11-02','Finados'),
('2025-11-15','Proclamação da República'),
('2025-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2025-12-25','Natal'),
('2026-01-01','Confraternização Universal'),
('2026-04-03','Paixão de Cristo'),
('2026-04-21','Tiradentes'),
('2026-05-01','Dia do Trabalho'),
('2026-09-07','Independência do Brasil'),
('2026-10-12','Nossa Senhora Aparecida'),
('2026-11-02','Finados'),
('2026-11-15','Proclamação da República'),
('2026-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2026-12-25','Natal'),
('2027-01-01','Confraternização Universal'),
('2027-03-26','Paixão de Cristo'),
('2027-04-21','Tiradentes'),
('2027-05-01','Dia do Trabalho'),
('2027-09-07','Independência do Brasil'),
('2027-10-12','Nossa Senhora Aparecida'),
('2027-11-02','Finados'),
('2027-11-15','Proclamação da República'),
('2027-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2027-12-25','Natal'),
('2028-01-01','Confraternização Universal'),
('2028-04-14','Paixão de Cristo'),
('2028-04-21','Tiradentes'),
('2028-05-01','Dia do Trabalho'),
('2028-09-07','Independência do Brasil'),
('2028-10-12','Nossa Senhora Aparecida'),
('2028-11-02','Finados'),
('2028-11-15','Proclamação da República'),
('2028-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2028-12-25','Natal'),
('2029-01-01','Confraternização Universal'),
('2029-03-30','Paixão de Cristo'),
('2029-04-21','Tiradentes'),
('2029-05-01','Dia do Trabalho'),
('2029-09-07','Independência do Brasil'),
('2029-10-12','Nossa Senhora Aparecida'),
('2029-11-02','Finados'),
('2029-11-15','Proclamação da República'),
('2029-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2029-12-25','Natal'),
('2030-01-01','Confraternização Universal'),
('2030-04-19','Paixão de Cristo'),
('2030-04-21','Tiradentes'),
('2030-05-01','Dia do Trabalho'),
('2030-09-07','Independência do Brasil'),
('2030-10-12','Nossa Senhora Aparecida'),
('2030-11-02','Finados'),
('2030-11-15','Proclamação da República'),
('2030-11-20','Dia Nacional de Zumbi e da Consciência Negra'),
('2030-12-25','Natal');
