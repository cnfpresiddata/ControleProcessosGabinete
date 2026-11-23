# Registro de Testes de Integração

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 09. Registro de Testes de Integração | 1.4 | 23/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |
| 1.2 | 22/11/2026 | Bruno-LSO | Projeto independente: perfis, log, rótulos, funções e logins no schema sispad |
| 1.3 | 23/11/2026 | Bruno-LSO | Prazo individual por processo, data de conclusão com botão Concluir e Painel com evolução e tempo de resolução |
| 1.4 | 23/11/2026 | Bruno-LSO | Só o prazo informado pelo órgão (saem regras de prazo e feriados) e análise do prazo dado por órgão |

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
| CT-17 | Retirado em 23/11/2026 com as regras de prazo e os feriados | Não se aplica |

## Última execução

22/11/2026: 10 de 10 casos aprovados.

22/11/2026, regras de prazo: CT-17 aprovado.

| CT-19 | Independência: cada login só vê o próprio projeto. Talita e Bruno do sispad não veem o jogo nem o caged; Bruno do jogo e Bruno do caged não veem o sispad; visitante sem login não vê nada; o login antigo da Talita (domínio sem projeto) é recusado | RNF-003, R-02 |

22/11/2026, independência: CT-19 aprovado (`testes/testar_independencia.py`, só leitura). Gatilhos de log do sispad e do caged conferidos numa transação desfeita no fim.

| CT-20 | Trava de datas no banco, numa transação desfeita no fim: recebimento no futuro, conclusão no futuro e conclusão antes do recebimento são recusados com mensagem clara | RF-024 |

23/11/2026, prazo individual e conclusão: CT-20 aprovado. Migração conferida por dois caminhos: contagem no banco (673 processos, 673 com prazo informado pelo órgão, 0 concluídos, o mesmo último `atualizado_em`) e comparação campo a campo com a cópia de segurança (0 diferenças fora de `prazo_modo`).

23/11/2026, só o prazo informado pelo órgão: CT-20 aprovado de novo depois da migração (recebimento e conclusão no futuro e prazo antes do recebimento recusados; prazo normal aceito; transação desfeita). Conferência por dois caminhos: estrutura (0 tabelas e 0 funções de regra; gatilhos `carimbar`, `conferir_datas` e `log_processos`) e comparação com a cópia (0 diferenças nos 673 processos).
