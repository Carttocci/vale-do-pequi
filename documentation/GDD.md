# VALE DO PEQUI — Documento mestre de desenvolvimento (GDD)

*Uma vida no campo, uma aventura pelo Cerrado.*

Versão 1.1 · 17/11/2026 · substitui a versão 1.0 (ver §23, Histórico)

---

## 0. Definição oficial

> **Vale do Pequi é um RPG de fazenda, aventura e ação hack-and-slash, ambientado em uma versão fantástica do interior de Goiás. O jogador constrói sua propriedade, cultiva alimentos, cria animais, pesca, explora regiões, enfrenta criaturas, desenvolve equipamentos e descobre histórias inspiradas na cultura e no folclore brasileiro.**

Esta frase orienta todas as decisões. Quando uma proposta não cabe nela, ela não entra no jogo.

**Diretriz de liberdade (mantida da v1.0):** o jogador escolhe como quer viver — fazendeiro, pescador, caçador, explorador, artesão ou aventureiro. A história principal existe e é épica, mas nunca obriga o jogador a abandonar a vida rural: é possível passar dias cuidando da propriedade antes de partir para uma expedição.

---

## 1. Identidade do projeto

| Característica | Definição |
|---|---|
| Nome | Vale do Pequi |
| Gênero | RPG de fazenda, aventura, exploração e ação hack-and-slash |
| Ambientação | Versão fantástica do interior de Goiás e do Cerrado |
| Visão / Arte | Top-down · Pixel art 2D |
| Fazenda | Sistema central |
| Pesca | Sistema profundo |
| Combate | Hack-and-slash dinâmico |
| Exploração | Mundo dividido em regiões |
| Progressão | Habilidades, equipamentos, recursos e propriedade |
| Narrativa | Épica, misteriosa e regional; conclusão própria com mundo aberto depois do final |
| Folclore | Tradicional brasileiro + criaturas originais |
| Plataforma | **Navegador (desktop e celular), publicado no GitHub Pages.** Build Windows como extra |
| Motor / Linguagem | Godot 4 (4.3+) · GDScript |
| Modo | Single-player; multiplayer como possibilidade futura |
| Idioma | Português brasileiro |

> Nota de plataforma: o texto da direção revisada citava "Windows PC" como plataforma inicial. Prevalece a decisão de 16/11/2026: o jogo roda no navegador, no celular e no computador (já implementado na v0.2). O executável Windows continua sendo gerado como opção.

---

## 2. Os pilares (não negociáveis)

Estes são os sistemas centrais. Nenhum deles será substituído para transformar o jogo em algo exclusivamente de exploração ou exclusivamente de fazenda.

1. **Agricultura e fazenda** — plantar, colher, cuidar de animais, expandir a propriedade, construir instalações, produzir alimentos e administrar recursos.
2. **Pesca** — espécies regionais, equipamentos, iscas, raridades, locais secretos, horários e condições climáticas.
3. **Combate hack-and-slash** — combos, esquivas, habilidades, armas, inimigos, chefes, masmorras e equipamentos.
4. **Exploração e aventura** — matas, rios, cavernas, serras, ruínas, regiões secretas, coleta e descobertas.
5. **Comunidade e progressão** — NPCs, amizades, comércio, missões, eventos, culinária, construção e desenvolvimento do personagem.

---

## 3. Originalidade: familiar no gênero, própria na identidade

A originalidade está em **como os sistemas se relacionam com a cultura brasileira**, não em abandonar o que o gênero tem de bom.

| Sistema | Identidade própria de Vale do Pequi |
|---|---|
| Fazenda | Propriedade rural goiana: quintal produtivo, pomar, roça, curral e galinheiro |
| Agricultura | Pequi, baru, mandioca, milho, guariroba, abóbora e outras culturas regionais |
| Animais | Criação rural, manejo, produtos artesanais e animais do Cerrado |
| Pesca | Rios brasileiros, espécies regionais, pescarias especiais e histórias dos pescadores |
| Combate | Facões, lanças, arcos, machados, espadas artesanais e armas fantásticas |
| Exploração | Chapadas, veredas, cavernas, matas, ruínas e estradas antigas |
| Criaturas | Folclore brasileiro, lendas regionais e monstros originais |
| NPCs | Sotaques, costumes, histórias e profissões do interior brasileiro |
| Eventos | Festas juninas, Folia de Reis, Cavalhadas, catira e festividades fictícias inspiradas nessas tradições |
| Culinária | Galinhada, empadão goiano, pamonha, arroz com pequi, doces e receitas regionais |

### 3.1 Como evitar que pareça cópia de Stardew Valley

- Não reproduzir a mesma estrutura de personagens, eventos, missões e progressão.
- Criar uma mitologia original, com referências culturais brasileiras.
- Dar a cada região ecossistema e arquitetura próprios.
- Dar ao combate mais profundidade e importância do que o normal no gênero.
- Pesca, caça e exploração com características regionais (espécies, habitats, costumes).
- Fazenda com identidade rural brasileira: culturas, atividades e construções diferentes.
- Personagens e histórias criados do zero — nunca adaptações de personagens de outros jogos.

### 3.2 Referências de mecânica (inspiração, não cópia)

Stardew Valley (rotina, calendário, relacionamentos) · Sun Haven (fantasia + fazenda + combate) · Core Keeper (mineração, construção) · Moonlighter (masmorras e economia) · Terraria (equipamentos e progressão).

---

## 4. Universo e história

### 4.1 Premissa — "O Vale das Antigas Tradições"

O protagonista começa uma nova vida numa propriedade rural no Vale do Pequi, região fictícia inspirada no interior de Goiás. A propriedade pertence à sua família **há gerações**; está abandonada — casa precisando de reforma, terreno tomado pelo mato, plantações perdidas.

Ao assumir o lugar, ele descobre que o vale tem uma história muito mais antiga e misteriosa do que imaginava. Os moradores falam de criaturas estranhas, de lugares que só aparecem em certas épocas do ano e de acontecimentos sem explicação. Com o tempo, o jogador descobre que algumas dessas histórias são verdadeiras.

O vale tem uma ligação sobrenatural com as **antigas tradições** e com a **memória** de quem vive nele. Criaturas do folclore, entidades originais e forças desconhecidas fazem parte desse mundo.

### 4.2 O Silêncio

Uma força misteriosa chamada **O Silêncio** começa a alterar regiões, corromper criaturas e **apagar antigos conhecimentos** — receitas que ninguém lembra mais, festas que deixaram de acontecer, caminhos que somem do mapa, histórias que os mais velhos já não conseguem contar.

O jogador precisa equilibrar a vida rural com uma aventura que o leva muito além dos limites da propriedade.

**Proposta de design (a validar):** como o Silêncio apaga memória e tradição, **viver o vale é o que o enfrenta**. Recuperar uma receita, reviver uma festa, ouvir e registrar a história de um morador, replantar uma cultura esquecida — tudo isso enfraquece o Silêncio numa região, junto com derrotar seus chefes. Assim fazenda, comunidade e combate alimentam a mesma história, e nenhum estilo de jogo fica de fora.

### 4.3 O papel da fazenda na narrativa

A fazenda não é tutorial nem ponto de partida descartável. É o **lar** do jogador, seu centro de produção, sua fonte de recursos e um lugar importante na história (a família viveu ali por gerações; a propriedade guarda pistas sobre o vale).

### 4.4 Estrutura da narrativa

- Descoberta gradual, sem obrigar o jogador a seguir missões constantemente.
- História principal **épica, com conclusão própria**; depois do final o mundo continua aberto.
- Fios narrativos: a história da propriedade e da família; a origem das ruínas; lendas regionais; mistérios de rios e cavernas; relatos dos moradores mais antigos; criaturas ligadas à natureza; regiões desconhecidas; o Silêncio.
- A fantasia se integra à realidade rural — o vale não vira um cenário medieval.

### 4.5 Folclore: regras de uso

- Misturar **criaturas do folclore brasileiro** com **criaturas originais** do Vale do Pequi.
- Folclore com respeito: as criaturas tradicionais não são "monstros genéricos". Muitas são guardiãs da mata, protetoras ou ambíguas — podem ser aliadas, dar missões ou só aparecer em certas condições. O que o jogador enfrenta em combate são, principalmente, criaturas originais e **criaturas corrompidas pelo Silêncio**.
- Priorizar lendas do Centro-Oeste e de Goiás ao lado das mais conhecidas do país. Cada criatura usada precisa de pesquisa de fonte antes de entrar no jogo (origem, região, o que a lenda realmente diz), registrada em `documentation/folclore.md` (a criar na fase de conteúdo).
- A fauna real não vira monstro indiscriminadamente.
- Evitar estereótipos; respeitar a biodiversidade e as culturas tradicionais.

---

## 5. Direção artística

### 5.1 Paleta

| Elemento | Cores |
|---|---|
| Cerrado | Verde-oliva, verde-escuro |
| Solo | Vermelho-terra, ocre |
| Vegetação seca | Amarelo-dourado |
| Pequi | Amarelo intenso |
| Água | Azul e verde-água |
| Construções | Terracota, bege e madeira |
| Fantasia / sobrenatural | Azul luminoso e violeta |
| O Silêncio | Cores dessaturadas, cinza e ausência de som (proposta) |

### 5.2 Elementos visuais característicos

Pequizeiros · ipês amarelos, rosas e roxos · buritis · capim-dourado · cupinzeiros · estradas de terra vermelha · cercas de madeira · casas rurais com telhado cerâmico · ranchos e currais · cachoeiras e rios · formações rochosas e chapadas · igrejas e praças de cidade pequena · carroças, ferramentas e objetos rurais.

**Regra artística:** cenários feitos com tiles reutilizáveis, com escala, perspectiva, iluminação e estilo consistentes. Nunca usar uma imagem de cenário inteira como se fosse tileset.

---

## 6. Mundo e regiões

O mundo é dividido em áreas conectadas. **Cada região tem atividades rurais, recursos, fauna, inimigos e mistérios próprios.**

| # | Região | Papel | Conteúdo |
|---|---|---|---|
| 1 | **Fazenda do Pequi** | Base principal | Casa, roça, pastagem, galinheiro, curral, pomar de pequi, poço, depósito, área de expansão; agricultura, criação, construção, armazenamento, produção |
| 2 | **Vila de Santa Pequiria** | Comunidade | Praça, igreja, mercearia, ferreiro, mercado, bar e restaurante, casas; comércio, eventos, festas, missões e relacionamentos |
| 3 | **Mata dos Ipês** | Exploração inicial | Cerrado e mata; coleta, madeira, plantas, frutos silvestres, caça, criaturas folclóricas |
| 4 | **Rio das Araras** | Água | Pesca, navegação, cachoeiras, áreas de banho, criaturas aquáticas, locais secretos |
| 5 | **Serra do Cristal** | Mineração | Montanhas, minas abandonadas, cavernas, cristais, minérios, equipamentos, inimigos e chefes |
| 6 | **Ruínas do Cerrado** | Conteúdo avançado | Masmorras, enigmas, símbolos antigos, relíquias, criaturas especiais, história antiga do vale |

**Expansões futuras:** veredas e buritizais · pantanal fictício do Centro-Oeste · chapadas e cânions · vilarejo ribeirinho · fazenda distante · áreas subterrâneas especiais · estradas antigas.

---

## 7. Agricultura e vida rural

### 7.1 Plantio — cada cultura tem

Nome e descrição · preço da semente · tempo de crescimento · estação adequada · número de colheitas · valor de venda · processamento possível · necessidade de água · qualidade do produto.

### 7.2 Culturas regionais

| Cultura | Uso |
|---|---|
| Milho | Alimentação, pamonha, curau |
| Mandioca | Farinha e receitas |
| Feijão | Alimentação |
| Arroz | Alimentação |
| Abóbora, tomate, quiabo | Culinária |
| Cana-de-açúcar | Doces, rapadura, processamento |
| Pequi | Produtos regionais (cultura emblemática) |
| Baru | Castanhas e receitas |
| Guariroba | Culinária regional |
| Maracujá | Bebidas e doces |

O pequi é emblemático mas **sazonal** (safra aproximada de outubro a janeiro) e não é uma plantação comum em toda parte. O fruto se cata no chão depois que cai maduro (já implementado assim na v0.1).

### 7.3 Criação de animais

Galinhas, patos, vacas, porcos, cabras e ovelhas. Produtos: ovos, leite, queijo, manteiga, lã e outros artesanais. Sistema com alimentação, higiene, felicidade, reprodução e melhoria de instalações.

---

## 8. Pesca (sistema profundo)

A pesca é um sistema próprio, não uma atividade secundária.

- Pesca em rios, lagos, lagoas e cachoeiras; locais secretos.
- Espécies diferentes por **habitat, horário, estação e clima**.
- Iscas diferentes; varas com atributos; sistema de raridade; peixes lendários.
- Pescarias especiais e torneios; coleção de espécies; venda e culinária.
- **Histórias dos pescadores** da região como fonte de missões e pistas de peixes lendários.

Espécies possíveis: tucunaré, traíra, piau, pacu, pintado, dourado, lambari. Distribuídas apenas em habitats compatíveis — nada de todas as espécies em todo corpo d'água.

---

## 9. Caça

Rastreamento · pegadas e sinais · identificação de espécies · equipamentos · camuflagem · iscas e atrativos · comportamento animal · raridade · coleta de materiais · registro de descobertas.

Animais possíveis: capivara, veado-campeiro, cateto, paca, cutia, seriema, ema, quati.

**Cuidado obrigatório:** caça de subsistência e atividades de aventura são permitidas; **caçar espécies ameaçadas nunca vira mecânica de recompensa**. Algumas espécies servem só para observação e registro. Criaturas fantásticas oferecem a alternativa de combate e coleta.

---

## 10. Combate hack-and-slash

O combate é uma parte importante da experiência, não um extra. Simples de aprender — inimigos comuns caem sem combos complexos —, com profundidade para quem quiser dominar.

### 10.1 Mecânicas

Ataque básico · ataque carregado · combos · esquiva e rolamento · bloqueio · habilidades especiais · barra de energia · vida · efeitos de estado · chefes com padrões próprios · masmorras.

### 10.2 Estilos por arma

| Arma | Estilo |
|---|---|
| Facão | Ataques rápidos e combos |
| Espada | Equilíbrio entre velocidade e dano |
| Machado | Golpes pesados e quebra de defesas |
| Lança | Alcance e controle de distância |
| Arco | Combate à distância |
| Adagas | Velocidade e esquivas |
| Martelo | Impacto e atordoamento |
| Cajado | Habilidades sobrenaturais |

Armas com aparência artesanal (madeira, couro, ferro) e versões fantásticas nas fases avançadas.

### 10.3 Progressão de combate

Três caminhos combináveis, sem classe definitiva e com redistribuição de pontos: **Guerreiro** (dano, defesa, combos) · **Caçador** (arco, rastreamento, mobilidade) · **Explorador** (esquiva, sobrevivência, coleta).

### 10.4 Inimigos

Criaturas originais (de raízes, de água, de caverna, espíritos luminosos) · guardiões de ruínas · **criaturas corrompidas pelo Silêncio** · chefes de região. Inimigos inspirados na fauna, nas lendas e na fantasia brasileira, seguindo as regras do §4.5.

Para quem prefere a vida rural, o combate continua sendo opcional na progressão do dia a dia; a história principal pede combate nos pontos-chave, sempre com dificuldade acessível.

---

## 11. Estações e clima

O calendário é central para a rotina e segue a identidade climática do Cerrado — não só as quatro estações europeias.

- **Período chuvoso** (outubro a abril): plantio, rios cheios, tempestades.
- **Período seco** (maio a setembro): vegetação dourada, ipês florindo, queimadas a evitar, colheitas e festas.
- **Implementado (v0.4, dias oficiais desde a 1.4.8):** ano de 12 meses com nomes e dias reais (365 dias); começa em 1º de outubro; dia das 06:00 às 02:00.
- Variações: tempestades, neblina, ventos, dias ensolarados.
- Lugares e criaturas que **só aparecem em certas épocas** (gancho da história, §4.1).

---

## 12. Vila, NPCs e relacionamentos

Cada morador tem: nome · idade fictícia · profissão · casa · horários · preferências · diálogos · relações com outros NPCs · eventos especiais · **sotaque e costumes do interior** · histórias próprias (que o Silêncio pode apagar — §4.2).

Exemplos provisórios: Dona Alzira (cozinheira) · Seu Benedito (agricultor) · Toninho (ferreiro) · Mariana (veterinária) · João Pedro (pescador) · Helena (comerciante).

Relacionamentos: amizade, presentes, eventos, namoro e casamento, se o jogador quiser.

---

## 13. Eventos e festividades

Calendário de eventos inspirado em tradições reais, adaptadas ao vale:

- **Festa junina** — quadrilha, comidas típicas, barracas.
- **Folia de Reis** — cortejo pelas fazendas, cantoria, visita à propriedade do jogador.
- **Cavalhadas** — inspiradas nas de Pirenópolis.
- **Catira** — apresentações e mini-jogo de ritmo (proposta).
- **Torneios de pesca**.
- **Festividades fictícias** do vale (ex.: festa da safra do pequi).

As tradições reais são representadas com respeito e pesquisa; as fictícias podem misturar elementos livremente.

---

## 14. Culinária

Receitas iniciais: arroz com pequi · galinhada · empadão goiano · pamonha · curau · paçoca de carne · biscoito de queijo · doce de leite · receitas com baru · sucos de frutas do Cerrado.

Efeitos: recuperação de energia e vida · bônus de pesca, combate e coleta · resistência ao clima.

Receitas também são **conhecimento**: algumas foram esquecidas por causa do Silêncio e precisam ser redescobertas (proposta, §4.2).

---

## 15. Economia, profissões e progressão

| Caminho | Renda |
|---|---|
| Agricultor | Plantações e colheitas |
| Criador | Animais e derivados |
| Pescador | Peixes e torneios |
| Caçador | Recursos de caça permitidos |
| Minerador | Minérios e pedras |
| Artesão | Produtos processados |
| Explorador | Relíquias e descobertas |
| Aventureiro | Recompensas e missões |

Nenhuma atividade pode ser muito mais lucrativa que as outras.

Habilidades com níveis, desbloqueios e melhorias: agricultura, pesca, caça, mineração, combate, coleta, criação, artesanato. Progressão também por **equipamentos, recursos e melhoria da propriedade**.

---

## 16. Construção e personalização

Melhorar a casa · celeiros · galinheiros · oficinas · hortas · cercas · pontes · lagos artificiais · decoração interna · posicionar móveis e objetos. Construções modulares em grade.

---

## 17. Interface e controles

HUD limpo: vida, energia, dinheiro, relógio, dia e estação, atalho de ferramentas, inventário, mapa, diário, coleções, habilidades.

| Ação | Teclado/mouse | Celular | Controle |
|---|---|---|---|
| Andar | WASD / setas | Analógico virtual (esquerda) | Analógico / direcional |
| Atacar | Clique esquerdo | Botão de ataque (Fase 6) | X |
| Esquivar | Espaço | Botão de esquiva (Fase 6) | B |
| Interagir / ação contextual (capinar, regar, plantar, colher, abrir...) | E (segurar repete) | Botão verde | A |
| Inventário / Mapa / Diário | I / M / J | Botões no HUD (fases futuras) | Y / Back / — |
| Ferramentas | 1–9 | Barra tocável (Fase 2) | — |
| Menu | Esc | Botão ⏸ | Start |

Toque, teclado e controle disparam as mesmas ações; nenhum sistema depende do tipo de entrada. Todo controle novo precisa ter versão de toque.

---

## 18. Arquitetura técnica

Detalhes em `documentation/architecture.md`. Resumo:

- Godot 4 + GDScript, renderizador Compatibility (WebGL 2).
- Resolução base 640×360, pixel art com filtro nearest; aspect "expand"; escala inteira no PC e fracionária no celular.
- Tiles 16×16; sprites de personagem 32×32.
- Módulos independentes, sinais via `EventBus`, componentes reutilizáveis, dados em recursos (`data/`).
- Saves com versionamento e compatibilidade com saves antigos.
- Testes de integração automatizados; a publicação no GitHub Pages só acontece se todos passarem.
- Multiplayer fora do MVP, mas sem decisões que o impeçam (jogador criado por código, estado centralizado). Nada de rede antes de o single-player estar estável.

---

## 19. Roadmap

Cada fase termina com uma versão jogável publicada no navegador.

| Fase | Conteúdo | Status |
|---|---|---|
| 1 — Fundação | Projeto, personagem, 8 direções, câmera, fazenda provisória, colisões, interação | ✅ v0.1 |
| — Web e celular | Export web, controles de toque, publicação automática | ✅ v0.2 |
| 2 — Fazenda | Terreno, enxada, regador, plantio, colheita, inventário, baús, **save** | ✅ v0.3 (dormir provisório) |
| 3 — Tempo | Relógio, calendário, período chuvoso/seco, clima | ✅ v0.4 |
| 4 — Vila | Vila, NPCs, diálogos, lojas, economia | ✅ v0.5 |
| 5 — Atividades | Pesca, caça, criação de animais | ✅ v0.6 |
| 6 — Combate | Hack-and-slash, armas, inimigos, habilidades | ✅ v0.7 |
| 7 — Aventura | Mineração, ruínas, masmorras, missões, **início da trama do Silêncio** | ✅ v0.8 |
| 8 — Conteúdo | Culinária, eventos/festividades, relacionamentos, construção | ✅ v0.9 |
| 9 — Finalização | Testes, otimização, áudio, balanceamento, lançamento | ✅ v1.0 |

Prioridades permanentes: sensação de controle agradável · cara de Goiás (não fazenda genérica) · arquitetura bem estruturada desde o início.

---

## 20. Diretrizes de assets

| Asset | Referência |
|---|---|
| Personagem / NPCs | 32×32 px |
| Animais | 16×16 a 32×32 px |
| Itens | 16×16 ou 24×24 px |
| Armas | 16×24 ou 24×24 px |
| Tiles | 16×16 px |
| Efeitos | 16×16 a 32×32 px |
| Controles de toque | Legíveis em celular; área de toque mínima ~40 px na tela base |

Spritesheets com transparência, dimensões consistentes e documentação dos quadros. Assets provisórios marcados (`_placeholder`) e listados em `documentation/assets_provisorios.md`.

---

## 21. Regras para a IA desenvolvedora

1. Não desenvolver todos os sistemas de uma vez; trabalhar por fases.
2. Entregar sempre código executável e publicado.
3. Testar cada funcionalidade; corrigir erros antes de avançar.
4. Não remover funcionalidades nem **nenhum dos pilares do §2** sem autorização.
5. Preservar a compatibilidade dos saves.
6. Documentar as alterações (`documentation/changelog.md`).
7. Não criar funcionalidades fictícias só para dizer que estão prontas.
8. Informar limitações e dependências.
9. Não trocar sistemas funcionais por protótipos sem autorização.
10. Identificar claramente assets provisórios.
11. Todo conteúdo novo deve passar pelo teste da definição oficial (§0) e pelas regras de originalidade (§3) e de folclore (§4.5).
12. Toda mecânica nova funciona com teclado, controle **e toque**.

### 21.1 Critérios de entrega de cada fase

Funcionalidades implementadas · arquivos criados ou modificados · testes executados · erros conhecidos · limitações · próximas tarefas · link da versão publicada.

---

## 22. Visão final

Vale do Pequi deve ser um jogo em que dá para passar uma tarde inteira cuidando da fazenda, pescar no rio, preparar uma galinhada, conversar com os moradores e, se quiser, pegar o facão e descer numa caverna cheia de criaturas — sabendo que cada uma dessas coisas ajuda a manter vivas as histórias do vale.

---

## 23. Histórico

| Versão | Data | Mudanças |
|---|---|---|
| 1.0 | 16/11/2026 | Documento original |
| 1.1 | 17/11/2026 | Direção oficial revisada incorporada: definição oficial (§0); gênero "RPG de fazenda, aventura e hack-and-slash"; pilares não negociáveis (§2); tabela de identidade cultural e regras anti-cópia (§3); nova história "O Vale das Antigas Tradições", propriedade da família há gerações, **O Silêncio**, fazenda como lar, final com mundo aberto (§4); regras de uso do folclore (§4.5); regiões com papel definido e navegação no Rio das Araras (§6); pesca com locais secretos, clima e histórias de pescadores (§8); combate como parte central, estilos revisados e masmorras (§10); eventos e festividades (§13). Plataforma mantida como navegador desktop + celular (decisão de 16/11). Links de imagens de referência da v1.0 removidos. |
