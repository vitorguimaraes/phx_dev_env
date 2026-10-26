## Development environment (Docker)

Elixir, Erlang and Mix are **not installed on the host**. They only exist inside the
`__APP_CONTAINER__` container. Files are shared with the host through a volume, so edit
them normally, but run every `mix`, `iex` and `make` command inside the container:

- Start the services (app + database): `docker compose up -d`
- Run a command: `docker exec __APP_CONTAINER__ mix <task>` (e.g. `docker exec __APP_CONTAINER__ mix test`)
- After changing dependencies in `mix.exs`: `docker exec __APP_CONTAINER__ mix deps.get`
- Before committing: `docker exec __APP_CONTAINER__ mix precommit` (requires the database running)
- **Never** run `mix` on the host or install Elixir/Erlang locally
- **Never** use `./scripts/dev.sh` (it opens an interactive shell)
- The dev server is started by the developer with `make app` (interactive); check if it is
  running with `curl -s -o /dev/null -w "%{http_code}" http://localhost:__APP_HOST_PORT__`
- The database host is `db_service` (Docker network); **do not** change it to `localhost`
  in `config/dev.exs` or `config/test.exs`
- Database credentials come from `.env`, which is not committed. When adding a new variable,
  also add it to `.env.example`

## Commits

- Commit at the end of each completed task, only after
  `docker exec __APP_CONTAINER__ mix precommit` passes. Never commit with failing checks
- Make atomic commits: one logical change per commit; split independent changes
- Format (enforced by `.githooks/commit-msg`): `<gitmoji> <type>(<scope>): <description>`
  - `<scope>` is optional; use the context name (e.g. `accounts`, `blog`)
  - `<description>`: English, imperative mood, lowercase, no trailing period
  - Subject line up to 72 characters
  - Types: ✨ feat, 🐛 fix, ♻️ refactor, ⚡️ perf, ✅ test, 📝 docs, 🎨 style,
    📦 build, 👷 ci, 🔧 chore, ⏪ revert
  - Examples: `✨ feat(accounts): add password reset via email`,
    `🐛 fix(blog): prevent duplicate slugs on post update`
- Add a body only when the reason for the change is not obvious; explain why, not what
- Breaking changes: add `!` after the type/scope and a `BREAKING CHANGE:` line in the body
- **Never** push unless the developer explicitly asks
- **Never** commit `.env`, use `--no-verify`, `push --force` or amend pushed commits

## Tests

- Every new feature ships with tests in the same commit
- Every bug fix starts with a failing test that reproduces the bug; only then fix it
- Required tests:
  - Contexts: every public function, covering success and error paths
    (invalid changeset, record not found)
  - LiveViews: rendering, events (`phx-click`, `phx-submit`, `phx-change`) and navigation
  - Controllers and JSON APIs: status, response body and authorization
  - Authorization: always test that a user cannot access another user's data
- Test data: use and extend the fixtures in `test/support/fixtures`; do not add ExMachina
- External HTTP calls: stub them with `Req.Test`; tests must never hit real external services
- Run the tests with `docker exec __APP_CONTAINER__ mix test` (or `mix test <file>`)
- There is no coverage threshold; use `mix test --cover` only to inspect coverage

## UI

- daisyUI is used **only** for the theme (semantic colors and dark mode) and for the
  existing components in `core_components.ex`. This overrides the "instead of using
  daisyUI" rule in the JS and CSS guidelines below
- Build new components with Tailwind utility classes using **only theme colors**:
  `primary`, `secondary`, `accent`, `neutral`, `base-100/200/300`, `base-content`,
  `info`, `success`, `warning`, `error` (and their `-content` variants; opacity
  modifiers like `bg-primary/10` are fine)
- **Never** use palette colors (`bg-blue-500`, `text-gray-700`) or hex values
- Reuse and extend `core_components.ex` before creating a new component
- Reusable UI goes in function components with `attr` and `slot` in
  `__APP_WEB__/components/`; never duplicate markup between pages
- Mobile-first and responsive on every page
- Accessibility: every input has a `label`, icon-only buttons have `aria-label`
- Icons: always `<.icon name="lucide-...">` with a **literal, full name**
  (e.g. `lucide-shopping-cart`); never build icon names dynamically, because
  Tailwind only generates CSS for names it finds in the source code
- Before using an icon, check that `deps/lucide/icons/<name>.svg` exists; to find
  icons by meaning, search the tags in the JSON files
  (e.g. `grep -l '"cart"' deps/lucide/icons/*.json`)
- Heroicons are not installed; generators already produce Lucide icons through the
  custom templates in `priv/templates/`
- When upgrading Phoenix, compare `priv/templates/` with the new generator templates

## Language

- English for code (modules, functions, variables, database tables and columns),
  comments, `@moduledoc`/`@doc`, commit messages and project docs (README, ADRs)
- Brazilian domain terms without a natural English translation (e.g. `cnpj`) may be kept as is
- User-facing text is in Brazilian Portuguese and **always** goes through Gettext,
  with the Portuguese text as the message id: `gettext("Meus pedidos")`.
  This includes page titles, labels, placeholders, buttons and flash messages
- The default locale is `pt_BR`; Ecto validation errors are translated in
  `priv/gettext/pt_BR/LC_MESSAGES/errors.po`
- Generators (`mix phx.gen.*`) create English UI text: translate it to Portuguese with
  `gettext` and update the generated tests that assert on those texts
