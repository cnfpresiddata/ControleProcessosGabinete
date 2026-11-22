# Registro de Testes de Integração

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 09. Registro de Testes de Integração | 1.1 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |

## Ferramenta

`testes/testar_regras.py` (Python 3.12, sem dependências externas). Chama a API do Supabase com a chave pública e com o login da Talita.

## Como rodar

```
python testes/testar_regras.py senhas.json
```

`senhas.json` tem as senhas de teste e não vai para o repositório.

## Casos

| Código | Caso | Requisito |
|---|---|---|
| CT-01 | Visitante sem login não lê `processos` | RNF-003 |
| CT-02 | Visitante sem login não lê `historico` | RNF-003 |
| CT-03 | Editor lê os processos | RF-002 |
| CT-04 | `meu_perfil` devolve o papel `editor` | RF-001 |
| CT-05 | Editor do `sispad` não lê os telefones do jogo (`jogo_confea.player_phones`) | RNF-003 |
| CT-06 | Editor altera situação, prioridade e prazo | RF-004, RF-005, RF-006 |
| CT-07 | O log registra a alteração com o nome e a frase | RF-010 |
| CT-08 | Editor não exclui processo | RNF-003 |
| CT-09 | O teste desfaz a própria alteração | RNF-004 |
| CT-10 | Gravação feita sobre uma versão antiga do processo é recusada | RNF-006 |
| CT-17 | Cálculo no banco, numa transação desfeita no fim: recebido em 13/11/2026; regra geral de 10 dias corridos dá 23/11; TCU/DENÚNCIA com 5 dias úteis dá 23/11 (pula o feriado de 20/11); feriado de teste em 23/11 leva os dois para 24/11; prazo manual fica em 31/12 depois de mudar a regra | RF-016, RF-017, RF-018 |

## Última execução

22/11/2026: 10 de 10 casos aprovados.

22/11/2026, regras de prazo: CT-17 aprovado.
