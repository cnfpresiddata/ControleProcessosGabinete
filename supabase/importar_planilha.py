import sys, os, json, datetime
sys.path.insert(0, os.path.dirname(__file__)); from api import sql  # api.py: chamada à API de gestão do Supabase com o token da variável CNF-PRES-DATA
import openpyxl
ARQ = sys.argv[1]  # caminho da planilha CONSULTA_GERAL_SISPAD_2026-11-17.xlsx
ws = openpyxl.load_workbook(ARQ).active
rows = list(ws.iter_rows(values_only=True)); h = rows[0]
ORG = {'PF': 'Polícia Federal'}
def limpo(v):
    if v is None: return None
    if isinstance(v, (datetime.date, datetime.datetime)): return v.strftime('%Y-%m-%d')
    v = str(v).strip()
    return None if v in ('', '-') else v
reg = []
for i, r in enumerate(rows[1:], start=2):
    if not any(v is not None for v in r): continue
    orig = {h[j]: (r[j].isoformat() if hasattr(r[j], 'isoformat') else r[j]) for j in range(len(h))}
    c = [limpo(v) for v in r]
    reg.append({'linha_planilha': i, 'processo_sei': c[0], 'processo_orgao': c[1], 'orgao_demandante': ORG.get(c[2], c[2]),
        'uf': c[3], 'localidade': c[4], 'assunto': c[5], 'situacao_ags': c[6], 'relator': c[7], 'tipo_procedimento': c[8],
        'situacao': c[9], 'prioridade': c[10], 'data_recebimento': c[11], 'prazo_resposta': c[12], 'origem': orig})
ja = sql('select count(*) n from sispad.processos')[0]['n']
if ja: sys.exit(f'Já existem {ja} processos; nada importado.')
payload = json.dumps(reg, ensure_ascii=False).replace("'", "''")
sql(f"""insert into sispad.processos (linha_planilha,processo_sei,processo_orgao,orgao_demandante,uf,localidade,assunto,situacao_ags,relator,tipo_procedimento,situacao,prioridade,data_recebimento,prazo_resposta,origem)
select linha_planilha,processo_sei,processo_orgao,orgao_demandante,uf,localidade,assunto,situacao_ags,relator,tipo_procedimento,situacao,prioridade,data_recebimento,prazo_resposta,origem
from jsonb_to_recordset('{payload}'::jsonb) as x(linha_planilha int,processo_sei text,processo_orgao text,orgao_demandante text,uf text,localidade text,assunto text,situacao_ags text,relator text,tipo_procedimento text,situacao text,prioridade text,data_recebimento date,prazo_resposta date,origem jsonb)""")
n = sql('select count(*) n from sispad.processos')[0]['n']
sql(f"""insert into auditoria.eventos (projeto,usuario,acao,descricao) values ('sispad','Bruno (importação)','importou',
 'Bruno importou {n} processos da planilha CONSULTA_GERAL_SISPAD_2026-11-17.xlsx (consulta geral do SISPAD de 17/11/2026).')""")
print('planilha', len(reg), 'banco', n)
