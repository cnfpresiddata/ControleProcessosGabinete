# Metodologia

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 03. Metodologia | 1.0 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |

## Ambientes

| Ambiente | Endereço |
|---|---|
| Produção | https://cnfpresiddata.github.io/ControleProcessosGabinete/ |
| Banco | Supabase `rmjlqngrfgorhcwaarou`, schema `sispad` |
| Teste local | `python -m http.server 8765` na pasta do repositório e `http://127.0.0.1:8765/` |

Não existe banco de homologação. Os testes de tela usam a conta de administrador e desfazem toda alteração no fim.

## Controle de versão

- Repositório: `cnfpresiddata/ControleProcessosGabinete`, branch `main`, publicada pelo GitHub Pages.
- Commits em português, no nome de Bruno-LSO.
- Toda mudança no banco entra como migração nova em `supabase/migrations/`, com data e nome. Migração aplicada não é editada.

## Papéis

| Papel | Pessoa |
|---|---|
| Responsável técnico | Bruno-LSO |
| Dona do processo de negócio | Talita Machado |

## Processo

1. Receber o pedido do Gabinete.
2. Registrar o requisito no 02 com a origem.
3. Alterar o banco por migração e a página no `index.html`.
4. Rodar os testes de `testes/` (regras, tela e ao vivo).
5. Atualizar a documentação no mesmo commit.
6. Publicar na `main`.

## Manutenção da documentação

| Tipo de alteração | Documentos que mudam |
|---|---|
| Requisito novo ou alterado | 02, 07 |
| Tela nova ou alterada | 04, 06, 07, 10 |
| Banco (tabela, regra, função) | 05, 07, 09 |
| Teste novo ou nova execução | 08, 09, 10 |
| Qualquer entrega | 11 |

## Ferramentas

| Ferramenta | Uso |
|---|---|
| GitHub e GitHub Pages | Código e hospedagem |
| Supabase (PostgreSQL 17, PostgREST, Auth, Realtime) | Banco, API, login e atualização ao vivo |
| supabase-js 2.45.4 | Cliente no navegador |
| Python 3.12 e Playwright | Importação da planilha e testes |
