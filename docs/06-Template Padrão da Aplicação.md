# Template Padrão da Aplicação

| Projeto | Documento | Versão | Data | Autor |
|---|---|---|---|---|
| Controle de Processos do Gabinete | 06. Template Padrão da Aplicação | 1.3 | 22/11/2026 | Bruno-LSO |

**Histórico de versões**

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 22/11/2026 | Bruno-LSO | Primeira versão |
| 1.3 | 22/11/2026 | Bruno-LSO | Identidade visual do Confea (design system do Claude Design), botão Início e ajuda com ? em cada seção |

## Origem

Design system "CONFEA/CREA-SP Design System" do Claude Design (https://claude.ai/artifact/3uFmr3qaXfCvoxVUMj4qq4), feito a partir do Manual de Identidade Visual do Confea (05/2019). Pedido do Bruno em 22/11/2026: identidade do Confea, visual limpo e direto, com efeitos tecnológicos.

## Cores

| Token | Valor | Uso |
|---|---|---|
| `--azul` / `--esc` | #00509b (Pantone 280C) | Faixa do topo, botão principal, títulos das seções, aba ativa, foco |
| `--esc-h` | #1465b0 | Botão principal ao passar o mouse |
| `--ouro` | #ba9705 (Pantone 457C) | Botão Início fora da tela inicial, card selecionado, número que mudou, contador de filtros, exemplo da ajuda |
| `--bg` | #f6f8fb | Fundo, com dois degradês radiais suaves |
| `--tx`, `--tx2`, `--tx3` | #161d24, #57667a, #6b7a8f | Texto, texto secundário, texto fraco |
| `--ln`, `--ln2` | #dfe5ec, #c7d0dc | Bordas de 1,5 px |
| `--verm`, `--lar`, `--amar`, `--verde` | #c62828, #e8590c, #b7791f, #2e7d32 | Só para prazo e prioridade (pedido da Talita) |

## Tipografia

Barlow Semi Condensed (títulos, números dos cards, rótulos dos cards, cabeçalho da tabela) e Public Sans (texto e campos), pelo Google Fonts. O manual usa Futura XBlk BT e Verdana só dentro do logotipo; o design system registra a troca.

## Marca

`assets/logo-confea-crea-branca.png`: logotipo Confea/Crea em branco e ouro, para a faixa azul, feito a partir do arquivo oficial do design system (o arquivo "negativa" do design system tem letras pretas). `assets/brasao-confeacrea.png`: brasão na tela de entrada.

## Formas

Cantos de 10 px (botões e campos), 12 px (cartões da lista e da ajuda), 14 px (faixa do topo), 16 px (cards e área principal). Sombras `--sh-sm`, `--sh-md`, `--sh-lg`. Sem faixa colorida na lateral dos cards: a cor vem de um ponto antes do rótulo.

## Efeitos

Todos informam algo e somem com "reduzir movimento" do sistema.

| Efeito | O que informa |
|---|---|
| Brilho que cruza a faixa do topo uma vez | A página abriu |
| Entrada em sequência do topo, dos cards, dos filtros e da lista | A página está pronta |
| Barras que correm no lugar da lista | Os processos estão carregando |
| Anel que pulsa no ponto verde | Ligação ao vivo ativa |
| Linha dourada que corre na base do topo | A página está conferindo os dados com o banco |
| Número do card conta até o valor novo e fica dourado | O número mudou |
| Card Prazo vencido vermelho com anel que pulsa | Há prazo vencido |
| Linha da lista com fundo dourado que some | Outra pessoa acabou de mudar este processo |
| Card sobe 2 px e ganha sombra | O card pode ser clicado |
| Botão Início dourado com dois anéis | Você saiu da tela inicial |
| Troca de tela com subida curta | A tela mudou |
| Blocos da ajuda entram em sequência; o bloco pedido fica dourado | Onde está a explicação pedida |

## Layout e responsividade

| Faixa | Comportamento |
|---|---|
| Largura a partir de 1440 px | Filtros numa linha; tabela com 8 colunas |
| 860 a 1439 px | Filtros em 2 linhas; tabela sem Tipo abaixo de 1180 px e sem UF abaixo de 1000 px |
| Até 859 px | Cartões no lugar da tabela; cards em 3 + 2 com rótulo curto; filtros numa tela própria; processo em abas |
| Até 600 px | Logotipo sai do topo |
| Até 420 px | Título sai do topo; ficam Início, ?, ponto ao vivo e os botões |
| Altura até 520 px | Cards numa linha, número em cima do rótulo |
