# Programação de Funcionalidades

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 07. Programação de Funcionalidades | 1.5 | 23/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |
| 1.2 | 22/11/2026 | Bruno-LSO | Projeto independente: perfis, log, rótulos, funções e logins no schema sispad |
| 1.3 | 22/11/2026 | Bruno-LSO | Identidade visual do Confea (design system do Claude Design), botão Início e ajuda com ? em cada seção |
| 1.4 | 23/11/2026 | Bruno-LSO | Prazo individual por processo, data de conclusão com botão Concluir e Painel com evolução e tempo de resolução |
| 1.5 | 23/11/2026 | Bruno-LSO | Só o prazo informado pelo órgão (saem regras de prazo e feriados) e análise do prazo dado por órgão |

| Requisito | Situação | Onde | Como verificar |
|---|---|---|---|
| RF-001 | Implementado | `index.html`, `telaLogin`, `iniciar`; `sispad.meu_perfil` | Entrar com usuário sem perfil: mensagem "Este usuário não tem acesso" |
| RF-002 | Implementado | `renderLista` | Abrir o painel |
| RF-003 | Implementado | `prazoInfo`, classes `p-venc`, `p-urg`, `p-aten` | Pôr prazo de ontem num processo: linha vermelha e indicador vermelho |
| RF-004 | Implementado | `SITUACOES`; restrição `check` em `sispad.processos.situacao` | Aba Acompanhamento |
| RF-005 | Implementado | `PRIORIDADES`; restrição `check` em `prioridade` | Botões Crítica, Alta, Normal |
| RF-006 | Implementado | formulário `#acomp` | Salvar e reabrir o processo |
| RF-007 | Implementado | `kpis`, `KPI_DEF` | Clicar num indicador filtra a lista |
| RF-008 | Implementado | `passa`, `filtrosHTML` | Combinar filtros |
| RF-009 | Implementado | `renderNovo` | Novo processo e Corrigir dados |
| RF-010 | Implementado | `sispad.registrar`, `sispad.registrar_acesso`, tabela `sispad.eventos` | Histórico de ações |
| RF-011 | Implementado | `renderHistorico`, `encaixarEventos` | Histórico geral e aba Histórico do processo |
| RF-012 | Implementado | `assinar` (Realtime de `sispad.processos` e `sispad.eventos`) | Duas telas abertas: a alteração aparece na outra |
| RF-013 | Implementado | `renderConta` | Minha conta, Trocar senha |
| RF-014 | Implementado | `baixarCSV` | Minha conta, Baixar planilha |
| RF-015 | Retirado em 23/11/2026 | Não se aplica | Não se aplica |
| RF-016 | Retirado em 23/11/2026 | Não se aplica | Não se aplica |
| RF-017 | Retirado em 23/11/2026 | Não se aplica | Não se aplica |
| RF-018 | Implementado | campo Prazo dado pelo órgão (`prazo_resposta`) | Informar o prazo e salvar |
| RF-019 | Implementado | `irInicio`, `emInicio`, classe `bt-inicio` | Abrir um processo: o Início fica dourado; clicar volta à lista sem filtros |
| RF-020 | Implementado | `topicosAjuda`, `exemplos`, `renderAjuda`, `paginarAjuda`, atributo `data-ajuda` | Clicar em cada ? abre o assunto certo |
| RF-021 | Implementado | bloco `<style id="identidade-confea">`, `assets/` | Comparar com o design system do Claude Design |
| RF-022 | Implementado | `previa`, `faixa` em `renderDetalhe` | Recebido 13/11/2026 e prazo 30/11/2026: "De 13/11/2026 a 30/11/2026: 17 dias corridos." |
| RF-023 | Implementado | `pedirConclusao`, `salvar`, `infoConcl`; coluna `data_conclusao` | Concluir propõe hoje; Confirmar conclusão grava |
| RF-024 | Implementado | `validar` na página; gatilho `sispad.conferir_datas` no banco | Data de amanhã é recusada |
| RF-025 | Implementado | `renderPainel`, `pnDados`, `desenharEvol`, `desenharGrupos`; bloco `<style id="painel">` | Botão Painel no topo |
| RF-026 | Implementado | `abrirModal`, `renderModal`, `abrirDoPainel`, `E.voltaModal` | Clicar numa barra, abrir um processo e voltar com o botão Painel |
| RF-027 | Implementado | `estatPrazos`, `quantil`, `foraPadrao`, `desenharPrazos`; número Prazos fora do padrão | Painel, quadro Prazo dado por órgão |
| RF-028 | Implementado | `compararPrazo`, `previa` em `renderDetalhe` | Informar um prazo bem maior que o habitual do órgão: aparece "Fora do padrão" |
