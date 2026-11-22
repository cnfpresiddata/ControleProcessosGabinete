import sys, json, urllib.request, urllib.error
S = json.load(open(sys.argv[1]))
URL = 'https://rmjlqngrfgorhcwaarou.supabase.co'
ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtamxxbmdyZmdvcmhjd2Fhcm91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NTI4NjIsImV4cCI6MjEwMjEyODg2Mn0.sQazP8j9mxG7iXP66_2PXWZmE7sSCk0KXcu_SLs4H_c'
def req(path, tok=None, method='GET', body=None, perfil='sispad', extra=None):
    h = {'apikey': ANON, 'Authorization': 'Bearer ' + (tok or ANON), 'Content-Type': 'application/json', 'Accept-Profile': perfil, 'Content-Profile': perfil}
    h.update(extra or {})
    r = urllib.request.Request(URL + path, method=method, data=json.dumps(body).encode() if body is not None else None, headers=h)
    try:
        with urllib.request.urlopen(r) as x: return x.status, json.loads(x.read() or b'null')
    except urllib.error.HTTPError as e: return e.code, e.read().decode()[:150]
def login(u):
    s, d = req('/auth/v1/token?grant_type=password', method='POST', body={'email': f'{u}@cnfpresiddata.local', 'password': S[u]})
    return d['access_token']
ok = lambda c, t: print(('OK  ' if c else 'FALHA ') + t)
s, d = req('/rest/v1/processos?select=id&limit=1'); ok(s in (401, 403) or d == [], f'visitante sem login não lê processos ({s})')
s, d = req('/rest/v1/historico?select=id&limit=1'); ok(s in (401, 403) or d == [], f'visitante sem login não lê histórico ({s})')
t = login('talita')
s, d = req('/rest/v1/processos?select=id', t, extra={'Prefer': 'count=exact', 'Range': '0-0'}); ok(s in (200, 206), f'Talita lê processos ({s})')
s, d = req('/rest/v1/rpc/meu_perfil', t, 'POST', {}); ok(d and d[0]['papel'] == 'editor', f'perfil da Talita = {d}')
s, d = req('/rest/v1/player_phones?select=*', t, perfil='jogo_confea'); ok(d == [], f'Talita não lê telefones do jogo ({s}, {d})')
s, d = req('/rest/v1/processos?id=eq.-1', t, 'DELETE'); 
s, d = req('/rest/v1/processos?select=id,prioridade,prazo_resposta,atualizado_em&processo_orgao=eq.017.048/2026-5', t); alvo = d[0]
s, d = req(f"/rest/v1/processos?id=eq.{alvo['id']}", t, 'PATCH', {'prioridade': 'Crítica', 'prazo_resposta': '2026-11-20', 'situacao': 'Encaminhado à unidade responsável'}, extra={'Prefer': 'return=representation'})
ok(s == 200 and d[0]['prioridade'] == 'Crítica', f'Talita altera prioridade/prazo/situação ({s})')
s, d = req(f"/rest/v1/historico?select=usuario,acao,descricao&registro_id=eq.{alvo['id']}&order=quando.desc&limit=1", t)
ok(d and d[0]['usuario'] == 'Talita', 'log: ' + (d[0]['descricao'] if d else str(d)))
s, d = req(f"/rest/v1/processos?id=eq.{alvo['id']}&atualizado_em=eq.{alvo['atualizado_em'].replace('+', '%2B')}", t, 'PATCH', {'observacao': 'teste'}, extra={'Prefer': 'return=representation'})
ok(s == 200 and d == [], f'gravação com versão antiga é recusada ({s}, {d})')
s, d = req(f"/rest/v1/processos?id=eq.{alvo['id']}", t, 'DELETE', extra={'Prefer': 'return=representation'}); ok(d == [], f'Talita (editor) não exclui ({s}, {d})')
s, d = req(f"/rest/v1/processos?id=eq.{alvo['id']}", t, 'PATCH', {'prioridade': None, 'prazo_resposta': None, 'situacao': None}, extra={'Prefer': 'return=representation'})
ok(s == 200 and d[0]['prioridade'] is None, 'teste desfeito')
print('ALVO', alvo['id'])
