# Controle de Processos do Gabinete

Página de acompanhamento dos processos de órgãos de controle (TCU, MPF, Polícia Federal, MPT, CGU, AGU, PGR e Ministérios Públicos estaduais) recebidos pelo Gabinete da Presidência do Confea.

Endereço: https://cnfpresiddata.github.io/ControleProcessosGabinete/

| Item | Valor |
|---|---|
| Autor | Bruno-LSO |
| Pedido | Talita Machado, Gabinete da Presidência, 10/11/2026 |
| Base inicial | Consulta geral do SISPAD de 17/11/2026, 673 processos |
| Banco | Supabase `rmjlqngrfgorhcwaarou`, schema `sispad` |

## O que a página faz

- Mostra os processos com o prazo para resposta em destaque: vencido em vermelho, até 3 dias em laranja, de 4 a 7 dias em amarelo.
- Registra a situação do processo: Recebido pelo Gabinete, Encaminhado à unidade responsável, Aguardando assinatura do Ofício, Respondido, Arquivado.
- Registra a prioridade: Crítica (vermelho), Alta (laranja), Normal (verde).
- Guarda o prazo de cada processo, informado pelo órgão demandante, e mostra o prazo do dia do recebimento ao dia final ("De 13/11/2026 a 30/11/2026: 17 dias corridos."). A regra por órgão e tipo de procedimento, em dias úteis ou corridos, continua como opção na tela Prazos.
- Registra a data de conclusão. O botão Concluir propõe a data de hoje, permite trocar e grava depois da confirmação. Data de recebimento e data de conclusão no futuro são recusadas, na página e no banco.
- Painel: processos recebidos e concluídos por mês, semana ou ano (barras), tempo médio de resolução no geral, por órgão e por tipo, e parte dos concluídos dentro do prazo. Filtros por órgão, tipo, UF e período. Clique em qualquer barra, linha ou número para ver a lista dos processos e abrir cada um.
- Mostra 5 indicadores: prazo vencido, vence em até 7 dias, prioridade crítica em aberto, aguardando resposta e sem situação definida. Clique num indicador para filtrar a lista.
- Filtra por situação, prioridade, prazo, órgão, UF, tipo de procedimento, situação histórica (AGS) e texto livre.
- Atualiza ao vivo: a alteração feita por uma pessoa aparece na tela das outras em poucos segundos.
- Registra no histórico quem fez cada ação, quando e o que mudou, em frase simples.
- Cabe na tela inteira, sem rolagem, do celular de 320 px de largura ao monitor de 2560 px.

## Perfis

| Perfil | Pode |
|---|---|
| admin | consultar, editar, cadastrar e excluir |
| editor | consultar, editar e cadastrar |
| leitor | consultar |

Os perfis ficam na tabela `sispad.perfis`. As contas usam o domínio `sispad.cnfpresiddata.local`; na tela, a pessoa digita só o usuário. O cadastro livre de contas está desligado.

## Independência

Este projeto é 100% independente dos outros projetos do mesmo banco Supabase: dados, perfis, log, funções e logins ficam só no schema `sispad`. Nenhuma mudança pode quebrar o link de uma página publicada.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `index.html` | A aplicação inteira (HTML, CSS e JavaScript, sem etapa de build) |
| `supabase/migrations/` | Migrações aplicadas ao banco, em ordem |
| `docs/` | Documentação do projeto (modelo PUC, documentos 01 a 13) |

## Documentação

1. [Documentação de Contexto](docs/01-Documentação%20de%20Contexto.md)
2. [Especificação do Projeto](docs/02-Especificação%20do%20Projeto.md)
3. [Metodologia](docs/03-Metodologia.md)
4. [Projeto de Interface](docs/04-Projeto%20de%20Interface.md)
5. [Arquitetura da Solução](docs/05-Arquitetura%20da%20Solução.md)
6. [Template Padrão da Aplicação](docs/06-Template%20Padrão%20da%20Aplicação.md)
7. [Programação de Funcionalidades](docs/07-Programação%20de%20Funcionalidades.md)
8. [Registro de Testes Unitários](docs/08-Registro%20de%20Testes%20Unitários.md)
9. [Registro de Testes de Integração](docs/09-Registro%20de%20Testes%20de%20Integração.md)
10. [Registro de Testes de Sistema](docs/10-Registro%20de%20Testes%20de%20Sistema.md)
11. [Registro de Contribuição](docs/11-Registro%20de%20Contribuição.md)
12. [Apresentação do Projeto](docs/12-Apresentação%20do%20Projeto.md)
13. [Referências](docs/13-Referências.md)
