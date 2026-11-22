# Registro de Testes de Sistema

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 10. Registro de Testes de Sistema | 1.2 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |
| 1.2 | 22/11/2026 | Bruno-LSO | Projeto independente: perfis, log, rótulos, funções e logins no schema sispad |

## Ferramentas

Playwright 1.65.2 com o Chrome instalado. Scripts `testes/testar_tela.py` e `testes/testar_vivo.py`.

## Tamanhos de tela

320 x 568, 360 x 640, 390 x 844, 568 x 320 (celular deitado), 768 x 1024, 1024 x 768, 1366 x 768, 1920 x 1080 e 2560 x 1440.

## Casos

| Código | Caso | Requisito |
|---|---|---|
| CT-11 | Sem rolagem vertical e horizontal em todas as telas e tamanhos | RNF-001 |
| CT-12 | Blocos do painel sem sobreposição | RNF-002 |
| CT-13 | Nenhum botão, campo, linha ou cartão cortado na área principal | RNF-001 |
| CT-14 | Assunto de 835 caracteres legível inteiro em todos os tamanhos | RNF-001 |
| CT-15 | Sem erro de JavaScript | todos |
| CT-16 | Alteração numa tela aparece na outra: indicador "Prazo vencido" passa de 0 para 1 e volta a 0 | RF-012, RF-003 |
| CT-18 | Prévia do prazo na tela igual ao banco (MPF 23/11, TCU/DENÚNCIA 23/11, TCU/REPRESENTAÇÃO pela regra geral 23/11) e campo liberado no modo manual, com regras só na memória da página | RF-016, RF-018 |

## Última execução

22/11/2026: 78 combinações de tela e tamanho, 0 problemas, 0 erros de JavaScript. CT-16 aprovado.

22/11/2026, regras de prazo: 123 combinações de tela e tamanho (com as telas Prazos, Nova regra, Feriados e Adicionar dia), 0 problemas, 0 erros de JavaScript; CT-18 aprovado.

22/11/2026, independência: 123 combinações de tela sem problema no site publicado; gameCONFEA, PostitGameCONFEA, AdmGameCONFEA (login com a conta do jogo), cagedcnfcr e cagedcnfcr/adm (login com a conta do caged) abriram sem erro e sem resposta HTTP de erro.
