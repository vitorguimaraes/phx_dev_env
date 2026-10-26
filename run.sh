#!/bin/bash

source .env

chmod +x *.sh

# run the container with the host user, so generated files are owned by you
sed -i "s/HOST_UID=.*/HOST_UID=$(id -u)/" .env
sed -i "s/HOST_GID=.*/HOST_GID=$(id -g)/" .env

# check Docker installation
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
    printf "Docker is already installed...\n"
else
    printf "Installing Docker...\n"
    bash docker.sh || exit 1
    printf "Log out and log in again (to apply the docker group), then run ./run.sh again.\n"
    exit 0
fi

# stop and remove any running services of this project
docker compose down --remove-orphans

# (re)build the image with the host user's UID/GID
docker compose build app_service

read -p "What is the Project's Name? " project_name
if [[ ! "$project_name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    printf "Invalid name: use lowercase letters, numbers and underscores (e.g. my_app).\n"
    exit 1
fi

# the current folder will be renamed to the project's name
new_project_path="$(dirname "$PWD")/$project_name"
if [[ -e "$new_project_path" ]]; then
    printf "Folder %s already exists.\n" "$new_project_path"
    exit 1
fi

read -p "Do you want to use Ecto? [Y/n] " use_ecto
read -p "Do you want to use UUID? [Y/n] " uuid_answer

phx_flags=""
[[ "${uuid_answer:-Y}" =~ ^[Yy]$ ]] && phx_flags+=" --binary-id"
[[ "${use_ecto:-Y}" =~ ^[Nn]$ ]] && phx_flags+=" --no-ecto"

if ! docker compose run --rm --no-deps app_service sh -c "mix phx.new$phx_flags $project_name" \
   || [[ ! -d "$project_name" ]]; then
    printf "Failed to create Phoenix project. Nothing was changed.\n"
    exit 1
fi

# changes POSTGRES_DB in .env file accordingly to project's name
# Default name defined by Phoenix is like: project_name_dev
postgres_db="${project_name}_dev" # name is like: project_name
sed -i "s/POSTGRES_DB=.*/POSTGRES_DB=$postgres_db/" .env

# change hostname in config/dev.exs and config/test.exs
# accordingly to postgres service name in docker-compose.yaml (defined as db_service)
sed -i "s/hostname: .*/hostname: \"$POSTGRES_HOST\",/" ${project_name}/config/dev.exs
sed -i "s/hostname: .*/hostname: \"$POSTGRES_HOST\",/" ${project_name}/config/test.exs

# change database credentials in config/dev.exs and config/test.exs accordingly to .env
sed -i "s/username: .*/username: \"$POSTGRES_USER\",/" ${project_name}/config/dev.exs
sed -i "s/password: .*/password: \"$POSTGRES_PASSWORD\",/" ${project_name}/config/dev.exs
sed -i "s/username: .*/username: \"$POSTGRES_USER\",/" ${project_name}/config/test.exs
sed -i "s/password: .*/password: \"$POSTGRES_PASSWORD\",/" ${project_name}/config/test.exs

# change pool_size in config/dev.exs to 2
sed -i "s/pool_size: .*/pool_size: 2/" ${project_name}/config/dev.exs
# change ip to local in config/dev.exs
sed -i "s/http: .*/http: [ip: {0, 0, 0, 0}, port: $APP_PORT],/" ${project_name}/config/dev.exs

# phx.new initializes its own git repository; a new one is created at the end
rm -rf "${project_name}/.git"

# copy phoenix project files to current path, including hidden files
cp -r "${project_name}/." "$(pwd)"

# delete the original project folder
rm -rf "$project_name"

# keep .env out of git and provide a template for other developers
cp .env .env.example
printf "\n# environment variables\n.env\n" >> .gitignore

# stop services before renaming the folder (compose identifies the project by folder name)
docker compose down

# rename current folder with project's name
mv "$(pwd)" "$new_project_path"

mkdir scripts
mv dev.sh scripts/

rm run.sh
rm docker.sh

# delete old git files
rm -rf .git
git init

printf "\nProject created at %s\n" "$new_project_path"
printf "Run: cd %s && ./scripts/dev.sh\n" "$new_project_path"
