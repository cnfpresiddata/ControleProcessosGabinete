alter table sispad.processos alter column processo_orgao drop not null;
drop trigger log_processos on sispad.processos;
create trigger log_processos after insert or update or delete on sispad.processos
  for each row execute function auditoria.registrar('sispad','processo_orgao','so_login','o processo');
