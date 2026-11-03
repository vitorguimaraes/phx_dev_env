## Development environment (Docker)

Elixir, Erlang and Mix are **not installed on the host**. They only exist inside the
`__APP_CONTAINER__` container. Files are shared with the host through a volume, so edit
them normally, but run every `mix`, `iex` and `make` command inside the container:

- Start the services: `docker compose up -d`
- Run a command: `docker exec __APP_CONTAINER__ mix <task>` (e.g. `docker exec __APP_CONTAINER__ mix test`)
- After changing dependencies in `mix.exs`: `docker exec __APP_CONTAINER__ mix deps.get`
- Before committing: `docker exec __APP_CONTAINER__ mix precommit`
- **Never** run `mix` on the host or install Elixir/Erlang locally
- **Never** use `./scripts/dev.sh` (it opens an interactive shell)
- The dev server is started by the developer with `make app` (interactive); check if it is
  running with `curl -s -o /dev/null -w "%{http_code}" http://localhost:__APP_HOST_PORT__`
<!-- db:start -->
- `mix precommit` and `mix test` require the database running (`docker compose up -d`)
- The database host is `db_service` (Docker network); **do not** change it to `localhost`
  in `config/dev.exs` or `config/test.exs`
- Database credentials come from `.env`, which is not committed
<!-- db:end -->
- When adding a new variable to `.env` (not committed), also add it to `.env.example`
- `Dockerfile.dev` is the development image (used by `docker-compose.yaml`); `Dockerfile` is
  the production release image (`mix phx.gen.release --docker`). When adding a system package
  needed at runtime, add it to both

## Commits

- Commit at the end of each completed task, only after
  `docker exec __APP_CONTAINER__ mix precommit` passes. Never commit with failing checks.
  It compiles with warnings as errors, formats, runs Credo, Sobelow, `mix deps.audit`
  (dependencies with known vulnerabilities; needs internet), `mix hex.audit` (dependencies
  retired by their authors) and the tests
- CI (`.github/workflows/ci.yml`) runs the same checks on every push and pull request;
  when adding a check to `mix precommit`, add it to the CI too
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

## Security

- Fix the issues reported by Credo and Sobelow; **never** disable a check, add
  `# sobelow_skip` or change `.sobelow-skips` without asking the developer
- When `mix deps.audit` reports a vulnerable dependency, or `mix hex.audit` a retired one,
  update it (`mix deps.update <dep>`); if there is no fixed version yet, tell the developer
  instead of ignoring it
- Before a pull request (or a direct push), run the `/security-review` skill when the changes
  touch `lib/`, `config/` or `priv/repo/migrations/`; fix what it finds, and ask the developer
  when a fix changes a rule. `/implement-spec` runs it once, at the end
- **Never** commit secrets (API keys, tokens, passwords): they go in `.env` and are read in
  `config/runtime.exs`. When the CI's gitleaks job finds one, tell the developer to revoke it
  first (it is already on GitHub), and only then remove it from the code
- The CI also scans the production image with Trivy (on `master` and weekly). When it fails,
  update the base images of the `Dockerfile` (the `BUILDER_IMAGE` and `RUNNER_IMAGE` versions);
  when there is no fixed version yet, tell the developer
- The Content-Security-Policy is set by `__APP_WEB__/plugs/content_security_policy.ex`, with a
  new nonce per request. Inline scripts need `nonce={@csp_nonce}`; prefer code in
  `assets/js` (or LiveView colocated hooks) and **never** use inline event handlers
  (`onclick=`) or `javascript:` URLs, which the policy blocks
- When adding an external resource (CDN script, font, image host, analytics, iframe), add only
  that origin to the matching directive, and only after the developer agrees to use it
<!-- auth:start -->
- Authentication was generated by `mix phx.gen.auth` (`Accounts` context, `User` schema,
  LiveView pages). Protect new routes with the `:require_authenticated_user` pipeline and
  the `{__APP_MODULE__Web.UserAuth, :require_authenticated}` `on_mount` hook, and scope every
  query to `current_scope.user` (see the authentication rules below)
- Its pages and emails were generated with English text: the first task that touches
  authentication translates them to Portuguese with `gettext` (see "Language")
<!-- auth:end -->

## Domain, specs and screens

- `GLOSSARY.md`, when it exists, is the source of the domain terms: use them in the names of
  contexts, schemas and functions. Each entry has the term in Portuguese, its English name in
  the code and a definition in Portuguese (e.g. "**Pedido** (`Order`): ..."). When a new term
  appears, or one conflicts with the glossary, ask the developer before using it and record
  the answer there. Architectural decisions go in `docs/adr/`
- Every screen comes from the user stories of a spec (an issue or a file in `docs/`). Before
  adding a screen to `docs/ui/screens.md`, find its spec; when there is none, ask the
  developer instead of inventing requirements
- List the screens of a spec with the `screens` skill (`.claude/skills/screens/SKILL.md`;
  agents without skills follow that file):
  - every story with a user interface has Given/When/Then acceptance criteria for the main
    path and, when they can happen, the empty and error states
  - specs with two or more screens get a flow in `docs/ui/flows/<spec-slug>.md`
  - the developer decides which screens are `Prototype: required`
- A spec is defined once its screens are listed. Its `required` screens are then prototyped
  and approved, and only after that is it broken into tickets
- Every acceptance criterion of a screen has a LiveView test
- When the developer asks what to do next or where the project stands, use the `next-step`
  skill (`.claude/skills/next-step/SKILL.md`): it reads the state and recommends one skill

## Tickets (tracer bullets)

- Every ticket is a tracer bullet: a thin path through every layer it needs (migration,
  schema and changeset, context function, route and LiveView rendering the approved
  component, and the LiveView tests of its criteria), landed with `mix precommit` green and
  visible in the browser. Never slice by layer (one ticket for the schemas, another for the
  LiveViews). The only exceptions are prefactoring (make the change easy first) and wide
  refactors, sequenced as expand, migrate and contract
- The first ticket of a spec is its skeleton: the main path of its central screen, with the
  smallest context function that feeds it and the test of the main criterion. It blocks the
  other tickets of that screen
- The tickets of a screen are sliced by its acceptance criteria, which are also its prototype
  states: each ticket points to the screen's entry in `docs/ui/screens.md`, lists the
  Given/When/Then criteria it closes and, for `Prototype: required`, the states to compare
  (`/dev/prototypes/<path>?state=<state>`). Every criterion belongs to exactly one ticket
- A ticket is done when its criteria pass as LiveView tests and the real route looks like the
  prototype states it lists
- A screen moves to `implemented` only when the last ticket that covers it is closed; until
  then it keeps its status
- Build each ticket test-first with `/tdd`: one test at an agreed seam (the context's public
  functions and the LiveView), the minimal code that passes it, then the next test. The first
  cycle is the ticket's tracer bullet; refactoring belongs to `/code-review`

## Design system and screens

- Before any UI work, read `docs/ui/design-system.md`. While its status is `not defined`, the
  first UI task is the design system setup, and no screen is prototyped or built before it.
  Set it up and change it with the `design-system` skill (`.claude/skills/design-system/SKILL.md`;
  agents without skills follow that file), from the daisyUI theme generator export in
  `docs/ui/themes/` (CSS files or a design system Markdown file). Only the developer sets the
  status to `defined`, after reviewing `/dev/components` in light and dark mode
- `assets/css/app.css` is the source of truth of the themes; the files in `docs/ui/themes/` are
  only the record of what was exported
- Use only the typography roles of the document, never ad hoc text sizes
- Text contrast is at least 4.5:1; after changing a theme color, measure again and update the table
- Use `font-display` only for page and section titles; everything else uses the default
  `font-sans`
- Never load fonts with external `<link>` tags (the Content-Security-Policy blocks them);
  fonts are self-hosted in `priv/static/fonts/`
- When creating or changing a reusable component, add it to `/dev/components` and to the
  components table
- Every screen is listed in `docs/ui/screens.md` before it is built:
  - `Prototype: none`: build it from the specs and the screen entry, set it to `implemented`
    and ask the developer to review it in the browser; only the developer sets `reviewed`
  - `Prototype: required`: its prototype is built and approved before the screen is built
    (see "Prototypes"); only the developer sets `approved`, and only approved screens are
    implemented. Once implemented, it follows the same review as `Prototype: none`
  - Keep the status up to date

## Prototypes

- A prototype is a screen built with fake data, for the developer to review in the browser
  before the real one is built. Build and change them with the `prototype-screen` skill
  (`.claude/skills/prototype-screen/SKILL.md`; agents without skills follow that file)
- Prototypes live in `dev/__APP___web/prototypes/` (compiled in dev and test only, never in
  the release), use `__APP_MODULE__Web.Prototypes` and are routed in the `:prototypes` live
  session of the router, under `/dev/prototypes`; their `render/1` has `@impl true`
- Fake data in plain maps inside the prototype: never call contexts, `Repo` or schemas
- States (`?state=`) come from the screen's acceptance criteria; variants (`?v=`) only to
  compare layouts, and the rejected ones are deleted after the choice
- Only the design system's resources, and the screen's text in Brazilian Portuguese through
  `gettext`. The dev pages (the index, the frames and the toolbar) are in English and are not
  translated
- After the approval, the screen's markup becomes a function component in
  `__APP_WEB__/components/<feature>_components.ex`: the real LiveView renders it with the
  real data and the prototype with its fake data. The real LiveView never copies the markup
- A prototype never decides a rule: when a change requested in its review alters an
  acceptance criterion, update the spec and the screen's entry before the approval
- When a screen changes, change its component and keep the prototype's states in sync with
  the acceptance criteria

## Language

- English for code (modules, functions, variables, database tables and columns, routes),
  comments, `@moduledoc`/`@doc`, commit messages, this file and the skills in `.claude/skills/`
- Brazilian Portuguese, with correct accents, for every other document: `README.md`,
  `GLOSSARY.md`, the ADRs in `docs/adr/`, the specs and their acceptance criteria, and
  `docs/ui/` (screens, flows and design system). They cite code, modules, functions, commands,
  paths, field names and status values by their original English names, never translated
  (e.g. "a tela chama `Orders.list_orders/1`", "status `approved`")
- Brazilian domain terms without a natural English translation (e.g. `cnpj`) may be kept as is
- User-facing text is in Brazilian Portuguese and **always** goes through Gettext,
  with the Portuguese text as the message id: `gettext("Meus pedidos")`.
  This includes page titles, labels, placeholders, buttons and flash messages
- The default locale is `pt_BR`; Ecto validation errors are translated in
  `priv/gettext/pt_BR/LC_MESSAGES/errors.po`
- Generators (`mix phx.gen.*`) create English UI text: translate it to Portuguese with
  `gettext` and update the generated tests that assert on those texts
