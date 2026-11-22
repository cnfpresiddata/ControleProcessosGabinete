import sys, json, asyncio, subprocess, time, os
from playwright.async_api import async_playwright
SITE = sys.argv[1]; SENHAS = json.load(open(sys.argv[2])); OUT = sys.argv[3]
TAMS = [(320,568),(360,640),(390,844),(568,320),(768,1024),(1024,768),(1366,768),(1920,1080),(2560,1440)]
CHECK = """() => {
  const de = document.documentElement, prob = [];
  if (de.scrollHeight > innerHeight + 1) prob.push('rolagem vertical ' + de.scrollHeight + '>' + innerHeight);
  if (de.scrollWidth > innerWidth + 1) prob.push('rolagem horizontal ' + de.scrollWidth + '>' + innerWidth);
  const vis = el => { const s = getComputedStyle(el); const r = el.getBoundingClientRect(); return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 0 && r.height > 0 && !el.closest('[hidden]'); };
  const blocos = [...document.querySelectorAll('#app > *')].filter(vis);
  for (let i = 0; i < blocos.length; i++) for (let j = i + 1; j < blocos.length; j++){
    const a = blocos[i].getBoundingClientRect(), b = blocos[j].getBoundingClientRect();
    if (a.bottom > b.top + 1 && b.bottom > a.top + 1 && a.right > b.left + 1 && b.right > a.left + 1) prob.push('sobreposição ' + blocos[i].className + ' x ' + blocos[j].className);
  }
  const p = document.querySelector('#principal');
  if (p){ const pr = p.getBoundingClientRect();
    for (const el of p.querySelectorAll('button,input,select,textarea,.selo,.card,tr,.evento,label,h2,dd')){
      if (!vis(el)) continue; const r = el.getBoundingClientRect();
      if (r.bottom > pr.bottom + 1 || r.right > pr.right + 1 || r.left < pr.left - 1) { prob.push('cortado: ' + el.tagName + '.' + el.className + ' "' + (el.textContent||'').trim().slice(0,30) + '" ' + Math.round(r.bottom) + '/' + Math.round(pr.bottom)); if (prob.length > 12) break; }
    }
  }
  const c = document.querySelector('.corpo'); if (c){ const cb = c.getBoundingClientRect().bottom; for (const el of c.querySelectorAll('tr,.card')) { const r = el.getBoundingClientRect(); if (r.bottom > cb + 1) prob.push('linha cortada ' + Math.round(r.bottom) + '/' + Math.round(cb)); } }
  for (const el of document.querySelectorAll('.vista-corpo .linhas > *, .eventos > *, .itens > *, .aj-itens > *')) { if (!vis(el)) continue; const box = el.parentElement.getBoundingClientRect(), r = el.getBoundingClientRect(); if (r.bottom > box.bottom + 1) prob.push('campo cortado: ' + (el.textContent||'').trim().slice(0,25)); }
  for (const el of document.querySelectorAll('.kpi span, .kpi b')) { if (!vis(el)) continue; if (el.scrollWidth > el.clientWidth + 1 && el.children.length === 0) prob.push('kpi truncado: ' + el.textContent); }
  for (const el of document.querySelectorAll('.kpi,.topo .bt,.topo h1')) { if (!vis(el)) continue; const r = el.getBoundingClientRect(); if (r.right > innerWidth + 1) prob.push('fora da tela: ' + el.className); }
  return prob;
}"""
async def main():
    async with async_playwright() as pw:
        br = await pw.chromium.launch(channel='chrome')
        ctx = await br.new_context(viewport={'width':1366,'height':768}, locale='pt-BR', timezone_id='America/Sao_Paulo')
        pg = await ctx.new_page()
        erros = []
        pg.on('pageerror', lambda e: erros.append(str(e)))
        pg.on('dialog', lambda d: asyncio.ensure_future(d.dismiss()))
        await pg.goto(SITE)
        await pg.fill('input[name=usuario]', 'bruno'); await pg.fill('input[name=senha]', SENHAS['bruno'])
        await pg.click('button[type=submit]'); await pg.wait_for_selector('#kpis .kpi', timeout=20000)
        await pg.wait_for_timeout(1500)
        res = {}
        for w, h in TAMS:
            await pg.set_viewport_size({'width':w, 'height':h}); await pg.wait_for_timeout(250)
            async def vista(nome, acao=None):
                if acao: await acao()
                await pg.wait_for_timeout(300)
                pr = await pg.evaluate(CHECK)
                res[f'{w}x{h} {nome}'] = pr
                await pg.screenshot(path=os.path.join(OUT, f'{w}x{h}-{nome}.png'))
            await pg.evaluate("irPara('lista')"); await vista('lista')
            await vista('detalhe', lambda: pg.evaluate("irPara('detalhe', E.dados.find(r=>r.assunto && r.assunto.length>800).id)"))
            await vista('detalhe-assunto', lambda: pg.evaluate("E.soAssunto=true; renderPrincipal()"))
            res[f'{w}x{h} assunto inteiro'] = await pg.evaluate("(()=>{const b=document.querySelector('.assunto-box');return b.scrollHeight>b.clientHeight+1?['assunto não coube']:[]})()")
            if w < 860:
                await vista('detalhe-acomp', lambda: pg.click('.aba[data-a=acomp]'))
                await vista('detalhe-hist', lambda: pg.click('.aba[data-a=hist]'))
                await vista('filtros', lambda: pg.evaluate("irPara('filtros')"))
            await vista('prazos', lambda: pg.evaluate("irPara('prazos')"))
            await vista('prazos-nova-regra', lambda: pg.click('#z-nova'))
            await vista('prazos-regra-corridos', lambda: pg.evaluate("E.fRegra.contagem='corridos'; E.formPag=0; renderPrincipal()"))
            await pg.evaluate("irPara('prazos')")
            if w < 860: await pg.click('.aba[data-a=feriados]')
            await vista('prazos-feriados', None)
            await vista('prazos-novo-feriado', lambda: pg.click('#z-novof'))
            await pg.evaluate("irPara('lista')")
            for tp in ['pagina','kpis','filtros','lista','dados','acompanhamento','historico','novo','regras','feriados','conta']:
                await vista('ajuda-' + tp, lambda tp=tp: pg.evaluate(f"abrirAjuda('{tp}')"))
            await pg.evaluate("fecharAjuda(); irPara('lista')"); await pg.wait_for_timeout(200)
            await vista('ajuda-kpi-card', lambda: pg.click('.kpi-c:nth-child(2) .ajuda-bt'))
            await pg.evaluate("fecharAjuda()")
            await vista('historico', lambda: pg.evaluate("irPara('historico')"))
            await vista('novo', lambda: pg.evaluate("E.form=null; irPara('novo')"))
            await vista('conta', lambda: pg.evaluate("irPara('conta')"))
        print(json.dumps({k: v for k, v in res.items() if v}, ensure_ascii=False, indent=1))
        print('telas testadas', len(res), 'com problema', sum(1 for v in res.values() if v), 'erros js', erros)
        await br.close()
asyncio.run(main())
