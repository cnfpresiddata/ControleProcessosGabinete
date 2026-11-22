# Programação de Funcionalidades

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 07. Programação de Funcionalidades | 1.2 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.1 | 22/11/2026 | Bruno-LSO | Regras de prazo por órgão e tipo, dias úteis ou corridos, feriados e cálculo automático |
| 1.2 | 22/11/2026 | Bruno-LSO | Projeto independente: perfis, log, rótulos, funções e logins no schema sispad |

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
| RF-012 | Implementado | `assinar` (Realtime de `sispad.processos`, `sispad.eventos`, `sispad.regras_prazo` e `sispad.feriados`) | Duas telas abertas: a alteração aparece na outra |
| RF-013 | Implementado | `renderConta` | Minha conta, Trocar senha |
| RF-014 | Implementado | `baixarCSV` | Minha conta, Baixar planilha |
| RF-015 | Implementado | `renderPrazos`; tabela `sispad.regras_prazo` | Prazos, Nova regra |
| RF-016 | Implementado | gatilhos `calcular_prazo` e `recalcular`; `somar_prazo`, `regra_para` | Pôr data de recebimento num processo com regra: o prazo aparece |
| RF-017 | Implementado | `sispad.feriados`; aba Feriados | Adicionar dia: os prazos em dias úteis andam um dia |
| RF-018 | Implementado | campo Forma do prazo, `prazo_modo = manual` | Mudar a regra não altera o processo manual |
