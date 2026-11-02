
## Desenvolvimento

Este projeto roda no Docker: Elixir e Erlang não precisam estar instalados no host.

Depois de clonar, rode uma vez:

```bash
cp .env.example .env
git config core.hooksPath .githooks
```

Para subir os serviços e o servidor:

- `./scripts/dev.sh` abre um shell no container da aplicação; depois rode `mix setup` e `make app`
- Ou, pelo host com `make` instalado: `make up`, `make app.setup` e `make app`

Acesse [`localhost:__APP_HOST_PORT__`](http://localhost:__APP_HOST_PORT__) (`APP_HOST_PORT` no `.env`). Rode `make app.precommit` antes de cada commit:
ele compila com warnings como erros, formata o código e roda o Credo, o Sobelow, o `mix deps.audit`
(dependências com vulnerabilidades conhecidas) e os testes.
A CI (`.github/workflows/ci.yml`) roda as mesmas verificações a cada push e pull request.

As mensagens de commit seguem o formato `<gitmoji> <type>(<scope>): <description>` e são validadas
pelo `.githooks/commit-msg`. As convenções do projeto estão no `AGENTS.md`.

## Imagem de produção

O `Dockerfile` gera uma imagem de release (criada pelo `mix phx.gen.release --docker`);
o `Dockerfile.dev` é só para desenvolvimento. Para testá-la localmente (em `localhost:8080`):

```bash
docker build -t __APP__ .
docker run --rm -p 8080:4000 -e PHX_HOST=localhost \
  -e SECRET_KEY_BASE=$(docker exec __APP_CONTAINER__ mix phx.gen.secret) \
<!-- db:start -->
  -e DATABASE_URL=ecto://user:password@host/database \
<!-- db:end -->
  __APP__
```

<!-- db:start -->
Rode as migrations com a mesma imagem e as mesmas variáveis: `docker run ... __APP__ /app/bin/migrate`.

<!-- db:end -->
## Construção da aplicação

A aplicação é construída com um agente de IA (Claude Code), nos passos abaixo. O passo 1 é feito
uma vez, antes da primeira tela; os passos 2 a 7 se repetem a cada funcionalidade.

| Passo | Resultado | Skills do Matt Pocock | BMAD Method |
|---|---|---|---|
| 1. Design system | temas no `app.css`, `docs/ui/design-system.md`, `/dev/components` | peça à IA | peça à IA |
| 2. Domínio | `GLOSSARY.md`, `docs/adr/` | `/grill-with-docs` | product brief, arquitetura |
| 3. Spec | user stories | `/to-spec` | PRD, épicos e stories |
| 4. Telas | `docs/ui/screens.md`, `docs/ui/flows/` | `/screens` | `/screens` |
| 5. Protótipo | protótipos aprovados em `/dev/prototypes` | `/prototype-screen` | `/prototype-screen` |
| 6. Tickets | fatias verticais de trabalho | `/to-tickets` | as stories do passo 3 |
| 7. Implementação | código, testes e revisão | `/tdd`, `/implement-spec`, `/code-review` | desenvolvimento das stories, code review |

### Ferramentas

- **Claude Code**, aberto na pasta do projeto. O `CLAUDE.md` importa o `AGENTS.md` (as
  convenções do projeto, inclusive como rodar comandos no container), e as skills `/screens` e
  `/prototype-screen` ficam em `.claude/skills/`
- **Um método** para os passos 2, 3, 6 e 7:
  - **Skills do Matt Pocock** (mais leve, recomendado): no Claude Code, rode
    `/plugin install mattpocock-skills@claude-plugins-official` e depois, uma vez no projeto,
    `/setup-matt-pocock-skills`, para escolher onde ficam as specs e os tickets (issues do
    GitHub, com o CLI `gh` logado, ou arquivos locais)
  - **BMAD Method** (mais papéis e documentos, para projetos maiores): rode
    `npx bmad-method install` na pasta do projeto, no host (precisa de Node.js 20.12+,
    Python 3.10+ e [uv](https://docs.astral.sh/uv/)). Os nomes das skills mudam entre versões
    do BMAD: pergunte ao `bmad-help` qual roda cada passo
- **Web Design Guidelines** (opcional): `npx skills add vercel-labs/agent-skills --skill
  web-design-guidelines`, para revisar a acessibilidade e a usabilidade das telas. As regras
  são genéricas (algumas são sobre React): aplique só o que fizer sentido

### 1. Design system

Uma vez, antes da primeira tela (pode ser feito enquanto os passos 2 e 3 andam). As fontes já
estão instaladas (Figtree para a interface e os textos, Lato para os títulos); você escolhe as
cores e as formas, e a IA faz a configuração.

1. Abra o [gerador de temas do daisyUI](https://daisyui.com/theme-generator/). O projeto usa o
   daisyUI 5, e o gerador exporta temas do daisyUI 5
2. **Tema claro**: escolha um tema claro como ponto de partida e ajuste as cores (base,
   primary, secondary, accent, neutral, info, success, warning e error, cada uma com a sua cor
   de conteúdo), o raio (boxes, campos e seletores), os tamanhos, a borda e os efeitos
   (profundidade e ruído). Dê a ele o nome `light`
3. Copie o CSS dele (`Copy to clipboard` em "Add theme to your CSS file") e salve em
   `docs/ui/themes/light.css`
4. **Tema escuro**: parta de um tema escuro, mantenha o raio, os tamanhos, a borda e os efeitos
   do tema claro (só as cores mudam), dê o nome `dark` e salve o CSS em
   `docs/ui/themes/dark.css`
5. Peça à IA: "define the design system with the themes in `docs/ui/themes`". Ela copia as
   variáveis para o `assets/css/app.css` (você não edita esse arquivo), mede o contraste dos
   textos (perguntando antes de mudar qualquer cor), preenche o `docs/ui/design-system.md`,
   cria a galeria de componentes e faz o commit
6. Revise a galeria em
   [`localhost:__APP_HOST_PORT__/dev/components`](http://localhost:__APP_HOST_PORT__/dev/components)
   nos modos claro e escuro, e peça ajustes até aprová-la; então a IA marca o design system
   como `defined` e faz o commit

O gerador guarda os seus temas só no navegador, por isso os arquivos em `docs/ui/themes/` são o
registro do que foi exportado. Depois da configuração, o `app.css` é a fonte da verdade: peça
à IA as mudanças de cor seguintes, ou exporte novos temas e repita os passos 5 e 6.

### 2. Domínio

Defina o vocabulário e as decisões da funcionalidade antes de escrever os requisitos.

- **Matt Pocock**: `/grill-with-docs <a ideia da funcionalidade>`. A IA te entrevista em
  rodadas; cada pergunta vem com uma resposta recomendada (responda "sim" para aceitá-la, ou
  corrija). Os termos vão para o `GLOSSARY.md` e as decisões para `docs/adr/`
- **BMAD**: o product brief (e o PRD, para um produto novo) descrevem o problema, e o
  documento de arquitetura registra as decisões técnicas

### 3. Spec

O resultado é uma spec com user stories numeradas ("Como <usuário>, quero <funcionalidade>,
para <benefício>").

- **Matt Pocock**: `/to-spec` na mesma conversa. Ele não te entrevista de novo: escreve o
  problema, a solução, as user stories e as decisões de implementação e de testes, e publica
  tudo onde você escolheu no setup
- **BMAD**: o PRD é dividido em épicos e stories
- **À mão**: um arquivo em `docs/specs/` com as stories também serve

### 4. Telas

`/screens <spec>` (um arquivo, o número de uma issue ou um arquivo de story). A IA:

1. Completa os critérios de aceite Given/When/Then de cada story com interface (caminho
   principal, estado vazio e erros), perguntando o que a spec não diz
2. Propõe as telas (uma por rota), mostra quais stories cada uma cobre e recomenda
   `Prototype: required` ou `none` para cada; você decide
3. Depois da sua confirmação, escreve as entradas em `docs/ui/screens.md` (status `specified`)
   e, quando há duas ou mais telas, o fluxo em `docs/ui/flows/` (lugares, ações e um diagrama)

Com o BMAD, pule o workflow de UX design dele: o design system e este passo o substituem,
para que haja uma única fonte da verdade para as telas.

### 5. Protótipo

Só para as telas com `Prototype: required`. `/prototype-screen <tela>` (o nome ou a rota):

1. A IA constrói a tela com dados falsos em `/dev/prototypes`, com um estado por critério de
   aceite (preenchido, vazio, erro...), e muda o status dela para `prototyped`
2. Abra os links que ela te passar (a lista fica em
   [`localhost:__APP_HOST_PORT__/dev/prototypes`](http://localhost:__APP_HOST_PORT__/dev/prototypes)):
   a barra de ferramentas embaixo troca os estados e o tema, e "Mobile and desktop" mostra a
   tela nos dois tamanhos. Peça ajustes até ficar certo
3. Mude o status para `approved` em `docs/ui/screens.md`. Então a IA move o markup para um
   function component em `lib/__APP___web/components/`, que o LiveView real vai renderizar com
   os dados reais; o protótipo continua como o catálogo dos estados da tela

Só as telas aprovadas são implementadas.

### 6. Tickets

- **Matt Pocock**: `/to-tickets <spec>` divide a spec em fatias verticais (schema, context,
  LiveView e testes), cada uma com os tickets que a bloqueiam
- **BMAD**: as stories do passo 3 são os tickets; o sprint planning dele define a ordem

Os tickets que constroem uma tela apontam para a entrada dela em `docs/ui/screens.md`.

### 7. Implementação e revisão

- **Matt Pocock**: `/tdd <ticket>` para um ticket, ou `/implement-spec <spec>` para a spec
  inteira (subagentes em paralelo, numa branch de integração); `/code-review` antes do merge
- **BMAD**: o workflow de desenvolvimento dele para cada story, e depois o code review dele

Em todos os casos, cada critério de aceite ganha um teste de LiveView, o `make app.precommit`
passa antes de cada commit e a tela vai para `implemented`. Confira cada tela implementada no
navegador e marque-a como `reviewed` (se quiser, depois de
`/web-design-guidelines lib/__APP___web/live`). Faça o push para rodar a CI e comece a próxima
funcionalidade pelo passo 2.

## Saiba mais

- Site oficial do Phoenix: https://www.phoenixframework.org/
- Guias: https://phoenix.hexdocs.pm/overview.html
- Documentação: https://phoenix.hexdocs.pm
- Fórum: https://elixirforum.com/c/phoenix-forum
- Deploy: https://phoenix.hexdocs.pm/deployment.html
