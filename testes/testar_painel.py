"""Teste da tela com Supabase simulado: nada é gravado no banco.

Uso: python testar_painel.py <index.html> <processos.json da cópia de segurança> <pasta das imagens>

1. Dá datas de exemplo a 80% dos processos (semente fixa) só na memória do teste.
2. Confere sobreposição, rolagem e corte em 9 tamanhos de tela, em todas as telas, no painel e no modal.
3. Confere o fluxo Concluir, as travas de data futura e os números do painel por um segundo caminho (Python).
"""
import sys, json, asyncio, os, re, random, datetime as dt
from pathlib import Path
from playwright.async_api import async_playwright

PAGINA, PROC, OUT = Path(sys.argv[1]).resolve(), sys.argv[2], sys.argv[3]
os.makedirs(OUT, exist_ok=True)
AQUI = Path(__file__).parent
CHECK = re.search(r'CHECK = """(.*?)"""', (AQUI / 'testar_tela.py').read_text(encoding='utf-8'), re.S).group(1)
CHECK_PN = """() => {
  const prob = [], vis = el => { const s = getComputedStyle(el), r = el.getBoundingClientRect(); return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 0 && r.height > 0 && !el.closest('[hidden]'); };
  for (const el of document.querySelectorAll('.pn-k b, .pn-k > span > span, .pn-cab h3')) if (vis(el) && el.scrollWidth > el.clientWidth + 1) prob.push('truncado: ' + el.textContent);
  for (const cx of document.querySelectorAll('.pn-cx')){ if (!vis(cx)) continue; const b = cx.getBoundingClientRect();
    for (const el of cx.querySelectorAll('.pn-lin, .pn-nav .bt, .pn-leg, svg text')){ if (!vis(el)) continue; const r = el.getBoundingClientRect(); if (r.bottom > b.bottom + 1 || r.right > b.right + 1 || r.left < b.left - 1) prob.push('fora do quadro: ' + (el.textContent || el.className.baseVal || '').trim().slice(0, 25)); }
    const g = cx.querySelector('.pn-graf'); if (g && g.clientHeight < 60) prob.push('gráfico baixo demais: ' + g.clientHeight + 'px'); }
  const tp = document.querySelector('.topo'); if (tp){ const tb = tp.getBoundingClientRect(); for (const el of tp.children){ if (!vis(el) || el.classList.contains('sinc')) continue; const r = el.getBoundingClientRect(); if (r.right > tb.right + 1 || r.left < tb.left - 1) prob.push('topo cortado: ' + (el.textContent || el.className).trim().slice(0, 20)); } }
  const txt = [...document.querySelectorAll('#pn-gE svg text')].map(t => t.getBoundingClientRect()).filter(r => r.width);
  for (let i = 0; i < txt.length; i++) for (let j = i + 1; j < txt.length; j++){ const a = txt[i], b = txt[j]; if (a.right > b.left + 1 && b.right > a.left + 1 && a.bottom > b.top + 1 && b.bottom > a.top + 1) prob.push('rótulos sobrepostos no eixo'); }
  const m = document.querySelector('.modal'); if (m){ const mb = m.getBoundingClientRect();
    if (mb.bottom > innerHeight + 1 || mb.right > innerWidth + 1 || mb.left < -1 || mb.top < -1) prob.push('modal fora da tela');
    const ul = m.querySelector('.itens').getBoundingClientRect();
    for (const el of m.querySelectorAll('.item, .pager .bt, .modal-topo h2, #md-x')){ if (!vis(el)) continue; const r = el.getBoundingClientRect(); if (r.bottom > mb.bottom + 1 || r.right > mb.right + 1) prob.push('cortado no modal: ' + el.textContent.trim().slice(0, 25)); if (el.classList.contains('item') && r.bottom > ul.bottom + 1) prob.push('item do modal cortado'); } }
  return [...new Set(prob)];
}"""
TAMS = [(320,568),(360,640),(390,844),(568,320),(768,1024),(1024,768),(1366,768),(1920,1080),(2560,1440)]

HOJE = dt.datetime.now(dt.timezone(dt.timedelta(hours=-3))).date()
def dados():
    proc = json.load(open(PROC, encoding='utf-8'))
    rnd = random.Random(7)
    for i, r in enumerate(proc):
        r['prazo_modo'] = 'manual'; r['data_conclusao'] = None
        if i % 5 == 0: continue
        rec = HOJE - dt.timedelta(days=rnd.randint(0, 540))
        r['data_recebimento'] = rec.isoformat()
        r['prazo_resposta'] = (rec + dt.timedelta(days=rnd.randint(10, 60))).isoformat()
        if rnd.random() < 0.65:
            c = rec + dt.timedelta(days=rnd.randint(1, 90))
            if c <= HOJE: r['data_conclusao'] = c.isoformat(); r['situacao'] = 'Respondido'
    return proc

def esperado(proc):
    """Segundo caminho: os números do painel calculados em Python, sem o código da página."""
    rec = [r for r in proc if r.get('data_recebimento')]
    con = [r for r in proc if r.get('data_conclusao')]
    dias = [(dt.date.fromisoformat(r['data_conclusao']) - dt.date.fromisoformat(r['data_recebimento'])).days for r in con if r.get('data_recebimento')]
    aberto = [r for r in rec if not r.get('data_conclusao') and r.get('situacao') not in ('Respondido', 'Arquivado')]
    cp = [r for r in con if r.get('prazo_resposta')]
    no = [r for r in cp if r['data_conclusao'] <= r['prazo_resposta']]
    mes = HOJE.isoformat()[:7]
    return {'rec': len(rec), 'con': len(con), 'abe': len(aberto), 'media': round(sum(dias) / len(dias), 1),
            'pct': round(100 * len(no) / len(cp), 1), 'rec_mes': sum(1 for r in rec if r['data_recebimento'][:7] == mes),
            'tcu': [r for r in con if r['orgao_demandante'] == 'TCU' and r.get('data_recebimento')]}

async def main():
    proc = dados(); esp = esperado(proc)
    feriados = [{'data': f'{a}-{d}', 'nome': 'Feriado'} for a in (2025, 2026, 2027) for d in ('01-01', '04-21', '05-01', '09-07', '10-12', '11-02', '11-15', '11-20', '12-25')]
    sim = (AQUI / 'supabase_simulado.js').read_text(encoding='utf-8')
    corpo = 'window.__DADOS__ = ' + json.dumps({'processos': proc, 'feriados': feriados, 'regras_prazo': [], 'eventos': []}, ensure_ascii=False) + ';\n' + sim
    res, func, erros = {}, [], []
    def ok(cond, txt): func.append(('OK ' if cond else 'FALHOU ') + txt)
    async with async_playwright() as pw:
        br = await pw.chromium.launch(channel='chrome')
        ctx = await br.new_context(viewport={'width':1366,'height':768}, locale='pt-BR', timezone_id='America/Sao_Paulo')
        await ctx.route('**/@supabase/supabase-js**', lambda rt: rt.fulfill(status=200, content_type='application/javascript', body=corpo))
        pg = await ctx.new_page()
        pg.on('pageerror', lambda e: erros.append(str(e)))
        pg.on('dialog', lambda d: asyncio.ensure_future(d.dismiss()))
        await pg.goto(PAGINA.as_uri())
        await pg.fill('input[name=usuario]', 'bruno'); await pg.fill('input[name=senha]', 'simulado')
        await pg.click('button[type=submit]'); await pg.wait_for_selector('#kpis .kpi', timeout=20000); await pg.wait_for_timeout(800)

        # ---------- números do painel por dois caminhos ----------
        await pg.evaluate("irPara('painel')"); await pg.wait_for_timeout(400)
        k = await pg.evaluate("Object.fromEntries([...document.querySelectorAll('.pn-k')].map(b => [b.dataset.k, b.querySelector('b').textContent]))")
        n = lambda s: float(s.replace('.', '').replace(',', '.').replace(' dias', '').replace('%', ''))
        ok(n(k['rec']) == esp['rec'], f"recebidos {k['rec']} = {esp['rec']}")
        ok(n(k['con']) == esp['con'], f"concluídos {k['con']} = {esp['con']}")
        ok(n(k['abe']) == esp['abe'], f"em aberto {k['abe']} = {esp['abe']}")
        ok(abs(n(k['med']) - esp['media']) < 0.051, f"tempo médio {k['med']} = {esp['media']}")
        ok(abs(n(k['pra']) - esp['pct']) < 0.051, f"no prazo {k['pra']} = {esp['pct']}%")
        await pg.click('.pn-k[data-k=rec]'); await pg.wait_for_timeout(200)
        tx = await pg.text_content('#md-p span')
        ok(tx.endswith(f"de {esp['rec']:,} processos".replace(',', '.')), f"modal dos recebidos: {tx}")
        await pg.keyboard.press('Escape'); ok(await pg.locator('#modal').count() == 0, 'Esc fecha o modal')
        # barra do mês atual: a última barra azul visível
        alvo = pg.locator('#pn-gE rect.alvo[data-s=rec]').last
        await alvo.hover(); await pg.wait_for_timeout(150)
        ok(await pg.locator('.pn-tip:not([hidden])').count() == 1, 'dica aparece ao passar o mouse na barra')
        await alvo.click(); await pg.wait_for_timeout(200)
        tit = await pg.text_content('#md-t'); tx = await pg.text_content('#md-p span')
        ok(tx.endswith(f"de {esp['rec_mes']} processo" + ('' if esp['rec_mes'] == 1 else 's')), f"barra do mês atual: {tit} / {tx} (esperado {esp['rec_mes']})")
        await pg.click('#md-x')
        # filtro TCU + clique na linha do órgão
        await pg.select_option('#pn-orgao', 'TCU'); await pg.wait_for_timeout(300)
        await pg.click('.pn-org .pn-lin'); await pg.wait_for_timeout(200)
        tx = await pg.text_content('#md-p span')
        ok(tx.endswith(f"de {len(esp['tcu'])} processos"), f"linha TCU no modal: {tx} (esperado {len(esp['tcu'])})")
        await pg.click('#md-l .item'); await pg.wait_for_timeout(300)
        ok((await pg.text_content('#d-voltar')).strip() == '‹ Painel', 'processo aberto do modal mostra ‹ Painel')
        await pg.click('#d-voltar'); await pg.wait_for_timeout(300)
        ok(await pg.locator('#modal').count() == 1 and await pg.evaluate("E.vista") == 'painel', '‹ Painel volta ao painel com o modal aberto')
        await pg.click('#md-x'); await pg.evaluate("E.pn = PN_PADRAO(); renderPrincipal()")
        for esc_ in ('semana', 'ano', 'mes'):
            await pg.select_option('#pn-escala', esc_); await pg.wait_for_timeout(200)
            ok(await pg.locator('#pn-gE rect.alvo').count() > 0, f'gráfico por {esc_} desenhado')

        # ---------- concluir e travas de data ----------
        pid = await pg.evaluate("E.dados.find(r => r.data_recebimento && !r.data_conclusao && !r.situacao).id")
        await pg.evaluate(f"irPara('detalhe', {pid})"); await pg.wait_for_timeout(300)
        amanha = (HOJE + dt.timedelta(days=1)).isoformat()
        await pg.fill('#acomp [name=data_recebimento]', amanha); await pg.click('#d-salvar'); await pg.wait_for_timeout(200)
        ok('futuro' in await pg.text_content('#d-msg'), 'recebimento no futuro recusado: ' + await pg.text_content('#d-msg'))
        await pg.click('#d-desfazer'); await pg.wait_for_timeout(150)
        await pg.click('#d-concluir'); await pg.wait_for_timeout(350)
        ok(await pg.input_value('#acomp [name=data_conclusao]') == HOJE.isoformat(), 'Concluir propõe a data de hoje')
        ok((await pg.text_content('#d-concluir')).strip() == 'Confirmar conclusão', 'botão vira Confirmar conclusão')
        await pg.fill('#acomp [name=data_conclusao]', amanha); await pg.click('#d-concluir'); await pg.wait_for_timeout(200)
        ok('futuro' in await pg.text_content('#d-msg'), 'conclusão no futuro recusada')
        rec = await pg.evaluate(f"E.porId.get({pid}).data_recebimento")
        antes = (dt.date.fromisoformat(rec) - dt.timedelta(days=1)).isoformat()
        await pg.fill('#acomp [name=data_conclusao]', antes); await pg.click('#d-concluir'); await pg.wait_for_timeout(200)
        ok('antes da data de recebimento' in await pg.text_content('#d-msg'), 'conclusão antes do recebimento recusada')
        ontem = max(rec, (HOJE - dt.timedelta(days=1)).isoformat())
        await pg.fill('#acomp [name=data_conclusao]', ontem); await pg.click('#d-concluir'); await pg.wait_for_timeout(300)
        g = await pg.evaluate("window.__GRAVACOES__.slice(-1)[0]")
        ok(g and g['corpo'].get('data_conclusao') == ontem and g['corpo'].get('situacao') == 'Respondido', f'conclusão gravada: {g}')
        ok('Concluído em' in await pg.text_content('.vista-topo .selo'), 'selo mostra Concluído em')
        # prazo individual: mostra do dia tal ao dia tal
        pid2 = await pg.evaluate("E.dados.find(r => !r.data_recebimento).id")
        await pg.evaluate(f"irPara('detalhe', {pid2})"); await pg.wait_for_timeout(300)
        await pg.fill('#acomp [name=data_recebimento]', '2026-11-13'); await pg.fill('#acomp [name=prazo_resposta]', '2026-11-30'); await pg.wait_for_timeout(100)
        ok(await pg.text_content('#d-regra') == 'De 13/11/2026 a 30/11/2026: 17 dias corridos.', 'prazo: ' + await pg.text_content('#d-regra'))
        await pg.click('#d-concluir'); await pg.wait_for_timeout(300)
        await pg.click('#d-concluir'); await pg.wait_for_timeout(300)
        g = await pg.evaluate("window.__GRAVACOES__.slice(-1)[0]")
        ok(g['corpo'].get('data_recebimento') == '2026-11-13' and g['corpo'].get('prazo_resposta') == '2026-11-30' and g['corpo'].get('data_conclusao') == HOJE.isoformat(), f'concluir salva também as datas digitadas: {g}')
        # situação final escolhida sem data de conclusão pede a data
        pid3 = await pg.evaluate("E.dados.find(r => r.data_recebimento && !r.data_conclusao && !r.situacao).id")
        await pg.evaluate(f"irPara('detalhe', {pid3})"); await pg.wait_for_timeout(300)
        await pg.select_option('#acomp [name=situacao]', 'Arquivado'); await pg.click('#d-salvar'); await pg.wait_for_timeout(300)
        ok(await pg.input_value('#acomp [name=data_conclusao]') == HOJE.isoformat() and (await pg.text_content('#d-concluir')).strip() == 'Confirmar conclusão', 'Arquivado sem data pede a data de conclusão')
        await pg.click('#d-ncancelar'); await pg.wait_for_timeout(200)
        await pg.evaluate("E.sujo=false; irPara('lista')")

        # ---------- telas em 9 tamanhos ----------
        for w, h in TAMS:
            await pg.set_viewport_size({'width': w, 'height': h}); await pg.wait_for_timeout(250)
            async def vista(nome, acao=None, extra=True):
                if acao: await acao()
                await pg.wait_for_timeout(300)
                pr = await pg.evaluate(CHECK) + (await pg.evaluate(CHECK_PN) if extra else [])
                res[f'{w}x{h} {nome}'] = pr
                await pg.screenshot(path=os.path.join(OUT, f'{w}x{h}-{nome}.png'))
            await vista('lista', lambda: pg.evaluate("irPara('lista')"))
            await vista('detalhe', lambda: pg.evaluate("irPara('detalhe', E.dados.filter(r=>r.data_recebimento && !r.data_conclusao && r.assunto).sort((x,y)=>y.assunto.length-x.assunto.length)[0].id)"))
            if w < 860: await vista('detalhe-acomp', lambda: pg.click('.aba[data-a=acomp]'))
            else: await pg.evaluate("E.aba='acomp'")
            await vista('detalhe-concluir', lambda: pg.click('#d-concluir'))
            await pg.evaluate("E.sujo=false; E.concluindo=null")
            await vista('painel', lambda: pg.evaluate("E.pn = PN_PADRAO(); irPara('painel')"))
            if w < 860:
                for a in ('orgao', 'tipo'): await vista('painel-' + a, lambda a=a: pg.click(f'.aba[data-a={a}]'))
                await vista('painel-filtros', lambda: pg.click('#pn-abrir'))
                await pg.evaluate("E.pn.filtros=false; E.pn.aba='evolucao'; renderPrincipal()")
            await vista('painel-semana', lambda: pg.evaluate("E.pn.escala='semana'; E.pn.pagE=null; renderPrincipal()"))
            await pg.evaluate("E.pn.escala='mes'; renderPrincipal()")
            await vista('painel-vazio', lambda: pg.evaluate("E.pn.orgao='__nada__'; renderPrincipal()"))
            await pg.evaluate("E.pn.orgao=''; renderPrincipal()")
            await vista('painel-modal', lambda: pg.click('.pn-k[data-k=med]'))
            await vista('painel-modal-ajuda', lambda: pg.click('#md-aj'))
            await pg.evaluate("fecharModal()")
            await vista('ajuda-painel', lambda: pg.evaluate("abrirAjuda('painel')"))
            await vista('ajuda-acompanhamento', lambda: pg.evaluate("abrirAjuda('acompanhamento')"))
            await vista('prazos', lambda: pg.evaluate("fecharAjuda(); irPara('prazos')"))
            for tp in ['pagina','kpis','filtros','lista','dados','historico','novo','regras','feriados','conta']:
                await vista('ajuda-' + tp, lambda tp=tp: pg.evaluate(f"abrirAjuda('{tp}')"), False)
            await pg.evaluate("fecharAjuda()")
            await vista('historico', lambda: pg.evaluate("irPara('historico')"), False)
            await vista('novo', lambda: pg.evaluate("E.form=null; irPara('novo')"), False)
            await vista('conta', lambda: pg.evaluate("irPara('conta')"), False)
            if w < 860: await vista('filtros', lambda: pg.evaluate("irPara('filtros')"), False)
            await pg.evaluate("irPara('lista')")
        await br.close()
    ruins = {k: v for k, v in res.items() if v}
    print('\n'.join(func))
    print(json.dumps(ruins, ensure_ascii=False, indent=1))
    print('telas testadas', len(res), 'com problema', len(ruins), '| conferências', len(func), 'falhas', sum(1 for f in func if f.startswith('FALHOU')), '| erros js', erros)

asyncio.run(main())
