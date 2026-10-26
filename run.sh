#!/bin/bash

usage() {
    cat <<'EOF'
Usage: ./run.sh [options]

Creates a Phoenix project in this folder. Options not given are asked interactively.

  --name NAME          project name (lowercase letters, numbers and underscores)
  --ecto, --no-ecto    use Ecto and PostgreSQL (default: yes)
  --uuid, --no-uuid    use UUID primary keys, --binary-id (default: yes)
  --auth, --no-auth    generate authentication with mix phx.gen.auth (default: no; requires Ecto)
  -h, --help           show this help
EOF
}

project_name=""
use_ecto=""
use_uuid=""
use_auth=""
while (($#)); do
    case $1 in
        --name)
            if (($# < 2)); then usage; exit 1; fi
            project_name=$2
            shift
            ;;
        --name=*) project_name=${1#*=} ;;
        --ecto) use_ecto=y ;;
        --no-ecto) use_ecto=n ;;
        --uuid) use_uuid=y ;;
        --no-uuid) use_uuid=n ;;
        --auth) use_auth=y ;;
        --no-auth) use_auth=n ;;
        -h | --help) usage; exit 0 ;;
        *) printf "Unknown option: %s\n\n" "$1"; usage; exit 1 ;;
    esac
    shift
done

# stop at the first failing command, before the template is removed
set -eE
restore_hint="The template folder may be partially changed. To restore it and try again
(this also discards your changes to .env):
  docker compose down; git checkout -- . && git clean -fdx"
trap 'printf "\nrun.sh failed at line %s.\n%s\n" "$LINENO" "$restore_hint" >&2' ERR

die() {
    printf "%s\n" "$1" >&2
    exit 1
}

# prints y or n; $1 is the question, $2 the default answer
ask_yes_no() {
    local answer
    read -r -p "$1 " answer
    if [[ "${answer:-$2}" =~ ^[Yy] ]]; then echo y; else echo n; fi
}

source .env

# run the container with the host user, so generated files are owned by you
sed -i "s/HOST_UID=.*/HOST_UID=$(id -u)/" .env
sed -i "s/HOST_GID=.*/HOST_GID=$(id -g)/" .env

# check Docker installation
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
    printf "Docker is already installed...\n"
else
    printf "Installing Docker...\n"
    bash docker.sh
    printf "Log out and log in again (to apply the docker group), then run ./run.sh again.\n"
    exit 0
fi

# make is optional on the host (the makefile also works from inside the container)
if ! command -v make >/dev/null; then
    printf "Warning: make is not installed. To use the make commands from the host, run: sudo apt install make\n"
fi

if [[ -z "$project_name" ]]; then
    read -r -p "What is the Project's Name? " project_name
fi
if [[ ! "$project_name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    die "Invalid name: use lowercase letters, numbers and underscores (e.g. my_app)."
fi

# the current folder will be renamed to the project's name
new_project_path="$(dirname "$PWD")/$project_name"
if [[ -e "$new_project_path" ]]; then
    die "Folder $new_project_path already exists."
fi

[[ -n "$use_ecto" ]] || use_ecto=$(ask_yes_no "Do you want to use Ecto? [Y/n]" y)
[[ -n "$use_uuid" ]] || use_uuid=$(ask_yes_no "Do you want to use UUID? [Y/n]" y)
if [[ "$use_ecto" == n ]]; then
    [[ "$use_auth" != y ]] || die "Authentication (--auth) requires Ecto."
    use_auth=n
fi
[[ -n "$use_auth" ]] || use_auth=$(ask_yes_no "Do you want authentication (mix phx.gen.auth)? [y/N]" n)

# stop and remove any running services of this project
docker compose down --remove-orphans

# unique Docker names per project, so several generated projects can run at the same time
APP_IMAGE_NAME="${project_name}_app"
APP_CONTAINER_NAME="${project_name}_app"
DB_CONTAINER_NAME="${project_name}_db"
sed -i "s/^APP_IMAGE_NAME=.*/APP_IMAGE_NAME=$APP_IMAGE_NAME/" .env
sed -i "s/^APP_CONTAINER_NAME=.*/APP_CONTAINER_NAME=$APP_CONTAINER_NAME/" .env
sed -i "s/^DB_CONTAINER_NAME=.*/DB_CONTAINER_NAME=$DB_CONTAINER_NAME/" .env

# host ports of the projects created by run.sh (one line per project:
# name, app port, database port, path), so stopped projects keep their ports
projects_registry="${XDG_CONFIG_HOME:-$HOME/.config}/phx_dev_env/projects"
reserved_ports=" "
if [[ -f "$projects_registry" ]]; then
    while IFS=$'\t' read -r _ app_port db_port path; do
        if [[ -d "$path" ]]; then reserved_ports+="$app_port $db_port "; fi
    done < "$projects_registry"
fi

# first free host port from the default (e.g. 4001 if another project is using 4000)
free_port() {
    local port=$1
    while [[ -n "$(ss -ltnH "sport = :$port" 2>/dev/null)" || "$reserved_ports" == *" $port "* ]]; do
        port=$((port + 1))
    done
    echo "$port"
}
APP_HOST_PORT=$(free_port "$APP_HOST_PORT")
sed -i -E "s/^APP_HOST_PORT=[0-9]+/APP_HOST_PORT=$APP_HOST_PORT/" .env
if [[ "$use_ecto" == y ]]; then
    DB_HOST_PORT=$(free_port "$DB_HOST_PORT")
else
    DB_HOST_PORT=
fi

# (re)build the image with the host user's UID/GID
docker compose build app_service

phx_flags=""
if [[ "$use_uuid" == y ]]; then phx_flags+=" --binary-id"; fi
if [[ "$use_ecto" == n ]]; then phx_flags+=" --no-ecto"; fi

if ! docker compose run --rm --no-deps app_service sh -c "mix phx.new$phx_flags $project_name" \
   || [[ ! -d "$project_name" ]]; then
    die "Failed to create Phoenix project. Nothing was changed."
fi

# keep (y) or remove (n) the blocks between "<tag>:start" and "<tag>:end" marker lines
keep_blocks() {
    local tag=$1 keep=$2
    shift 2
    if [[ "$keep" == y ]]; then
        sed -i "/$tag:start/d; /$tag:end/d" "$@"
    else
        sed -i "/$tag:start/,/$tag:end/d" "$@"
    fi
}

# database settings only when using Ecto
keep_blocks db "$use_ecto" .env docker-compose.yaml makefile
if [[ "$use_ecto" == y ]]; then
    sed -i -E "s/^DB_HOST_PORT=[0-9]+/DB_HOST_PORT=$DB_HOST_PORT/" .env

    # changes POSTGRES_DB in .env file accordingly to project's name
    # Default name defined by Phoenix is like: project_name_dev
    sed -i "s/POSTGRES_DB=.*/POSTGRES_DB=${project_name}_dev/" .env

    # change hostname in config/dev.exs and config/test.exs
    # accordingly to postgres service name in docker-compose.yaml (defined as db_service)
    # and the database credentials accordingly to .env
    for env in dev test; do
        sed -i "s/hostname: .*/hostname: \"$POSTGRES_HOST\",/" "${project_name}/config/${env}.exs"
        sed -i "s/username: .*/username: \"$POSTGRES_USER\",/" "${project_name}/config/${env}.exs"
        sed -i "s/password: .*/password: \"$POSTGRES_PASSWORD\",/" "${project_name}/config/${env}.exs"
    done

    # change pool_size in config/dev.exs to 2
    sed -i "s/pool_size: .*/pool_size: 2/" "${project_name}/config/dev.exs"
fi

# change ip to local in config/dev.exs
sed -i "s/http: .*/http: [ip: {0, 0, 0, 0}, port: $APP_PORT],/" "${project_name}/config/dev.exs"

# phx.new initializes its own git repository; a new one is created at the end
rm -rf "${project_name}/.git"

# copy phoenix project files to current path, including hidden files
cp -r "${project_name}/." "$(pwd)"

# delete the original project folder
rm -rf "$project_name"

# keep .env out of git and provide a template for other developers
cp .env .env.example
printf "\n# environment variables\n.env\n" >> .gitignore

# project conventions for AI agents (Docker, commits, tests, UI and language)
app_module=$(sed -E 's/(^|_)([a-z0-9])/\U\2/g' <<< "$project_name")
cp templates/AGENTS.conventions.md conventions.md.tmp
keep_blocks db "$use_ecto" conventions.md.tmp
keep_blocks auth "$use_auth" conventions.md.tmp
conventions=$(<conventions.md.tmp)
rm conventions.md.tmp
conventions=${conventions//__APP_CONTAINER__/$APP_CONTAINER_NAME}
conventions=${conventions//__APP_HOST_PORT__/$APP_HOST_PORT}
conventions=${conventions//__APP_MODULE__/$app_module}
export CONVENTIONS=${conventions//__APP_WEB__/lib/${project_name}_web}

# insert them at the top of AGENTS.md (generated by Phoenix), before the project guidelines
if [[ -f AGENTS.md ]] && grep -q "^## Project guidelines" AGENTS.md; then
    awk '/^## Project guidelines/ && !done { print ENVIRON["CONVENTIONS"] "\n"; done = 1 } { print }' \
        AGENTS.md > AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md
else
    printf "%s\n" "$CONVENTIONS" >> AGENTS.md
fi

# Claude Code reads CLAUDE.md; import AGENTS.md to keep a single source
printf "@AGENTS.md\n" > CLAUDE.md

# validate commit messages (the hook is enabled after git init)
mkdir -p .githooks
cp templates/commit-msg .githooks/commit-msg
chmod +x .githooks/commit-msg

# CI: the mix precommit checks on every push and pull request
mkdir -p .github/workflows
sed -e "s/__POSTGRES_USER__/${POSTGRES_USER:-}/; s/__POSTGRES_PASSWORD__/${POSTGRES_PASSWORD:-}/" \
    templates/ci.yml > .github/workflows/ci.yml
keep_blocks db "$use_ecto" .github/workflows/ci.yml

# Brazilian Portuguese as the default locale, with the Ecto errors translated
export GETTEXT_CONFIG="# Brazilian Portuguese as the default locale
config :${project_name}, ${app_module}Web.Gettext, default_locale: \"pt_BR\"
"
awk '/^import_config/ && !done { print ENVIRON["GETTEXT_CONFIG"]; done = 1 } { print }' \
    config/config.exs > config/config.exs.tmp && mv config/config.exs.tmp config/config.exs
mkdir -p priv/gettext/pt_BR/LC_MESSAGES
cp templates/errors.pt_BR.po priv/gettext/pt_BR/LC_MESSAGES/errors.po

# development instructions in the project's README
sed -e "s/__APP_HOST_PORT__/$APP_HOST_PORT/g; s/__APP_CONTAINER__/$APP_CONTAINER_NAME/g" \
    -e "s/__APP__/$project_name/g" templates/README.development.md > README.development.md.tmp
keep_blocks db "$use_ecto" README.development.md.tmp
cat README.development.md.tmp >> README.md
rm README.development.md.tmp

# design system, screen inventory and pen.dev design folder
mkdir -p docs/ui design
cp templates/docs/ui/design-system.md docs/ui/design-system.md
sed "s/__APP_MODULE__/$app_module/g" templates/docs/ui/screens.md > docs/ui/screens.md
cp templates/design/README.md design/README.md

# Credo (make app.credo), Sobelow and mix_test_watch (make app.test.watch)
perl -0pi -e 's/(  defp deps do\n    \[\n)/$1      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},\n      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},\n      {:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false},\n/' mix.exs
grep -q '{:sobelow,' mix.exs || die "Could not add the dev dependencies to mix.exs."

# Credo and Sobelow in mix precommit (the CI runs the same checks)
perl -0pi -e 's/"format", "test"\]/"format", "credo", "sobelow --skip --exit low --ignore Vuln", "test"]/' mix.exs
grep -q '"sobelow --skip --exit low --ignore Vuln"' mix.exs || die "Could not add Credo and Sobelow to mix precommit."

# Lucide icons instead of Heroicons (see templates/icons)
lucide_version="1.56.0"

# sed expressions from the hero -> lucide map (whole icon names only)
icon_sed_args=()
while read -r hero lucide; do
    icon_sed_args+=(-e "s/${hero}([^a-z0-9-]|\$)/${lucide}\1/g")
done < templates/icons/icons.map

# dependency
export LUCIDE_DEP="{:lucide,
       github: \"lucide-icons/lucide\",
       tag: \"${lucide_version}\",
       sparse: \"icons\",
       app: false,
       compile: false,
       depth: 1}"
perl -0pi -e 's/\{:heroicons,.*?depth: 1\}/$ENV{LUCIDE_DEP}/s' mix.exs
grep -q '{:lucide,' mix.exs || die "Could not replace Heroicons with Lucide in mix.exs."

# Tailwind plugin
cp templates/icons/lucide.js assets/vendor/lucide.js
rm -f assets/vendor/heroicons.js
sed -i 's/"hero-#{ICON}"/"lucide-#{ICON}"/; s/heroicons/lucide/g' assets/css/app.css

# <.icon> component that validates the icon names in dev and test
export ICON_COMPONENT=$(sed "s/__APP__/${project_name}/" templates/icons/icon_component.ex)
perl -0pi -e 's/  \@doc """\n  Renders a \[Heroicon\].*?\n  def icon\(%\{name: "hero-" <> _\} = assigns\) do\n.*?\n  end\n/$ENV{ICON_COMPONENT}\n/s' \
    "lib/${project_name}_web/components/core_components.ex"
grep -q 'validate_icon!' "lib/${project_name}_web/components/core_components.ex" \
    || die "Could not replace the <.icon> component in core_components.ex."
for env in dev test; do
    printf '\n# raise on unknown icon names in <.icon>\nconfig :%s, :validate_icons, true\n' \
        "$project_name" >> "config/${env}.exs"
done

# icons used by the generated code and by the Phoenix guidelines in AGENTS.md
sed -i -E "${icon_sed_args[@]}" \
    "lib/${project_name}_web/components/core_components.ex" \
    "lib/${project_name}_web/components/layouts.ex" \
    AGENTS.md
sed -i 's/component for hero icons/component for Lucide icons/' AGENTS.md
sed -i 's|\* \[Heroicons\](https://heroicons.com)|* [Lucide](https://lucide.dev/icons)|' \
    "lib/${project_name}_web/components/core_components.ex"

# generators (mix phx.gen.*) use the project's priv/templates before their own:
# copy the generator templates that render icons, with Lucide icons
docker compose run --rm --no-deps app_service sh -c "mix deps.get && mix deps.unlock --unused"
# (core_components.ex.eex is skipped: it is only used when the project has none)
for file in $(grep -rlE 'hero-[a-z0-9-]+' deps/phoenix/priv/templates | grep -v core_components); do
    target=${file#deps/phoenix/}
    mkdir -p "$(dirname "$target")"
    sed -E "${icon_sed_args[@]}" "$file" > "$target"
done
[[ -d priv/templates ]] || die "Could not copy the Phoenix generator templates to priv/templates."

# authentication (LiveView pages), generated with the Lucide templates above
if [[ "$use_auth" == y ]]; then
    docker compose run --rm --no-deps app_service sh -c \
        "mix phx.gen.auth Accounts User users --live && mix deps.get" </dev/null

    # Credo asks for a @moduledoc in these generated modules
    add_moduledoc() {
        local file=$1 doc=$2
        if ! grep -q '@moduledoc' "$file"; then
            export MODULEDOC=$doc
            perl -0pi -e 's/^(defmodule \S+ do\n)/$1  \@moduledoc """\n  $ENV{MODULEDOC}\n  """\n\n/' "$file"
        fi
    }
    add_moduledoc "lib/${project_name}_web/user_auth.ex" \
        "Plugs and LiveView \`on_mount\` hooks for user authentication."
    add_moduledoc "lib/${project_name}/accounts/user_notifier.ex" \
        "Delivers the account emails (login instructions and email update)."

    # the pages render the Ecto errors in pt_BR (errors.po): update the generated tests
    auth_live_tests="test/${project_name}_web/live/user_live"
    sed -i -e 's/"has already been taken"/"já está em uso"/' \
        -e 's/"should be at least 12 character(s)"/"deve ter pelo menos 12 caracteres"/' \
        "$auth_live_tests"/*.exs
    if grep -rqE '"(has already been taken|should be at least 12 character\(s\))"' "$auth_live_tests"; then
        die "Could not translate the Ecto errors in $auth_live_tests."
    fi
fi

# Content-Security-Policy in the browser pipeline (checked by Sobelow, which needs a single
# string); 'unsafe-inline' is needed by the theme script in root.html.heex and the dev dashboards
csp="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'"
export SECURE_HEADERS="
  # Content-Security-Policy of the browser pipeline; add an origin only when it is needed
  @secure_headers %{
    \"content-security-policy\" => \"$csp\"
  }
"
router="lib/${project_name}_web/router.ex"
perl -0pi -e 's/^(  use \S+, :router\n)/$1$ENV{SECURE_HEADERS}/m; s/plug :put_secure_browser_headers\n/plug :put_secure_browser_headers, \@secure_headers\n/' "$router"
grep -q 'put_secure_browser_headers, @secure_headers' "$router" \
    || die "Could not add the Content-Security-Policy to $router."

# production image (Dockerfile; the development one is Dockerfile.dev) and release scripts
docker compose run --rm --no-deps app_service sh -c "mix phx.gen.release --docker" </dev/null
[[ -f Dockerfile ]] || die "Could not generate the production Dockerfile."

# format the changed files
docker compose run --rm --no-deps app_service sh -c "mix format"

# warn about icons missing from templates/icons/icons.map (e.g. after a Phoenix upgrade)
missing_icons=$(grep -rhoE 'hero-[a-z0-9-]+' lib priv/templates AGENTS.md | sort -u)
if [[ -n "$missing_icons" ]]; then
    printf "Warning: Heroicons without a Lucide equivalent in templates/icons/icons.map:\n%s\n" "$missing_icons"
fi

# stop services before renaming the folder (compose identifies the project by folder name)
docker compose down

# from here on the template folder is renamed
restore_hint="The project was created at $new_project_path, but the last steps did not finish."

# rename current folder with project's name
mv "$(pwd)" "$new_project_path"
cd "$new_project_path"

mkdir scripts
mv dev.sh scripts/

rm run.sh
rm docker.sh
rm e2e.sh
rm -rf templates

# delete old git files
rm -rf .git
git init
git config core.hooksPath .githooks

# register the host ports (entries of deleted projects are dropped)
mkdir -p "$(dirname "$projects_registry")"
{
    if [[ -f "$projects_registry" ]]; then
        while IFS=$'\t' read -r name app_port db_port path; do
            if [[ -d "$path" ]]; then
                printf "%s\t%s\t%s\t%s\n" "$name" "$app_port" "$db_port" "$path"
            fi
        done < "$projects_registry"
    fi
    printf "%s\t%s\t%s\t%s\n" "$project_name" "$APP_HOST_PORT" "${DB_HOST_PORT:--}" "$new_project_path"
} > "$projects_registry.tmp"
mv "$projects_registry.tmp" "$projects_registry"

printf "\nProject created at %s\n" "$new_project_path"
if [[ "$use_ecto" == y ]]; then
    printf "App: http://localhost:%s | Database: localhost:%s\n" "$APP_HOST_PORT" "$DB_HOST_PORT"
else
    printf "App: http://localhost:%s\n" "$APP_HOST_PORT"
fi
printf "Run: cd %s && ./scripts/dev.sh\n" "$new_project_path"
