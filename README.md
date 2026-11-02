![Elixir](https://img.shields.io/badge/elixir-%234B275F.svg?style=for-the-badge&logo=elixir&logoColor=white)
![Phoenix](https://img.shields.io/badge/Phoenix%20Framework-FD4F00?style=for-the-badge&logo=phoenixframework&logoColor=fff)
![Postgres](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)
![daisyUI](https://img.shields.io/badge/daisyUI-5A0EF8?style=for-the-badge&logo=daisyui&logoColor=white)

# Phoenix Development Environment

Configure o seu ambiente sem instalar Elixir e Phoenix localmente.
Assim, você não precisa baixar, instalar e configurar dependências, nem criar e construir uma imagem Docker à mão para começar um projeto novo.

## Tecnologias

O template usa:

- Docker
- Docker Compose
- Shell script

O projeto gerado usa:

- Elixir e Phoenix, com LiveView
- PostgreSQL (opcional, com Ecto)
- Tailwind CSS e daisyUI
- GitHub Actions

## Primeiros passos

Para criar o projeto:

- Instale o [`docker`](https://docs.docker.com/engine/install/) e o [`docker compose`](https://docs.docker.com/compose/install/)
- Opcionalmente, instale o `make`, para rodar os [comandos do makefile](#7-comandos-do-makefile) pelo host (`sudo apt install make` no Ubuntu)

> No Ubuntu, o `run.sh` instala o Docker automaticamente se ele não estiver instalado (veja o [`docker.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker.sh)).  
> Em outros sistemas, instale o Docker manualmente antes de rodá-lo.

Para construir a aplicação (veja o [passo 6](#6-construir-a-aplicação)):

- [Claude Code](https://claude.com/claude-code), o agente de IA que segue as convenções do projeto
- Opcionalmente, o CLI [`gh`](https://cli.github.com/), para criar o repositório no GitHub e manter as specs e os tickets em issues do GitHub
- Só para o BMAD Method: Node.js 20.12+, Python 3.10+ e [uv](https://docs.astral.sh/uv/)

## Como usar

### 1. Clone o repositório

No terminal, use o `git` para clonar o repositório.
> git clone <https://github.com/VitorGuimaraes/phx_dev_env.git>

### 2. Configure as variáveis do projeto no `.env`

No `.env` ficam as variáveis do Postgres e algumas variáveis usadas no [`docker-compose.yaml`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker-compose.yaml).
Os valores padrão funcionam como estão: o `run.sh` define sozinho os nomes, as portas e os ids de usuário.

### 3. Rode o script

> ./run.sh

Ele pergunta o nome do projeto e se você quer usar Ecto, UUID (`--binary-id`) e autenticação (`mix phx.gen.auth`).
As respostas também podem ser passadas como opções (`./run.sh --help`), por exemplo:

> ./run.sh --name my_app --ecto --uuid --auth

Depois, ele:

- cria o projeto Phoenix pelo container, com os arquivos no seu usuário;
- configura o `config/dev.exs` e o `config/test.exs` para usar o banco do `.env` (sem Ecto, o serviço e as variáveis do banco são removidos);
- opcionalmente, gera a autenticação com páginas em LiveView (`mix phx.gen.auth Accounts User users --live`);
- renomeia a pasta atual com o nome do projeto;
- move o `dev.sh` para `scripts/`;
- cria o `.env.example` e adiciona o `.env` ao `.gitignore`;
- adiciona as convenções do projeto ao `AGENTS.md` (Docker, commits, testes, UI e idioma) e cria o `CLAUDE.md`, que o importa;
- adiciona um hook `commit-msg` que valida mensagens no formato `<gitmoji> <type>(<scope>): <description>`;
- define `pt_BR` como locale padrão, com os erros de validação do Ecto traduzidos;
- troca os Heroicons pelos ícones do [`Lucide`](https://lucide.dev/icons), inclusive nos geradores `mix phx.gen.*` (veja `templates/icons/`);
- adiciona [`credo`](https://github.com/rrrene/credo), [`sobelow`](https://github.com/nccgroup/sobelow), [`mix_audit`](https://github.com/mirego/mix_audit) e [`mix_test_watch`](https://github.com/lpil/mix-test.watch) como dependências de dev/test, com o Credo, o Sobelow e o `mix deps.audit` no `mix precommit`;
- define uma Content-Security-Policy com um nonce por requisição (`templates/csp/`), para que scripts inline só rodem com o nonce;
- adiciona uma CI no GitHub Actions (`.github/workflows/ci.yml`) que roda as verificações do `mix precommit` a cada push e pull request;
- gera uma imagem de release para produção (`Dockerfile`, `mix phx.gen.release --docker`); a imagem de desenvolvimento é o `Dockerfile.dev`;
- dá aos containers, à imagem e à rede o nome do projeto e escolhe portas livres no host, para que vários projetos rodem ao mesmo tempo (as portas ficam registradas em `~/.config/phx_dev_env/projects`, então um projeto parado mantém as suas portas);
- instala as fontes Figtree (interface e textos) e Lato (títulos), servidas pelo próprio projeto (veja `templates/fonts/`);
- adiciona o `docs/ui/design-system.md` (definido na primeira tarefa de UI do projeto), o `docs/ui/screens.md` (inventário de telas) e o `docs/ui/themes/`, para os temas exportados do daisyUI;
- prepara os protótipos de telas em `/dev/prototypes` (LiveViews com dados falsos em `dev/`, compiladas só em dev e test, fora da release; veja `templates/prototypes/`);
- adiciona as skills `/screens` e `/prototype-screen` para o Claude Code (`.claude/skills/`), que transformam as user stories de uma spec em telas e as telas em protótipos;
- substitui o `README.md` do projeto por um em português, com as instruções de desenvolvimento e os passos de construção da aplicação;
- inicia um novo repositório git.

Se o Docker for instalado pelo script, saia da sessão e entre de novo (para aplicar o grupo `docker`) e rode o `./run.sh` outra vez.  
Veja o [`run.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/run.sh) para mais detalhes.  

### 4. Comece a desenvolver

Vá para a pasta do projeto, suba os serviços e abra um shell no container da aplicação  
> cd ../<project_name>  
> ./scripts/dev.sh

Dentro do container, baixe as dependências, crie o banco (só com Ecto), gere os assets e suba o servidor  
> make app.setup  
> make app

Ou, se você tem o `make` instalado, faça o mesmo pelo host (o `make app.setup` só na primeira vez)  
> make up  
> make app.setup  
> make app

Acesse `http://localhost:<APP_HOST_PORT>` (mostrado no fim do `run.sh` e definido no `.env`, padrão `4000`) e confira a página do Phoenix.  

### 5. Publique no GitHub

O `run.sh` inicia o repositório git sem commits. Faça o primeiro commit e o push, para que a CI rode a cada push:

> git add .  
> git commit -m "🔧 chore: create the project"

Com o CLI `gh` (logado com `gh auth login`):
> gh repo create <project_name> --private --source . --push

Ou crie um repositório vazio no GitHub (sem README, licença ou `.gitignore`) e faça o push para ele:
> git remote add origin git@github.com:<user>/<project_name>.git  
> git push -u origin HEAD

A primeira execução da CI leva alguns minutos (as seguintes usam o cache); acompanhe na aba Actions do repositório.

### 6. Construir a aplicação

A aplicação é construída com o Claude Code, aberto na pasta do projeto, em sete passos. Eles estão detalhados em "Construção da aplicação" no `README.md` do projeto (gerado a partir do [`templates/README.development.md`](templates/README.development.md)):

1. **Design system** (uma vez, antes da primeira tela): você cria um tema claro e um escuro no [gerador de temas do daisyUI](https://daisyui.com/theme-generator/), salva os dois em `docs/ui/themes/` e pede à IA para definir o design system; ela aplica os temas, mede o contraste e cria uma galeria de componentes para você aprovar
2. **Domínio**: uma entrevista que registra o vocabulário da funcionalidade no `GLOSSARY.md` e as decisões em `docs/adr/`
3. **Spec**: o problema, a solução e as user stories numeradas
4. **Telas**: `/screens <spec>` completa os critérios de aceite Given/When/Then e lista as telas em `docs/ui/screens.md` (e o fluxo em `docs/ui/flows/`, para duas ou mais telas); você decide quais são prototipadas primeiro
5. **Protótipo**: `/prototype-screen <tela>` constrói essas telas com dados falsos em `/dev/prototypes`, para você aprovar no navegador antes do resto da funcionalidade
6. **Tickets**: a spec é dividida em fatias verticais
7. **Implementação e revisão**: guiada por testes, com o `make app.precommit` antes de cada commit e a revisão de cada tela

Os passos 2, 3, 6 e 7 usam um de dois métodos: as [skills do Matt Pocock](https://github.com/mattpocock/skills) (mais leve, recomendado) ou o [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) (mais papéis e documentos, para projetos maiores). Os passos 1, 4 e 5 são iguais nos dois.

### 7. Comandos do makefile

Os comandos `app.*` funcionam tanto pelo host (eles rodam via `docker compose exec`) quanto dentro do container da aplicação.

- `make up` / `make down` (só no host)  
   sobe / para os serviços.

- `make shell` (só no host)  
   abre um shell no container da aplicação.

- `make app.setup`  
   baixa as dependências, cria o banco e gera os assets (`mix setup`).

- `make app`  
   sobe o servidor com um shell interativo (`iex -S mix phx.server`).

- `make app.migrate`  
   roda as migrations.

- `make app.test`  
   roda os testes e formata o código. Você pode passar um arquivo: `make app.test test/my_test.exs`

- `make app.precommit`  
   compila com warnings como erros, remove dependências não usadas, formata, roda o Credo, o Sobelow, o `mix deps.audit` e os testes (`mix precommit`). Rode antes de cada commit.

- `make app.test.watch`  
   roda os testes a cada mudança nos arquivos ([`mix_test_watch`](https://github.com/lpil/mix-test.watch)).

- `make app.credo`  
   roda o [`Credo`](https://github.com/rrrene/credo) no modo strict.

### 8. Testando o template

O `e2e.sh` testa o `run.sh` de ponta a ponta: cria um projeto a partir de uma cópia temporária desta pasta (incluindo as mudanças não commitadas), confere os arquivos gerados, roda o `mix setup`, o `mix precommit` e o servidor nos containers reais, e remove tudo no fim.

> ./e2e.sh                 # com Ecto  
> ./e2e.sh --auth --release   # com autenticação, gerando também a imagem de produção  
> ./e2e.sh --no-ecto  
> ./e2e.sh --keep          # mantém o projeto para inspecioná-lo

### 9. Conectando no DBeaver

Host: `localhost`  
Porta: DB_HOST_PORT definida no `.env` (padrão `6032`; acessível só a partir da sua máquina)  
Banco: POSTGRES_DB definido no `.env`  
Usuário: POSTGRES_USER definido no `.env`  
Senha: POSTGRES_PASSWORD definida no `.env`  

### 10. Gerenciando imagens e containers

- `docker compose up -d`  
   sobe os serviços.

- `docker compose down`  
   para os serviços.

- `docker exec -it $APP_CONTAINER_NAME sh`  
   abre um shell num container em execução.

- `docker compose run --rm app_service sh`  
   roda um novo container com shell e o remove ao sair.

- `docker compose down -v`  
   para os serviços e apaga o volume do banco (o banco é recriado na próxima subida).
