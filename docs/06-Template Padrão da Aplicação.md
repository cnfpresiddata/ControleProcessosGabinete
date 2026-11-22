# Template Padrão da Aplicação

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 06. Template Padrão da Aplicação | 1.0 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |

## Identidade visual

Interface limpa, com uma família de fonte e cor só onde informa algo (prazo e prioridade).

## Tokens

| Token | Valor | Uso |
|---|---|---|
| `--bg` | #f5f6f8 | Fundo |
| `--sup` | #ffffff | Cartões e área principal |
| `--tx` | #16181d | Texto |
| `--esc` | #16181d | Botão principal |
| `--verm` | #c62828 | Prazo vencido, prioridade Crítica |
| `--lar` | #e8590c | Vence em 1 a 3 dias, prioridade Alta |
| `--amar` | #b7791f | Vence em 4 a 7 dias |
| `--verde` | #2e7d32 | Prioridade Normal, indicador "Ao vivo" |
| `--azul` | #1f4e8c | Indicador "Aguardando resposta" |

## Tipografia

Geist (Google Fonts), pesos 400 a 700. Texto base 14 px. Números dos indicadores 26 px no computador e 18 a 21 px no celular.

## Layout e responsividade

| Faixa | Comportamento |
|---|---|
| Largura a partir de 1440 px | Filtros numa linha; tabela com 8 colunas |
| 860 a 1439 px | Filtros em 2 linhas; tabela sem Tipo abaixo de 1180 px e sem UF abaixo de 1000 px |
| Até 859 px | Cartões no lugar da tabela; indicadores em 3 + 2; filtros numa tela própria; processo em abas |
| Altura até 520 px | Indicadores numa linha com rótulo curto; espaçamentos menores |

## Componentes

Botão, selo de prazo, selo de prioridade, cartão de indicador, cartão de processo, linha de tabela, item de histórico, formulário paginado.
