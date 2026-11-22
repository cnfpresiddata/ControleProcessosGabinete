alter function public.rls_auto_enable() set search_path = pg_catalog;
create index if not exists answers_question_id_idx on jogo_confea.answers (question_id);
create index if not exists player_badges_badge_id_idx on jogo_confea.player_badges (badge_id);
drop index if exists sispad.processos_prazo_idx;
