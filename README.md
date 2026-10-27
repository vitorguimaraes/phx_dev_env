![Elixir](https://img.shields.io/badge/elixir-%234B275F.svg?style=for-the-badge&logo=elixir&logoColor=white)
![Phoenix](https://img.shields.io/badge/Phoenix%20Framework-FD4F00?style=for-the-badge&logo=phoenixframework&logoColor=fff)
![Postgres](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)

# Phoenix Development Environment

Set up your environment without install Elixir and Phoenix locally.
By this way, you don't need to download, install and configure dependencies or create and build a Docker image manually by yourself to start developing a new project.

## Technologies

The project uses:

- Docker
- Docker compose
- Shell script
## Getting started

- Install [`docker`](https://docs.docker.com/engine/install/) and [`docker compose`](https://docs.docker.com/compose/install/)
- Optionally install `make`, to run the [makefile commands](#5-makefile-commands) from the host (`sudo apt install make` on Ubuntu)

> On Ubuntu, `run.sh` installs Docker automatically if it is not installed (see [`docker.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker.sh)).  
> On other systems, install Docker manually before running it.

## How to run

### 1. Clone the repository locally  

In your terminal use `git` to clone the repository locally.
> git clone <https://github.com/VitorGuimaraes/phx_dev_env.git>

### 2. Setup your project variables in `.env`

In `.env` you can setup your postgres variables and some variables used in [`docker-compose.yaml`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker-compose.yaml).

### 3. Run the shell script

> ./run.sh

It will ask for the project's name, if you want to use Ecto, UUID (`--binary-id`) and authentication (`mix phx.gen.auth`).
The answers can also be given as options (`./run.sh --help`), for example:

> ./run.sh --name my_app --ecto --uuid --auth

Then it:

- creates the Phoenix project with the container, owned by your user;
- configures `config/dev.exs` and `config/test.exs` to use the database from `.env` (without Ecto, the database service and variables are removed);
- optionally generates authentication with LiveView pages (`mix phx.gen.auth Accounts User users --live`);
- renames the current folder to the project's name;
- moves `dev.sh` to `scripts/`;
- creates `.env.example` and adds `.env` to `.gitignore`;
- adds the project conventions to `AGENTS.md` (Docker, commits, tests, UI and language) and creates `CLAUDE.md` importing it;
- adds a `commit-msg` hook that validates `<gitmoji> <type>(<scope>): <description>` messages;
- sets `pt_BR` as the default locale, with the Ecto validation errors translated;
- replaces Heroicons with [`Lucide`](https://lucide.dev/icons) icons, including the `mix phx.gen.*` generators (see `templates/icons/`);
- adds [`credo`](https://github.com/rrrene/credo), [`sobelow`](https://github.com/nccgroup/sobelow), [`mix_audit`](https://github.com/mirego/mix_audit) and [`mix_test_watch`](https://github.com/lpil/mix-test.watch) as dev/test dependencies, with Credo, Sobelow and `mix deps.audit` in `mix precommit`;
- sets a Content-Security-Policy with a nonce per request (`templates/csp/`), so inline scripts run only with the nonce;
- adds a GitHub Actions CI (`.github/workflows/ci.yml`) running the `mix precommit` checks on every push and pull request;
- generates a production release image (`Dockerfile`, `mix phx.gen.release --docker`); the development image is `Dockerfile.dev`;
- names the containers, image and network after the project and picks free host ports, so several projects can run at the same time (the ports are registered in `~/.config/phx_dev_env/projects`, so a stopped project keeps its ports);
- installs the Figtree (interface and text) and Lato (titles) fonts, self-hosted (see `templates/fonts/`);
- adds `docs/ui/design-system.md` (defined by the project's first UI task), `docs/ui/screens.md` (screen inventory) and `design/` for [`pen.dev`](https://pen.dev) designs;
- appends development instructions to the project's `README.md`;
- starts a new git repository.

If Docker is installed by the script, log out and log in again (to apply the `docker` group), then run `./run.sh` again.  
Check [`run.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/run.sh) file for more information.  

### 4. Start developing

Go to the project's folder, start the services and open a shell in the app container  
> cd ../<project_name>  
> ./scripts/dev.sh

Inside the container, get the dependencies, create the database (only if using Ecto) and start the server  
> mix deps.get  
> mix ecto.create  
> make app

Or, if you have `make` installed, do the same from the host (first time only for `make app.setup`)  
> make up  
> make app.setup  
> make app

Visit `http://localhost:<APP_HOST_PORT>` (shown at the end of `run.sh` and defined in `.env`, default `4000`) and check Phoenix page.  

### 5. Makefile commands

The `app.*` commands work both from the host (they run through `docker compose exec`) and inside the app container.

- `make up` / `make down` (host only)  
   start / stop the services.

- `make shell` (host only)  
   open a shell in the app container.

- `make app.setup`  
   get the dependencies, create the database and build the assets (`mix setup`).

- `make app`  
   start the server with an interactive shell (`iex -S mix phx.server`).

- `make app.migrate`  
   run the migrations.

- `make app.test`  
   run the tests and format the code. You can pass a file: `make app.test test/my_test.exs`

- `make app.precommit`  
   compile with warnings as errors, remove unused deps, format, run Credo, Sobelow, `mix deps.audit` and the tests (`mix precommit`). Run it before committing.

- `make app.test.watch`  
   run the tests on file changes ([`mix_test_watch`](https://github.com/lpil/mix-test.watch)).

- `make app.credo`  
   run [`Credo`](https://github.com/rrrene/credo) in strict mode.

### 6. Testing the template

`e2e.sh` tests `run.sh` end to end: it creates a project from a temporary copy of this folder (including uncommitted changes), checks the generated files, runs `mix setup`, `mix precommit` and the server in the real containers, and removes everything at the end.

> ./e2e.sh                 # with Ecto  
> ./e2e.sh --auth --release   # with authentication, also building the production image  
> ./e2e.sh --no-ecto  
> ./e2e.sh --keep          # keep the project to inspect it

### 7. Connecting in DBeaver

Host: `localhost`  
Port: DB_HOST_PORT defined in `.env` (default `6032`; only reachable from your machine)  
Database: POSTGRES_DB defined in `.env`  
Username: POSTGRES_USER defined in `.env`  
Password: POSTGRES_PASSWORD defined in `.env`  

### 8. Managing images and containers

- `docker compose up -d`  
   up services.

- `docker compose down`  
   down services.

- `docker exec -it $APP_CONTAINER_NAME sh`  
   exec shell in a running container.

- `docker compose run --rm app_service sh`  
   run a new container with shell and clean up when exit.

- `docker compose down -v`  
   down services and delete the database volume (the database is recreated on the next start).
