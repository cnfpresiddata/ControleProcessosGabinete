-- Migração do banco inteiro: separou sispad, jogo_confea e caged. Guardada aqui como registro da mudança no sispad.
do $$
declare s text;
begin
  foreach s in array array['sispad','jogo_confea','caged'] loop
    execute format('revoke execute on function %I.registrar() from public, anon, authenticated', s);
    execute format('revoke execute on function %I.nome_usuario() from public, anon, authenticated', s);
    execute format('revoke execute on function %I.tem_papel(text[]) from public, anon', s);
  end loop;
end $$;
