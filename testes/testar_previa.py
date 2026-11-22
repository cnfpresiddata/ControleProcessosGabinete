import sys, json, asyncio
from playwright.async_api import async_playwright
S = json.load(open(sys.argv[1])); SITE = sys.argv[2]
async def main():
    async with async_playwright() as pw:
        br = await pw.chromium.launch(channel='chrome'); pg = await br.new_page(viewport={'width':1366,'height':768})
        erros = []; pg.on('pageerror', lambda e: erros.append(str(e)))
        await pg.goto(SITE); await pg.fill('input[name=usuario]','bruno'); await pg.fill('input[name=senha]',S['bruno']); await pg.click('button[type=submit]'); await pg.wait_for_selector('.vivo.on')
        # regras só na memória da página (nada é gravado)
        await pg.evaluate("E.regras=[{id:-1,orgao_demandante:null,tipo_procedimento:null,dias:10,contagem:'corridos',prorrogar:true},{id:-2,orgao_demandante:'TCU',tipo_procedimento:'DENÚNCIA',dias:5,contagem:'uteis',prorrogar:true}]")
        for org, tipo in [('MPF', None), ('TCU', 'DENÚNCIA'), ('TCU', 'REPRESENTAÇÃO')]:
            pid = await pg.evaluate(f"E.dados.find(r=>r.orgao_demandante==={json.dumps(org)} && r.tipo_procedimento==={json.dumps(tipo)}).id")
            await pg.evaluate(f"irPara('detalhe', {pid})"); await pg.wait_for_timeout(300)
            await pg.fill('#acomp input[name=data_recebimento]', '2026-11-13'); await pg.wait_for_timeout(150)
            print(org, tipo, '->', await pg.input_value('#acomp input[name=prazo_resposta]'), '|', await pg.text_content('#d-regra'))
        await pg.select_option('#acomp select[name=prazo_modo]', 'manual'); await pg.wait_for_timeout(150)
        print('manual: campo habilitado =', await pg.is_enabled('#acomp input[name=prazo_resposta]'), '|', await pg.text_content('#d-regra'))
        await pg.evaluate("E.sujo=false; irPara('prazos')"); await pg.wait_for_timeout(300)
        print('cobertura:', (await pg.text_content('.painel.regras .cobertura')).strip())
        print('itens de regra:', await pg.evaluate("[...document.querySelectorAll('#z-regras .item')].map(li=>li.innerText.replace(/\n/g,' | '))"))
        print('erros js', erros); await br.close()
asyncio.run(main())
