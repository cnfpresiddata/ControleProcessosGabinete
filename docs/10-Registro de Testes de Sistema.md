# Registro de Testes de Sistema

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 10. Registro de Testes de Sistema | 1.4 | 23/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |
| 1.2 | 22/11/2026 | Bruno-LSO | Projeto independente: perfis, log, rótulos, funções e logins no schema sispad |
| 1.3 | 22/11/2026 | Bruno-LSO | Identidade visual do Confea (design system do Claude Design), botão Início e ajuda com ? em cada seção |
| 1.4 | 23/11/2026 | Bruno-LSO | Prazo individual por processo, data de conclusão com botão Concluir e Painel com evolução e tempo de resolução |

## Ferramentas

Playwright 1.65.2 com o Chrome instalado. Scripts `testes/testar_tela.py` e `testes/testar_vivo.py`, com o login real. Script `testes/testar_painel.py`, com o Supabase simulado (`testes/supabase_simulado.js`): a página roda com a cópia de segurança dos processos e datas de exemplo na memória do teste, sem gravar nada no banco.

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
| CT-21 | Números do painel iguais ao cálculo independente em Python: recebidos, concluídos, em aberto, tempo médio e concluídos no prazo; a barra do mês atual e a linha do TCU abrem a janela com o mesmo número de processos | RF-025, RF-026 |
| CT-22 | Concluir propõe hoje, recusa data futura e data antes do recebimento, grava a data e a situação Respondido; situação Arquivado sem data pede a data | RF-023, RF-024 |
| CT-23 | Prazo mostrado: "De 13/11/2026 a 30/11/2026: 17 dias corridos." | RF-022 |
| CT-24 | Processo aberto da janela mostra o botão Painel e volta com a janela aberta; Esc fecha a janela | RF-026 |
| CT-18 | Prévia do prazo na tela igual ao banco (MPF 23/11, TCU/DENÚNCIA 23/11, TCU/REPRESENTAÇÃO pela regra geral 23/11) e campo liberado no modo manual, com regras só na memória da página | RF-016, RF-018 |

## Última execução

22/11/2026: 78 combinações de tela e tamanho, 0 problemas, 0 erros de JavaScript. CT-16 aprovado.

22/11/2026, regras de prazo: 123 combinações de tela e tamanho (com as telas Prazos, Nova regra, Feriados e Adicionar dia), 0 problemas, 0 erros de JavaScript; CT-18 aprovado.

22/11/2026, independência: 123 combinações de tela sem problema no site publicado; gameCONFEA, PostitGameCONFEA, AdmGameCONFEA (login com a conta do jogo), cagedcnfcr e cagedcnfcr/adm (login com a conta do caged) abriram sem erro e sem resposta HTTP de erro.

22/11/2026, identidade, Início e ajuda: 231 combinações de tela e tamanho (as telas anteriores, as 11 telas de ajuda e a ajuda aberta pelo ? de um card), 0 problemas, 0 erros de JavaScript. O teste também confere rótulo de card cortado e botão do topo fora da tela.

23/11/2026, prazo individual, conclusão e painel (`testes/testar_painel.py`): 241 combinações de tela e tamanho (todas as telas, painel, abas e filtros do painel, painel vazio, painel por semana, janela de processos e ajuda), 0 problemas, 0 erros de JavaScript; 25 de 25 conferências aprovadas (CT-21 a CT-24). O teste também confere rótulos sobrepostos no eixo, gráfico baixo demais, item cortado na janela e botão cortado no topo.
