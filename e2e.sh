#!/bin/bash
# End-to-end test of run.sh: creates a project from a temporary copy of this folder
# (including uncommitted changes), checks the result, runs mix setup and mix precommit
# against the real containers and removes everything at the end.
#
# Usage: ./e2e.sh [--no-ecto] [--auth] [--release] [--keep]
#   --no-ecto   create the project without Ecto
#   --auth      generate authentication (mix phx.gen.auth)
#   --release   also build the production image (slow)
#   --keep      keep the project, containers and images (prints how to remove them)

set -e

run_flags=(--uuid)
use_ecto=y
use_auth=n
build_release=n
keep=n
for arg in "$@"; do
    case $arg in
        --no-ecto) use_ecto=n ;;
        --auth) use_auth=y ;;
        --release) build_release=y ;;
        --keep) keep=y ;;
        *) printf "Unknown option: %s\n" "$arg" >&2; exit 1 ;;
    esac
done
if [[ "$use_ecto" == y ]]; then run_flags+=(--ecto); else run_flags+=(--no-ecto); fi
if [[ "$use_auth" == y ]]; then run_flags+=(--auth); else run_flags+=(--no-auth); fi

id=$(date +%s)
name="e2e_$id"
module="E2e$id"
work=$(mktemp -d)
# unique folder name: compose names the project (network, volumes) after it
template="$work/e2e_template_$id"
project="$work/$name"
# keep the test out of the real registry of host ports
export XDG_CONFIG_HOME="$work/config"

failures=0
check() {
    local description=$1
    shift
    if "$@" >/dev/null 2>&1; then
        printf "  ok    %s\n" "$description"
    else
        printf "  FAIL  %s\n" "$description"
        failures=$((failures + 1))
    fi
}

cleanup() {
    if [[ "$keep" == y ]]; then
        printf "\nKept %s. To remove it:\n" "$project"
        printf "  (cd %s && docker compose down -v) && docker rmi %s_app && rm -rf %s\n" "$project" "$name" "$work"
        return
    fi
    printf "\nCleaning up...\n"
    for dir in "$project" "$template"; do
        if [[ -f "$dir/docker-compose.yaml" ]]; then
            (cd "$dir" && docker compose down -v --remove-orphans >/dev/null 2>&1) || true
        fi
    done
    docker rmi -f "${name}_app" "${name}_release" >/dev/null 2>&1 || true
    rm -rf "$work"
}
trap cleanup EXIT

# app container commands, without a TTY
in_app() {
    docker compose exec -T app_service "$@"
}

printf "== run.sh %s (in %s)\n" "${run_flags[*]}" "$work"
mkdir "$template"
tar --exclude=.git -cf - . | tar -xf - -C "$template"
(cd "$template" && ./run.sh --name "$name" "${run_flags[@]}" </dev/null)
cd "$project"
source .env

printf "\n== Generated files\n"
check "template files removed" bash -c '[[ ! -e run.sh && ! -e docker.sh && ! -e e2e.sh && ! -e templates ]]'
check "scripts/dev.sh" test -x scripts/dev.sh
check "no Heroicons left" bash -c '! grep -rqE "hero-[a-z0-9-]+" lib priv/templates AGENTS.md'
check "Lucide dependency" grep -q '{:lucide,' mix.exs
check "Lucide Tailwind plugin" bash -c '[[ -f assets/vendor/lucide.js && ! -e assets/vendor/heroicons.js ]] && grep -q "lucide" assets/css/app.css'
check "generator templates with Lucide" grep -rq 'lucide-' priv/templates
check "pt_BR default locale" grep -q 'default_locale: "pt_BR"' config/config.exs
check "pt_BR Ecto errors" test -f priv/gettext/pt_BR/LC_MESSAGES/errors.po
check "Credo and Sobelow in mix precommit" bash -c 'grep -q "\"credo\"," mix.exs && grep -q "\"sobelow --skip --exit low --ignore Vuln\"" mix.exs'
check "Content-Security-Policy plug in the router" grep -q "plug ${module}Web.Plugs.ContentSecurityPolicy" "lib/${name}_web/router.ex"
check "CSP nonce in the root layout" grep -q 'nonce={@csp_nonce}' "lib/${name}_web/components/layouts/root.html.heex"
check "no template markers or placeholders left" bash -c \
    '! grep -rqE "(db|auth):(start|end)|__[A-Z_]+__" .env .env.example docker-compose.yaml makefile AGENTS.md README.md .github'
check "AGENTS.md conventions and CLAUDE.md" bash -c 'grep -q "^## Development environment (Docker)" AGENTS.md && grep -qx "@AGENTS.md" CLAUDE.md'
check "Docker names from the project name" bash -c "grep -qx APP_CONTAINER_NAME=${name}_app .env && grep -qx APP_IMAGE_NAME=${name}_app .env"
check ".env ignored, .env.example created" bash -c 'grep -qx ".env" .gitignore && test -f .env.example'
check "port registered" grep -q "^${name}	${APP_HOST_PORT}	" "$XDG_CONFIG_HOME/phx_dev_env/projects"
check "docker-compose.yaml is valid" docker compose config -q
check "CI workflow" test -f .github/workflows/ci.yml
check "production and development Dockerfiles" bash -c 'test -f Dockerfile && test -f Dockerfile.dev && test -x rel/overlays/bin/server'
check "commit hook enabled" bash -c '[[ $(git config core.hooksPath) == .githooks && -x .githooks/commit-msg ]]'
check "commit hook accepts a valid message" bash -c 'printf "✨ feat(accounts): add login\n" > msg.tmp && .githooks/commit-msg msg.tmp'
check "commit hook rejects an invalid message" bash -c 'printf "add login\n" > msg.tmp && ! .githooks/commit-msg msg.tmp'
rm -f msg.tmp

if [[ "$use_ecto" == y ]]; then
    check "database service" bash -c "docker compose config --services | grep -qx db_service"
    check "database names" bash -c "grep -qx DB_CONTAINER_NAME=${name}_db .env && grep -qx POSTGRES_DB=${name}_dev .env"
    check "database host in config" grep -q 'hostname: "db_service"' config/dev.exs config/test.exs
    check "database service in the CI" grep -q 'db_service:' .github/workflows/ci.yml
else
    check "no database service" bash -c "! docker compose config --services | grep -qx db_service"
    check "no database variables" bash -c '! grep -qE "POSTGRES|DATABASE_URL|DB_" .env'
    check "no database in the CI" bash -c '! grep -q "db_service" .github/workflows/ci.yml'
    check "no database rules in AGENTS.md" bash -c '! grep -q "The database host is" AGENTS.md'
fi

if [[ "$use_auth" == y ]]; then
    check "authentication generated" test -f "lib/${name}/accounts.ex"
    check "authentication rules in AGENTS.md" grep -q "Authentication was generated" AGENTS.md
else
    check "no authentication" test ! -e "lib/${name}/accounts.ex"
    check "no authentication rules in AGENTS.md" bash -c '! grep -q "Authentication was generated" AGENTS.md'
fi

printf "\n== mix setup and mix precommit\n"
docker compose up -d
in_app mix setup
# stage everything, so the changes made by mix precommit show up in git diff
git add -A
in_app mix precommit
# the CI checks that mix precommit fixes instead of failing on
in_app sh -c "MIX_ENV=test mix format --check-formatted && MIX_ENV=test mix deps.unlock --check-unused"
check "files unchanged by mix precommit (generated code formatted)" git diff --quiet

printf "\n== Server\n"
in_app sh -c "nohup mix phx.server > /tmp/server.log 2>&1 &"
url="http://localhost:$APP_HOST_PORT"
for _ in $(seq 60); do
    if curl -s -o /dev/null "$url"; then break; fi
    sleep 2
done
check "home page responds 200" bash -c "[[ \$(curl -s -o /dev/null -w '%{http_code}' $url) == 200 ]]"
# every inline script has the nonce of the response header and there are no inline handlers
csp_page_ok() {
    local headers body nonce
    headers=$(mktemp)
    body=$(mktemp)
    curl -sL -D "$headers" -o "$body" "$url$1"
    nonce=$(grep -i '^content-security-policy:' "$headers" | tail -1 | grep -oE "'nonce-[A-Za-z0-9_-]+'" | cut -d- -f2- | tr -d "'")
    [[ -n "$nonce" ]] \
        && ! grep -oE '<script[^>]*>' "$body" | grep -v ' src=' | grep -qv "nonce=\"$nonce\"" \
        && ! grep -qiE '<[^>]+[[:space:]]on[a-z]+=' "$body"
    local ok=$?
    rm -f "$headers" "$body"
    return $ok
}
check "CSP nonce on the home page" csp_page_ok /
check "CSP nonce on the LiveDashboard" csp_page_ok /dev/dashboard
check "CSP nonce on the mailbox preview" csp_page_ok /dev/mailbox
check "CSP without unsafe-inline scripts" bash -c "! curl -sI $url | grep -i '^content-security-policy:' | grep -q \"script-src[^;]*unsafe-inline\""
check "app.css has the Lucide icons" bash -c "curl -s $url/assets/css/app.css | grep -q 'lucide-'"
if [[ "$use_auth" == y ]]; then
    check "log in page responds 200" bash -c "[[ \$(curl -s -o /dev/null -w '%{http_code}' $url/users/log-in) == 200 ]]"
    check "CSP nonce on the log in page" csp_page_ok /users/log-in
fi

if [[ "$build_release" == y ]]; then
    printf "\n== Production image\n"
    docker build -t "${name}_release" .
    check "release boots its runtime config" docker run --rm \
        -e SECRET_KEY_BASE="$(printf 'x%.0s' $(seq 64))" \
        -e DATABASE_URL=ecto://user:password@localhost/db -e PHX_HOST=localhost \
        "${name}_release" "/app/bin/${name}" eval 'IO.puts(:ok)'
fi

printf "\n"
if ((failures > 0)); then
    printf "%s check(s) failed.\n" "$failures"
    exit 1
fi
printf "All checks passed.\n"
