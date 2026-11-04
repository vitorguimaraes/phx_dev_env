
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

Acesse [`localhost:__APP_HOST_PORT__`](http://localhost:__APP_HOST_PORT__) (`APP_HOST_PORT` no `.env`); a app só é acessível a partir da sua máquina, não da rede local.

### Verificações

- **Antes de cada commit**, `make app.precommit`: compila com warnings como erros, formata o
  código e roda o Credo, o Sobelow, o `mix deps.audit` (dependências com vulnerabilidades
  conhecidas), o `mix hex.audit` (dependências retiradas pelos autores) e os testes
- **A cada push e pull request**, a CI (`.github/workflows/ci.yml`) roda as mesmas verificações
  e procura segredos commitados por engano (gitleaks)
- **No push para o `master` e toda segunda-feira**, a CI gera a imagem de produção e procura
  vulnerabilidades nela (Trivy)
- **Toda semana**, o Dependabot (`.github/dependabot.yml`) abre um PR de atualização das
  dependências e das actions; a CI valida cada um

As mensagens de commit seguem o formato `<gitmoji> <type>(<scope>): <description>` e são validadas
pelo `.githooks/commit-msg`. As convenções do projeto estão no `AGENTS.md`. O que cada ferramenta faz está
em "Stack e ferramentas".

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
## Comandos do makefile

Os comandos `app.*` funcionam tanto pelo host (eles rodam via `docker compose exec`) quanto dentro
do container da aplicação.

- `make up` / `make down` (só no host): sobe / para os serviços
- `make shell` (só no host): abre um shell no container da aplicação
- `make app.setup`: baixa as dependências, cria o banco e gera os assets (`mix setup`)
- `make app`: sobe o servidor com um shell interativo (`iex -S mix phx.server`)
<!-- db:start -->
- `make app.migrate`: roda as migrations
<!-- db:end -->
- `make app.test`: roda os testes e formata o código. Aceita um arquivo:
  `make app.test test/my_test.exs`
- `make app.test.watch`: roda os testes a cada mudança nos arquivos
- `make app.precommit`: as verificações de antes do commit (veja "Verificações")
- `make app.credo`: roda o Credo no modo strict

## Docker

- `docker compose up -d` / `docker compose down`: sobe / para os serviços
- `docker exec -it __APP_CONTAINER__ sh`: abre um shell no container em execução
- `docker compose run --rm app_service sh`: roda um container novo com shell e o remove ao sair
<!-- db:start -->
- `docker compose down -v`: para os serviços e apaga o volume do banco (ele é recriado na
  próxima subida)

### Banco de dados

Para conectar um cliente (DBeaver, por exemplo), use os valores do `.env`:

- Host: `localhost`; porta: `DB_HOST_PORT` (acessível só a partir da sua máquina)
- Banco, usuário e senha: `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD`
<!-- db:end -->

## Stack e ferramentas

O que o projeto usa, para que serve e quando entra em ação. As versões exatas estão no `mix.lock`.

### Base

| Item | Para que serve | Quando é usado |
|---|---|---|
| Elixir e Phoenix 1.8 | linguagem e framework web | sempre |
| Phoenix LiveView | telas interativas renderizadas no servidor, sem uma SPA em JavaScript | em todas as telas; o JS próprio vai em colocated hooks |
| Bandit | servidor HTTP do Phoenix | ao rodar `make app` e na release |
<!-- db:start -->
| Ecto, `ecto_sql` e Postgrex | schemas, changesets, queries e migrations sobre o PostgreSQL | em todo acesso a dados |
| PostgreSQL 18 | banco de dados, no serviço `db_service` | em dev e test (container) e na CI (serviço do job) |
| `bcrypt_elixir` (com `--auth`) | hash das senhas da autenticação gerada | ao cadastrar e ao fazer login |
<!-- db:end -->
| Swoosh | envio de e-mails; em dev, as mensagens aparecem em `/dev/mailbox` | nos e-mails da autenticação e nos que você criar |
| Req | cliente HTTP | ao chamar APIs externas; o Swoosh o usa em produção |
| Gettext | traduções; o locale padrão é `pt_BR`, com os erros do Ecto traduzidos | em todo texto da interface |
| Jason | JSON | nas APIs, nos logs e no LiveView |
| Telemetry e LiveDashboard | métricas da app em `/dev/dashboard` | em dev, para investigar desempenho |
| `dns_cluster` | conecta os nós da release por DNS | só em produção, se houver mais de um nó |

### Interface

| Item | Para que serve | Quando é usado |
|---|---|---|
| Tailwind CSS | estilos por classes utilitárias, pelo binário standalone (sem Node) | ao gerar os assets (`mix setup`, `make app`) |
| daisyUI 5 | componentes e temas sobre o Tailwind; vem do GitHub, fixado por tag no `mix.lock` | nos componentes; os temas vêm do gerador do daisyUI (passo 1) |
| esbuild | empacota o `assets/js`, também sem Node | ao gerar os assets |
| Lucide | ícones (`<.icon name="lucide-...">`) no lugar dos Heroicons, inclusive nos geradores `mix phx.gen.*` | em toda tela com ícones |
| Figtree e Lato | fontes da interface e dos títulos, servidas pelo próprio projeto (sem Google Fonts, o que mantém a CSP restrita) | sempre |
| `phoenix_live_reload` | recarrega o navegador quando um arquivo muda | em dev |
| `/dev/components` e `/dev/prototypes` | a galeria do design system e os protótipos das telas, compilados só em dev e test | nos passos 1 e 5 |

### Qualidade e testes

| Item | Para que serve | Quando é usado |
|---|---|---|
| ExUnit, `Phoenix.LiveViewTest` e LazyHTML | testes de unidade e de LiveView; o LazyHTML lê o HTML renderizado | `make app.test`, no `precommit` e na CI |
| `mix_test_watch` | roda os testes a cada mudança | `make app.test.watch` |
| `compile --warnings-as-errors` | transforma warnings em erros, inclusive funções que não existem ou foram descontinuadas | no `precommit` e na CI |
| `mix format` | formatação padrão do Elixir | no `precommit` e no `make app.test` |
| Credo | consistência e legibilidade do código | no `precommit` e na CI; `make app.credo` roda no modo strict |
| `.githooks/commit-msg` | valida o formato `<gitmoji> <type>(<scope>): <description>` | a cada commit |

### Segurança

| Item | Para que serve | Quando é usado |
|---|---|---|
| Sobelow | análise estática de segurança do Phoenix: XSS, SQL injection, configurações inseguras | no `precommit` e na CI; as vulnerabilidades de dependências ficam com o `deps.audit` |
| `mix deps.audit` (mix_audit) | confere o `mix.lock` contra a base de vulnerabilidades conhecidas | no `precommit` e na CI (precisa de internet) |
| `mix hex.audit` | avisa sobre pacotes retirados pelos autores | no `precommit` e na CI |
| Content-Security-Policy com nonce | só roda script inline com o nonce da requisição; bloqueia `onclick=` e `javascript:` | em toda resposta HTML (`plugs/content_security_policy.ex`) |
| gitleaks | procura segredos commitados no histórico do git; o `.gitleaks.toml` libera só o `secret_key_base` de dev e test | job `secrets` da CI, a cada push e PR |
| Trivy | procura vulnerabilidades altas e críticas, com correção publicada, na imagem de produção | job `image` da CI, no push para o `master` e toda segunda-feira |
| `apt-get upgrade` no `Dockerfile` | atualiza os pacotes do Debian da imagem de produção, que vem fixada numa data | a cada build da imagem |
| Dependabot | PRs semanais de atualização das dependências mix e das actions. Não atualiza as imagens do gitleaks e do Trivy, que estão fixadas no `ci.yml` | toda semana |
| Portas em `127.0.0.1` | a app e o banco só aceitam conexões desta máquina | sempre, em dev |
| `/security-review` | revisão do diff atrás do que as ferramentas não pegam: autorização, queries sem escopo, dados sensíveis em log | antes do PR, quando o diff toca `lib/`, `config/` ou as migrations (passo 8) |

### CI e entrega

| Item | Para que serve | Quando é usado |
|---|---|---|
| GitHub Actions: job `checks` | roda o equivalente ao `mix precommit` num container `elixir:1.19`, com cache de `deps/` e `_build/` | a cada push e PR |
<!-- db:start -->
| Serviço `postgres:18-alpine` no job `checks` | o banco dos testes na CI | a cada push e PR |
<!-- db:end -->
| GitHub Actions: jobs `secrets` e `image` | o gitleaks; o build da release com o Trivy | `secrets` a cada push e PR; `image` no `master` e toda semana |
| `Dockerfile` (`mix phx.gen.release --docker`) | imagem de produção com a release e o `bin/server` | no deploy e no job `image` |
| `Dockerfile.dev` e `docker-compose.yaml` | imagem e serviços de desenvolvimento, com o usuário do host (os arquivos ficam no seu usuário) | sempre, em dev |

## Construção da aplicação

A aplicação é construída com um agente de IA (Claude Code) e as
[skills do Matt Pocock](https://github.com/mattpocock/skills), nos passos abaixo. O passo 1 é
feito uma vez, antes da primeira tela; os passos 2 a 9 se repetem a cada funcionalidade (a
partir do 4, quando a spec já vem pronta).

[![Fluxo de desenvolvimento: entradas, portão, skills de cada etapa e entrega](docs/fluxo-de-desenvolvimento.png)](docs/fluxo-de-desenvolvimento.html)

A versão interativa, com tema claro e escuro, zoom e os cards das pastas, dos templates e das verificações, está em [`docs/fluxo-de-desenvolvimento.html`](docs/fluxo-de-desenvolvimento.html) (abra o arquivo no navegador; o GitHub mostra só o código-fonte).

Para ver o fluxo aplicado a uma funcionalidade inteira, com as skills, as bibliotecas e as verificações de cada etapa, leia o [exemplo de uso](docs/exemplo-de-uso.md): uma loja em que os clientes acompanham os próprios pedidos, do `./run.sh` ao merge.

### Ferramentas

- **Claude Code**, aberto na pasta do projeto. As skills do projeto ficam em `.claude/skills/`;
  o `/security-review` já vem com o Claude Code
- **Skills do Matt Pocock**: no Claude Code, rode
  `/plugin install mattpocock-skills@claude-plugins-official` e depois, uma vez no projeto,
  `/setup-matt-pocock-skills`, para escolher onde ficam as specs e os tickets (issues do
  GitHub, com o CLI `gh` logado, ou arquivos locais)
- **Web Design Guidelines** (opcional): `npx skills add vercel-labs/agent-skills --skill
  web-design-guidelines`, para revisar a acessibilidade e a usabilidade das telas. As regras
  são genéricas (algumas são sobre React): aplique só o que fizer sentido

| Skill | Origem | Para que serve | Quando é usada |
|---|---|---|---|
| `/design-system` | projeto | aplica os temas do daisyUI, mede o contraste e cria a galeria | passo 1 e a cada mudança de cores |
| `/grill-with-docs` | Matt Pocock | entrevista sobre a ideia; grava o vocabulário e as decisões | passo 2 |
| `/research` | Matt Pocock | lê fontes em segundo plano e devolve um arquivo com citações | passo 2, quando uma pergunta depende de documentação |
| `/to-questionnaire` | Matt Pocock | escreve as perguntas para quem tem a resposta | passo 2, quando ela está com outra pessoa |
| `/to-spec` | Matt Pocock | escreve a spec com as user stories | passo 3 |
| `/screens` | projeto | critérios de aceite, telas em `docs/ui/screens.md` e fluxos | passo 4 |
| `/prototype-screen` | projeto | protótipo de uma tela com dados falsos, um estado por critério | passo 5 |
| `/to-tickets` | Matt Pocock | fatia a spec em tracer bullets, com os bloqueios | passo 6 |
| `/implement` e `/implement-spec` | Matt Pocock | implementam um ticket, ou a spec com subagentes | passo 7 |
| `/tdd` | Matt Pocock | um teste, o mínimo de código, o próximo teste | dentro do passo 7, ou avulso |
| `/code-review` | Matt Pocock | convenções, fidelidade à spec e refatoração | fim do passo 7 |
| `/security-review` | Claude Code | revisão de segurança do diff | passo 8 |
| `/pr` | Matt Pocock | escreve o corpo do PR com as evidências e o risco | passo 8 |
| `/retro` | Matt Pocock | melhorias no ambiente do agente | passo 9 |
| `/next-step` | projeto | lê o estado do projeto e diz qual skill rodar | a qualquer momento, sobretudo ao retomar |
| `/diagnosing-bugs` | Matt Pocock | laço de diagnóstico para bugs difíceis | quando surgir um bug assim |
| `/ask-matt` | Matt Pocock | indica qual skill do Matt Pocock usar | na dúvida |
| `/web-design-guidelines` | Vercel (opcional) | revisa a acessibilidade e a usabilidade | antes de marcar uma tela como `reviewed` |

O `CLAUDE.md` importa o `AGENTS.md`, lido no início de cada conversa. Ele junta as usage rules
do Phoenix (Elixir, Phoenix, Ecto, HEEx e LiveView, escritas pela equipe do Phoenix para a versão
instalada) às convenções do projeto: Docker, commits, testes, UI e segurança. Uma das convenções
manda a IA ler a documentação em `deps/` antes de usar uma API. Ela evita código de versões
antigas sem precisar de um MCP de documentação, e foi validada contra o Tidewave num teste A/B.

### Por onde começar

Há três entradas, conforme o que você já tem em mãos. A e B (ou C) podem andar em paralelo,
em conversas separadas, e se encontram antes do protótipo: nenhuma tela é prototipada nem
construída antes de o design system estar `defined` e de a tela estar listada em
`docs/ui/screens.md`.

- **A. Um design system**: os temas (ou um Markdown de design system) exportados do
  [gerador de temas do daisyUI](https://daisyui.com/theme-generator/). Salve em
  `docs/ui/themes/` e rode `/design-system` (passo 1)
- **B. Uma ideia de funcionalidade**: `/grill-with-docs <a ideia>`, `/to-spec` e
  `/screens <spec>`, na mesma conversa (passos 2 a 4)
- **C. Uma spec pronta** (escrita fora deste fluxo, num arquivo ou numa issue): `/screens <spec>`
  numa conversa nova (passo 4). Sem `GLOSSARY.md`, a IA recomenda um `/grill-with-docs <spec>`
  antes, para fixar o vocabulário

```
 A. design system                 B. ideia                      C. spec pronta
 docs/ui/themes/                  /grill-with-docs                    │
      │                           /to-spec                            │
 /design-system                       │                               │
 /dev/components aprovado             └──────────► /screens ◄──────────┘
 status `defined`                                 telas `specified`
      │                                                 │
      └──────────────────────┬──────────────────────────┘
                             ▼
              /prototype-screen <tela>   (cada tela `required`, até `approved`)
                             ▼
              /to-tickets <spec>         (tracer bullets, começando pelo esqueleto)
                             ▼
              /implement <ticket>  ou  /implement-spec <spec>   (/tdd, /code-review)
                             ▼
              tela no navegador → `reviewed`
                             ▼
              /security-review → /pr → /retro → próxima ideia (B)
```

Em qualquer momento, `/next-step` lê o estado do projeto (o design system, as specs, o
`docs/ui/screens.md`, os tickets e o git), aponta o que estiver fora do fluxo e diz qual skill
rodar agora. Use-o ao retomar o projeto depois de uma pausa.

### Passos

| Passo | Sessão | Skill | Resultado |
|---|---|---|---|
| 1. Design system | uma vez | `/design-system` | temas no `app.css`, `docs/ui/design-system.md`, `/dev/components` |
| 2. Domínio | uma só, nos passos 2 a 4 | `/grill-with-docs` | `GLOSSARY.md`, `docs/adr/` |
| 3. Spec | a mesma | `/to-spec` | spec com user stories |
| 4. Telas | a mesma (nova, na entrada C) | `/screens` | critérios de aceite na spec, `docs/ui/screens.md`, `docs/ui/flows/` |
| 5. Protótipo | uma por tela | `/prototype-screen` | protótipos aprovados em `/dev/prototypes` |
| 6. Tickets | nova | `/to-tickets` | tracer bullets, começando pelo esqueleto, com os seus bloqueios |
| 7. Implementação | uma por ticket | `/implement` ou `/implement-spec` | código, testes e revisão |
| 8. Pull request | a mesma do passo 7 | `/security-review` e `/pr` | o PR, e a CI verde |
| 9. Retrospectiva | a mesma do passo 7 | `/retro` | melhorias no ambiente do agente |

Os passos 2 a 4 rodam numa única conversa, sem `/clear` nem `/compact`: a entrevista, a spec e
as telas partem do mesmo raciocínio. A spec só está bem definida depois do passo 4, e só então
as telas são prototipadas. A partir dali, cada passo começa numa conversa nova (`/clear`),
porque tudo o que ele precisa já está salvo: a spec, o `GLOSSARY.md`, os ADRs, o
`docs/ui/screens.md` e os protótipos aprovados.

### 1. Design system

Uma vez, antes da primeira tela (pode ser feito enquanto os passos 2 a 4 andam, numa conversa
separada). As fontes já estão instaladas (Figtree para a interface e os textos, Lato para os
títulos); você escolhe as cores e as formas, e a IA faz a configuração.

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
5. Rode `/design-system`. A IA copia as variáveis para o `assets/css/app.css` (você não edita
   esse arquivo), mede o contraste dos textos (perguntando antes de mudar qualquer cor),
   preenche o `docs/ui/design-system.md`, cria a galeria de componentes e faz o commit
6. Revise a galeria em
   [`localhost:__APP_HOST_PORT__/dev/components`](http://localhost:__APP_HOST_PORT__/dev/components)
   nos modos claro e escuro, e peça ajustes até aprová-la; então a IA marca o design system
   como `defined` e faz o commit

Se em vez dos dois CSS você tiver um Markdown de design system (do gerador ou escrito à mão,
com os temas e, opcionalmente, a identidade, o papel de cada cor e o uso dos componentes),
salve-o em `docs/ui/themes/` e rode `/design-system <arquivo>`: a IA extrai os temas para
`light.css` e `dark.css`, usa o resto para preencher o `docs/ui/design-system.md` e pergunta
quando algo contraria as convenções do `AGENTS.md` (outras fontes, cores fora do tema). Com um
tema só, ela propõe o outro e espera a sua confirmação.

O gerador guarda os seus temas só no navegador, por isso os arquivos em `docs/ui/themes/` são o
registro do que foi exportado. Depois da configuração, o `app.css` é a fonte da verdade: peça
as mudanças de cor seguintes ao `/design-system`, ou exporte novos temas e repita os passos 5
e 6.

### 2. Domínio

Defina o vocabulário e as decisões da funcionalidade antes de escrever os requisitos:
`/grill-with-docs <a ideia da funcionalidade>`. A IA te entrevista em rodadas; cada pergunta
vem com uma resposta recomendada (responda "sim" para aceitá-la, ou corrija). Os termos vão
para o `GLOSSARY.md` e as decisões para `docs/adr/`.

Quando uma pergunta depende de leitura (a documentação de uma biblioteca, uma API externa),
peça um `/research <a pergunta>`: um agente lê as fontes em segundo plano e deixa um arquivo
com as citações, que volta para a entrevista. Quando a resposta está com outra pessoa (um
cliente, alguém do negócio), `/to-questionnaire` escreve as perguntas para ela.

### 3. Spec

`/to-spec`, na mesma conversa. Ele não te entrevista de novo: combina com você onde ficam os
testes (as seams) e escreve o problema, a solução, as user stories numeradas ("Como
<usuário>, quero <funcionalidade>, para <benefício>") e as decisões de implementação e de
testes, e publica tudo onde você escolheu no setup.

### 4. Telas

`/screens <spec>`, ainda na mesma conversa (ou numa conversa nova, para uma spec escrita fora
deste fluxo: a entrada C). A IA:

1. Completa os critérios de aceite Given/When/Then de cada story com interface (caminho
   principal, estado vazio e erros), perguntando o que a spec não diz, e os grava na spec
2. Propõe as telas (uma por rota), mostra quais stories cada uma cobre e recomenda
   `Prototype: required` ou `none` para cada; você decide
3. Depois da sua confirmação, escreve as entradas em `docs/ui/screens.md` (status `specified`)
   e, quando há duas ou mais telas, o fluxo em `docs/ui/flows/` (lugares, ações e um diagrama)

Com isso a spec está bem definida. Rode `/clear` antes do próximo passo.

### 5. Protótipo

Só para as telas com `Prototype: required`, uma conversa por tela. `/prototype-screen <tela>`
(o nome ou a rota):

1. A IA constrói a tela com dados falsos em `/dev/prototypes`, com um estado por critério de
   aceite (preenchido, vazio, erro...), e muda o status dela para `prototyped`
2. Abra os links que ela te passar (a lista fica em
   [`localhost:__APP_HOST_PORT__/dev/prototypes`](http://localhost:__APP_HOST_PORT__/dev/prototypes)):
   a barra de ferramentas embaixo troca os estados e o tema, e "Mobile and desktop" mostra a
   tela nos dois tamanhos. Peça ajustes até ficar certo. Se um ajuste mudar uma regra (um
   estado novo, outro texto de erro, outro dado na tela), a IA atualiza os critérios na spec e
   a entrada em `docs/ui/screens.md` antes da aprovação: o protótipo nunca decide uma regra
   sozinho
3. Mude o status para `approved` em `docs/ui/screens.md`. Então a IA move o markup para um
   function component em `lib/__APP___web/components/`, que o LiveView real vai renderizar com
   os dados reais; o protótipo continua como o catálogo dos estados da tela. Ela também sugere
   como os estados viram tickets (o principal é o esqueleto), ponto de partida do passo 6

Só as telas aprovadas são implementadas, e os tickets só são criados depois que todas as telas
`required` da spec estão aprovadas.

### 6. Tickets

Numa conversa nova, `/to-tickets <spec>`. A IA relê a spec, o `docs/ui/screens.md` e os
protótipos aprovados e propõe os tickets, cada um com os tickets que o bloqueiam; você ajusta
o tamanho e os bloqueios até aprovar, e ela os publica.

Cada ticket é um **tracer bullet**: um caminho estreito, mas completo, por todas as camadas
de que precisa (migration, schema, função do context, rota e LiveView com o componente
aprovado, e os testes de LiveView dos seus critérios), que entra com o `make app.precommit`
verde e já aparece no navegador. Nada de fatiar por camada (um ticket para os schemas, outro
para os LiveViews): assim nada funciona até o último ticket, e cada um depende do trabalho
dos outros.

- O primeiro ticket da spec é o **esqueleto**: o caminho principal da tela central, com a
  menor função do context que a alimenta. Ele bloqueia os outros tickets da tela
- Os outros tickets alargam o caminho, um grupo de critérios de aceite por vez. Os estados do
  protótipo vêm desses critérios, então eles são o roteiro natural:

| Ticket | Critérios | O que dá para ver |
|---|---|---|
| 1. Esqueleto | caminho principal (`filled`) | a lista real de pedidos em `/orders` |
| 2. Estado vazio | `empty` | "Você ainda não tem pedidos" |
| 3. Criar pedido | a ação e os erros de validação (`error`) | o formulário salvando e mostrando os erros |
| 4. Autorização | `not_allowed` | outro usuário não vê os pedidos |

Cada ticket aponta para a entrada da tela em `docs/ui/screens.md`, lista os critérios que
fecha e os estados do protótipo com que a tela real é comparada
(`/dev/prototypes/<rota>?state=<estado>`). Todo critério fica em exatamente um ticket.

### 7. Implementação e revisão

Duas formas, das quais você escolhe uma:

- **Um ticket por vez** (recomendado para acompanhar cada passo): `/implement <ticket>`, com
  `/clear` entre um ticket e outro, começando pelos que não têm bloqueio. A IA constrói o
  ticket com `/tdd` (um teste numa seam combinada, o mínimo de código que o faz passar, e o
  próximo teste; o primeiro ciclo é o tracer bullet do ticket), roda os testes, faz o
  `/code-review` (as convenções do projeto, a fidelidade à spec e a refatoração) e o commit
- **A spec inteira**: `/implement-spec <spec>`. Subagentes trabalham em paralelo os tickets já
  desbloqueados, numa branch de integração, e um `/code-review` e um `/security-review` revisam
  tudo no fim

Em todos os casos, cada critério de aceite ganha um teste de LiveView e o `make app.precommit`
passa antes de cada commit. Um ticket está pronto quando os testes dos seus critérios passam e
a rota real fica igual aos estados do protótipo que ele lista: a IA não vê a tela, então essa
comparação é sua, no navegador. A tela vai para `implemented` quando fecha o último ticket
dela; confira-a no navegador e marque-a como `reviewed` (se quiser, depois de
`/web-design-guidelines lib/__APP___web/live`).

Para um bug difícil, use `/diagnosing-bugs`; para um comportamento avulso, sem spec, `/tdd`.

### 8. Pull request

Peça o PR (ou faça o push direto, se trabalhar sem PRs). Antes, quando a mudança toca código
(`lib/`, `config/` ou as migrations), a IA roda o `/security-review`, que procura no diff o que
as ferramentas automáticas não pegam (autorização errada, query sem o escopo do usuário,
upload sem validação, dados sensíveis em log), e corrige o que ele encontrar. Então ela usa a
skill `/pr` sozinha: o corpo mostra a mudança no menor formato visual possível, as evidências
de que ela funciona e o risco do merge. A CI roda as mesmas verificações do
`make app.precommit` e procura segredos commitados (gitleaks).

### 9. Retrospectiva

`/retro`, na conversa da implementação, antes do `/clear`. A IA aponta o que travou o agente e
propõe melhorias no ambiente, não no código: verificações automáticas (Credo, hooks, CI) para os
erros mecânicos, regras no `AGENTS.md` para os de julgamento. Aplique as que fizerem sentido e
comece a próxima funcionalidade pelo passo 2.

## Saiba mais

- Site oficial do Phoenix: https://www.phoenixframework.org/
- Guias: https://phoenix.hexdocs.pm/overview.html
- Documentação: https://phoenix.hexdocs.pm
- Fórum: https://elixirforum.com/c/phoenix-forum
- Deploy: https://phoenix.hexdocs.pm/deployment.html
