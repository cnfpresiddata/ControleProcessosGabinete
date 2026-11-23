/* Supabase simulado para testes de tela: nada sai do navegador.
   O teste injeta window.__DADOS__ = { processos, feriados, regras_prazo, eventos } antes deste script. */
(function(){
  const D = window.__DADOS__ || {};
  const T = { processos: D.processos || [], feriados: D.feriados || [], regras_prazo: D.regras_prazo || [], historico: D.eventos || [] };
  let sessao = null, proxId = 1e6;
  window.__GRAVACOES__ = [];
  function consulta(tab){
    const q = { filtros: [], ordem: [], ini: 0, fim: null, lim: null, acao: 'select', corpo: null };
    const api = {
      select(){ return api; }, order(c, o){ q.ordem.push([c, !(o && o.ascending === false)]); return api; },
      range(a, b){ q.ini = a; q.fim = b; return api; }, limit(n){ q.lim = n; return api; },
      eq(c, v){ q.filtros.push([c, v]); return api; },
      update(m){ q.acao = 'update'; q.corpo = m; return api; }, insert(m){ q.acao = 'insert'; q.corpo = m; return api; },
      delete(){ q.acao = 'delete'; return api; },
      then(ok, erro){ return Promise.resolve(executar()).then(ok, erro); },
    };
    function executar(){
      const t = T[tab] || (T[tab] = []);
      const casa = r => q.filtros.every(([c, v]) => String(r[c]) === String(v));
      if (q.acao === 'update'){ const alvo = t.filter(casa); alvo.forEach(r => { Object.assign(r, q.corpo); r.atualizado_em = new Date().toISOString(); }); window.__GRAVACOES__.push({ tab, acao:'update', corpo:q.corpo, n:alvo.length }); return { data: alvo.map(r => ({ ...r })), error: null }; }
      if (q.acao === 'insert'){ const r = { id: proxId++, prazo_modo:'manual', atualizado_em: new Date().toISOString(), ...q.corpo }; t.push(r); window.__GRAVACOES__.push({ tab, acao:'insert', corpo:q.corpo }); return { data: [{ ...r }], error: null }; }
      if (q.acao === 'delete'){ const n = t.length; T[tab] = t.filter(r => !casa(r)); return { data: null, error: null, n: n - T[tab].length }; }
      let l = t.filter(casa);
      for (const [c, asc] of q.ordem.slice().reverse()) l = l.slice().sort((a, b) => (a[c] ?? '') < (b[c] ?? '') ? (asc ? -1 : 1) : (a[c] ?? '') > (b[c] ?? '') ? (asc ? 1 : -1) : 0);
      if (q.fim !== null) l = l.slice(q.ini, q.fim + 1);
      if (q.lim !== null) l = l.slice(0, q.lim);
      return { data: l.map(r => ({ ...r })), error: null };
    }
    return api;
  }
  const canal = { on(){ return canal; }, subscribe(cb){ setTimeout(() => cb('SUBSCRIBED'), 50); return canal; } };
  window.supabase = { createClient(){ return {
    from: consulta,
    rpc(nome){ if (nome === 'meu_perfil') return Promise.resolve({ data: sessao ? [{ nome:'Bruno', usuario:'bruno', papel:'admin' }] : [], error: null }); return Promise.resolve({ data: null, error: null }); },
    channel(){ return canal; }, removeChannel(){},
    auth: {
      getSession(){ return Promise.resolve({ data: { session: sessao } }); },
      signInWithPassword(){ sessao = { user: { id: 'teste' } }; return Promise.resolve({ error: null }); },
      signOut(){ sessao = null; return Promise.resolve({ error: null }); },
      onAuthStateChange(){}, updateUser(){ return Promise.resolve({ error: null }); },
    },
  }; } };
})();
