# Arquitetura da Solução

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 05. Arquitetura da Solução | 1.0 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |

## Componentes

```mermaid
flowchart LR
  N[Navegador: index.html + supabase-js] -->|HTTPS REST| R[PostgREST]
  N -->|WebSocket| RT[Realtime]
  N -->|login| AU[Supabase Auth]
  R --> DB[(PostgreSQL)]
  RT --> DB
  GH[GitHub Pages] -->|entrega index.html| N
```

## Organização do banco compartilhado

O projeto Supabase `rmjlqngrfgorhcwaarou` atende vários projetos do Confea. Cada projeto tem um schema próprio.

| Schema | Conteúdo | Exposto na API |
|---|---|---|
| `acesso` | `projetos` (catálogo) e `perfis` (usuário, projeto, papel) | Não |
| `auditoria` | `eventos` (log de todos os projetos) e `rotulos` (nomes legíveis das colunas) | Não |
| `sispad` | Este projeto: `processos`, visão `historico`, funções `meu_perfil` e `registrar_acesso` | Sim |
| `jogo_confea` | Jogo do Confea (gameCONFEA, AdmGameCONFEA, PostitGameCONFEA) | Sim |
| `arquivo` | Cópias de segurança antigas do jogo, sem acesso pela API | Não |
| `manutencao` | Tabela `keepAlive` do sinal de atividade | Não |
| `public` | Só a função `keepalive_enviar`, mantida para quem já a chama | Sim |

## Modelo de dados

```mermaid
erDiagram
  PROJETOS ||--o{ PERFIS : tem
  PERFIS }o--|| USUARIOS : "auth.users"
  PROCESSOS ||--o{ EVENTOS : registra
  PROJETOS {
    text codigo PK
    text nome
    text[] paginas
  }
  PERFIS {
    uuid user_id PK
    text projeto PK
    text papel
    text nome
    text usuario
    boolean ativo
  }
  PROCESSOS {
    bigint id PK
    text processo_sei
    text processo_orgao
    text orgao_demandante
    text uf
    text localidade
    text assunto
    text situacao_ags
    text relator
    text tipo_procedimento
    text situacao
    text prioridade
    date data_recebimento
    date prazo_resposta
    text observacao
    int linha_planilha
    jsonb origem
    timestamptz atualizado_em
  }
  EVENTOS {
    bigint id PK
    text projeto
    timestamptz quando
    uuid user_id
    text usuario
    text acao
    text registro
    text descricao
    jsonb antes
    jsonb depois
  }
```

## Regras de acesso (RLS)

| Tabela | Ler | Criar e alterar | Excluir |
|---|---|---|---|
| `sispad.processos` | perfil `admin`, `editor` ou `leitor` no projeto `sispad` | `admin` ou `editor` | `admin` |
| `auditoria.eventos` | quem tem perfil no projeto do evento | só os gatilhos (função com privilégio do dono) | ninguém |
| `acesso.perfis` | o próprio usuário | só o administrador do banco | só o administrador do banco |

A função `acesso.tem_papel(projeto, papéis)` decide o acesso. O cadastro livre de contas está desligado no Auth.

## Log

O gatilho `auditoria.registrar()` grava cada inclusão, alteração e exclusão com a pessoa, a hora, os valores antes e depois e uma frase como: `Talita alterou o processo 017.048/2026-5: Prioridade: "Crítica" (antes sem valor).` A entrada, a saída e a troca de senha entram pela função `sispad.registrar_acesso`.

## Importação

`supabase/importar_planilha.py` lê a planilha, troca "-" por vazio, troca "PF" por "Polícia Federal" e grava a linha original inteira em `origem`. Resultado conferido em 22/11/2026: 673 linhas na planilha, 673 no banco; 34 da Polícia Federal (22 "Polícia Federal" e 12 "PF"); 343 com UF (345 menos 2 com "-").

## Qualidade (ISO/IEC 25010)

| Característica | Medida | Resultado |
|---|---|---|
| Adequação funcional | RF implementados | 14 de 14 |
| Eficiência | Consultas ao abrir | 3 (perfil, processos, histórico) |
| Usabilidade | Telas sem rolagem e sem sobreposição | 78 de 78 combinações de tela testadas |
| Segurança | Acesso sem login aos processos | Recusado (HTTP 401) |
| Confiabilidade | Alteração sobre versão antiga | Recusada (CT-10); a tela recarrega e avisa |
