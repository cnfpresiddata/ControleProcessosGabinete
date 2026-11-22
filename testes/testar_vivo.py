import sys, json, asyncio
from playwright.async_api import async_playwright
S = json.load(open(sys.argv[1])); OUT = sys.argv[2]
async def entrar(br, w, h):
    pg = await (await br.new_context(viewport={'width': w, 'height': h}, timezone_id='America/Sao_Paulo')).new_page()
    await pg.goto('http://127.0.0.1:8765/'); await pg.fill('input[name=usuario]', 'bruno'); await pg.fill('input[name=senha]', S['bruno'])
    await pg.click('button[type=submit]'); await pg.wait_for_selector('.vivo.on', timeout=20000); return pg
async def main():
    async with async_playwright() as pw:
        br = await pw.chromium.launch(channel='chrome')
        a = await entrar(br, 1366, 768); b = await entrar(br, 390, 844)
        await a.evaluate("irPara('detalhe', 959)"); await a.wait_for_timeout(400)
        await a.select_option('#acomp select[name=situacao]', 'Aguardando assinatura do Ofício')
        await a.click('#prio button[data-p="Crítica"]')
        await a.fill('#acomp input[name=prazo_resposta]', '2026-11-20')
        await a.click('#d-salvar'); await a.wait_for_timeout(1500)
        print('A msg:', await a.text_content('#d-msg'))
        await b.wait_for_timeout(2500)
        print('B vencidos (ao vivo):', await b.text_content('.kpi.k-venc b'), '| críticos:', await b.text_content('.kpi.k-crit b'))
        await b.screenshot(path=OUT + '/vivo-390.png')
        await a.evaluate("irPara('lista')"); await a.wait_for_timeout(500); await a.screenshot(path=OUT + '/vivo-1366.png')
        await a.evaluate("irPara('historico')"); await a.wait_for_timeout(500); await a.screenshot(path=OUT + '/vivo-historico.png')
        # desfaz pela tela
        await a.evaluate("irPara('detalhe', 959)"); await a.wait_for_timeout(400)
        await a.select_option('#acomp select[name=situacao]', '')
        await a.click('#prio button[data-p="nenhuma"]'); await a.fill('#acomp input[name=prazo_resposta]', '')
        await a.click('#d-salvar'); await a.wait_for_timeout(1500)
        await b.wait_for_timeout(2000)
        print('B vencidos depois de desfazer:', await b.text_content('.kpi.k-venc b'))
        await br.close()
asyncio.run(main())
