-- Prazo individual por processo (informado pelo órgão demandante) e data de conclusão
-- Só acrescenta: nenhuma coluna sai, nenhum dado gravado se perde.

-- 1. Data de conclusão
alter table sispad.processos add column data_conclusao date;
create index processos_conclusao_idx on sispad.processos (data_conclusao);
create index processos_recebimento_idx on sispad.processos (data_recebimento);
insert into sispad.rotulos (tabela, coluna, rotulo) values ('processos','data_conclusao','Data de conclusão')
  on conflict do nothing;

-- 2. Prazo individual passa a ser o padrão. A regra por órgão e tipo continua disponível.
alter table sispad.processos alter column prazo_modo set default 'manual';
-- Os 673 processos de 17/11/2026 não têm prazo nem regra: a troca não muda nenhum prazo.
-- Gatilhos de carimbo e log desligados só nesta troca, para manter quem alterou e quando.
alter table sispad.processos disable trigger carimbar;
alter table sispad.processos disable trigger log_processos;
update sispad.processos set prazo_modo = 'manual' where prazo_modo = 'regra' and prazo_resposta is null;
alter table sispad.processos enable trigger carimbar;
alter table sispad.processos enable trigger log_processos;
insert into sispad.eventos (user_id, usuario, acao, tabela, descricao)
values (null, 'Sistema', 'alterou', 'processos',
  'Prazo para resposta passou a ser informado em cada processo, conforme o órgão demandante. Nenhum prazo gravado mudou.');

-- 3. Datas coerentes: nada no futuro, conclusão e prazo depois do recebimento.
--    Só confere o campo que mudou, para não travar registros antigos.
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
  if new.prazo_modo = 'manual' and new.prazo_resposta < new.data_recebimento
     and (new.prazo_resposta is distinct from (case when tg_op = 'UPDATE' then old.prazo_resposta end)
          or new.data_recebimento is distinct from (case when tg_op = 'UPDATE' then old.data_recebimento end)) then
    raise exception 'O prazo para resposta não pode ser antes da data de recebimento.' using errcode = '22008';
  end if;
  return new;
end $$;
create trigger conferir_datas before insert or update on sispad.processos
  for each row execute function sispad.conferir_datas();
revoke execute on function sispad.conferir_datas() from public, anon, authenticated;
