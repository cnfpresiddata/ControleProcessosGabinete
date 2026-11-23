-- Só o prazo informado pelo órgão: saem as regras de prazo, os feriados e o cálculo automático.
-- Pedido do Bruno em 23/11/2026 (a Talita informou que cada processo tem o prazo dado pelo órgão).
-- Cópia de segurança antes: processos, regras_prazo (0 linhas), feriados (60 linhas), rotulos e funções.
-- Nenhum processo, data ou prazo muda.

drop trigger if exists calcular_prazo on sispad.processos;
alter table sispad.processos drop column regra_id;
alter table sispad.processos drop column prazo_modo;
drop table sispad.regras_prazo;
drop table sispad.feriados;
drop function sispad.calcular_prazo();
drop function sispad.recalcular_prazos();
drop function sispad.regra_para(text, text);
drop function sispad.somar_prazo(date, integer, text, boolean);
drop function sispad.dia_util(date);
drop function sispad.carimbar_regra();
drop function sispad.rotular_feriado();

delete from sispad.rotulos where tabela in ('regras_prazo','feriados') or (tabela = 'processos' and coluna = 'prazo_modo');

-- Trava de datas sem a forma do prazo
create or replace function sispad.conferir_datas() returns trigger
language plpgsql set search_path = '' as $$
declare hoje date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  if new.data_recebimento is distinct from (case when tg_op = 'UPDATE' then old.data_recebimento end)
     and new.data_recebimento > hoje then
    raise exception 'A data de recebimento não pode ser no futuro.' using errcode = '22008';
  end if;
  if new.data_conclusao is distinct from (case when tg_op = 'UPDATE' then old.data_conclusao end) then
    if new.data_conclusao > hoje then
      raise exception 'A data de conclusão não pode ser no futuro.' using errcode = '22008';
    end if;
    if new.data_conclusao < new.data_recebimento then
      raise exception 'A data de conclusão não pode ser antes da data de recebimento.' using errcode = '22008';
    end if;
  end if;
  if new.prazo_resposta < new.data_recebimento
     and (new.prazo_resposta is distinct from (case when tg_op = 'UPDATE' then old.prazo_resposta end)
          or new.data_recebimento is distinct from (case when tg_op = 'UPDATE' then old.data_recebimento end)) then
    raise exception 'O prazo para resposta não pode ser antes da data de recebimento.' using errcode = '22008';
  end if;
  return new;
end $$;
revoke execute on function sispad.conferir_datas() from public, anon, authenticated;

insert into sispad.eventos (user_id, usuario, acao, tabela, descricao)
values (null, 'Sistema', 'excluiu', 'regras_prazo',
  'Regras de prazo e feriados retirados: o prazo de cada processo é o informado pelo órgão demandante. Nenhum prazo gravado mudou.');
