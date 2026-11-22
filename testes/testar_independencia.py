"""Confere que cada login só enxerga o próprio projeto. Só lê; não grava nada."""
import sys, json, urllib.request, urllib.error
S = json.load(open(sys.argv[1]))
URL = 'https://rmjlqngrfgorhcwaarou.supabase.co'
ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtamxxbmdyZmdvcmhjd2Fhcm91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NTI4NjIsImV4cCI6MjEwMjEyODg2Mn0.sQazP8j9mxG7iXP66_2PXWZmE7sSCk0KXcu_SLs4H_c'
def req(path, tok, perfil, method='GET', body=None):
    h = {'apikey': ANON, 'Authorization': 'Bearer ' + (tok or ANON), 'Content-Type': 'application/json', 'Accept-Profile': perfil, 'Content-Profile': perfil}
    r = urllib.request.Request(URL + path, method=method, data=json.dumps(body).encode() if body is not None else None, headers=h)
    try:
        with urllib.request.urlopen(r) as x: return x.status, json.loads(x.read() or b'null')
    except urllib.error.HTTPError as e: return e.code, e.read().decode()[:120]
def login(email, pw):
    s, d = req('/auth/v1/token?grant_type=password', None, 'public', 'POST', {'email': email, 'password': pw})
    return d.get('access_token') if isinstance(d, dict) else None
contas = {
  'talita (sispad)': login('talita@sispad.cnfpresiddata.local', S['talita']),
  'bruno (sispad)': login('bruno@sispad.cnfpresiddata.local', S['bruno']),
  'bruno (jogo)': login('bruno@jogo-confea.cnfpresiddata.local', S['bruno_jogo']),
  'bruno (caged)': login('bruno@cnfpresiddata.local', S['bruno']),
  'visitante': None,
}
print('login antigo da talita recusado:', login('talita@cnfpresiddata.local', S['talita']) is None)
for nome, t in contas.items():
    if nome != 'visitante' and not t: print('FALHA login', nome); continue
    s1, d1 = req('/rest/v1/rpc/meu_perfil', t, 'sispad', 'POST', {})
    s2, d2 = req('/rest/v1/processos?select=id&limit=1', t, 'sispad')
    s3, d3 = req('/rest/v1/player_phones?select=player_id&limit=1', t, 'jogo_confea')
    s4, d4 = req('/rest/v1/rpc/meu_perfil', t, 'caged', 'POST', {})
    s5, d5 = req('/rest/v1/valoriza_lotes?select=id&limit=1', t, 'caged')
    s6, d6 = req('/rest/v1/eventos?select=id&limit=1', t, 'sispad')
    vê = lambda s, d: 'vê' if s in (200, 206) and d else 'não vê'
    print(f"{nome:16} sispad perfil={d1 if s1==200 else s1} processos={vê(s2,d2)} log={vê(s6,d6)} | jogo telefones={vê(s3,d3)} | caged perfil={d4 if s4==200 else s4} lotes={vê(s5,d5)}")
