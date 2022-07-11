# Phx Dev 
Set up your environment without install Elixir and Phoenix locally. 
By this way, you don't need to download, install and configure dependencies or create and build a Docker image manually by yourself to start developing.

## Technologies 
The project is created with:
- Docker
- Docker compose
- Shell script

## Getting started
- Install [`docker`](https://docs.docker.com/engine/install/) and [`docker-compose`](https://docs.docker.com/compose/install/)


## How to run 

### 1. Create your project:
In your terminal, create your `project_name` folder and `cd` to it.
> mkdir `project_name` && cd `project_name` 

### 2. Clone the repository locally  
In your terminal use `git` to clone the repository locally.
> git clone https://github.com/VitorGuimaraes/phx_dev

### Give permission to execute the bash script
> sudo chmod +x phx_dev/run.sh

### 3. Run the shell script
It will copy the `Dockerfile` and `docker-compose` files to your project's directory, build the image and than delete the folder `/phx_dev`. 
Check `run.sh` file for more information.  
> ./phx_dev/run.sh 

### 4. Run the container
> docker compose run app bash

### 5. Create your Phoenix Project
In the container's terminal, run:
> mix phx.new .
> exit

The dot at the end of the command means that the project will be created at the current directory. Use `mix phx.new . --no-ecto` if you don't need database.

### 6. Set up your project
In `config/dev.exs` change the ip to `{0, 0, 0, 0}` so wil be possible to access the application endpoint from the host machine.

Change the `hostname` from the database to **db** (this is the default database name in docker-compose file)

If you change the user or password from postgres, change it in `config/dev.exs` and `config/test.exs`.

In the host terminal run: `sudo chown -R $USER *`
You need run this command always that a new file is created from the running container, because the files created from the container are associated to the user and group of the container, not of the host machine. 

## Managing the image and container
`docker compose build` - build the image.
`docker compose run app bash` - run the container and open bash.
`docker rm phx_dev`: stop and delete the running container. 
`docker rmi phx_dev` delete phx_dev image.
