import os, json, urllib.request, urllib.error
REF='rmjlqngrfgorhcwaarou'
PAT=os.environ.get('CNF-PRES-DATA')
def sql(q):
    req=urllib.request.Request(f'https://api.supabase.com/v1/projects/{REF}/database/query',data=json.dumps({'query':q}).encode(),headers={'Authorization':'Bearer '+PAT,'Content-Type':'application/json','User-Agent':'cli'},method='POST')
    try:
        with urllib.request.urlopen(req,timeout=120) as r: return json.loads(r.read())
    except urllib.error.HTTPError as e: raise RuntimeError(e.read().decode()[:800])
def mgmt(path,method='GET',body=None):
    req=urllib.request.Request(f'https://api.supabase.com/v1/projects/{REF}{path}',data=json.dumps(body).encode() if body is not None else None,headers={'Authorization':'Bearer '+PAT,'Content-Type':'application/json','User-Agent':'cli'},method=method)
    with urllib.request.urlopen(req,timeout=120) as r: return json.loads(r.read() or b'null')
