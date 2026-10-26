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

> On Ubuntu, `run.sh` installs Docker automatically if it is not installed (see [`docker.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker.sh)).  
> On other systems, install Docker manually before running it.

## How to run

### 1. Clone the repository locally  

In your terminal use `git` to clone the repository locally.
> git clone <https://github.com/VitorGuimaraes/phx_dev_env.git>

### 2. Setup your project variables in `.env`

In `.env` you can setup your postgres variables and some variables used in [`docker-compose.yaml`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/docker-compose.yaml).

### 3. Give permission to execute the bash scripts

> chmod +x *.sh

### 4. Run the shell script

> ./run.sh

It will ask for the project's name and if you want to use Ecto and UUID (`--binary-id`), then:

- creates the Phoenix project with the container, owned by your user;
- configures `config/dev.exs` and `config/test.exs` to use the database from `.env`;
- renames the current folder to the project's name;
- moves `dev.sh` to `scripts/`;
- creates `.env.example` and adds `.env` to `.gitignore`;
- starts a new git repository.

If Docker is installed by the script, log out and log in again (to apply the `docker` group), then run `./run.sh` again.  
Check [`run.sh`](https://github.com/VitorGuimaraes/phx_dev_env/blob/master/run.sh) file for more information.  

### 5. Add Credo Dependency (optional)

Check current [`credo`](https://github.com/rrrene/credo) version

```elixir
defp deps do
  [
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
  ]
end
```

### 6. Start developing

Go to the project's folder, start the services and open a shell in the app container  
> cd ../<project_name>  
> ./scripts/dev.sh

Inside the container, get the dependencies, create the database (only if using Ecto) and start the server  
> mix deps.get  
> mix ecto.create  
> make app

Visit [`http://localhost:4000/`](http://localhost:4000/) and check Phoenix page.  

### 7. Makefile commands

Run them inside the app container.

- `make app`  
   start the server with an interactive shell (`iex -S mix phx.server`).

- `make app.migrate`  
   run the migrations.

- `make app.test`  
   run the tests and format the code. You can pass a file: `make app.test test/my_test.exs`

- `make app.test.watch`  
   run the tests on file changes (requires the [`mix_test_watch`](https://github.com/lpil/mix-test.watch) dependency).

- `make app.credo`  
   run Credo in strict mode (requires the Credo dependency).

### 8. Connecting in DBeaver

Host: `localhost`  
Port: HOST_PORT defined in `.env` (default `6032`)  
Database: POSTGRES_DB defined in `.env`  
Username: POSTGRES_USER defined in `.env`  
Password: POSTGRES_PASSWORD defined in `.env`  

### 9. Managing images and containers

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
