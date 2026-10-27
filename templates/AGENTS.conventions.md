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
  It compiles with warnings as errors, formats, runs Credo, Sobelow and the tests
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

## Design system and screens

- Before any UI work, read `docs/ui/design-system.md`. While its status is `not defined`, the
  first UI task is the design system setup, and no screen is built before it:
  1. The developer provides the `light` and `dark` themes from the daisyUI theme generator
     and the font family (Google Fonts)
  2. Replace only the variables inside the `light` and `dark` theme blocks of
     `assets/css/app.css`; keep the block names and the plugin path
  3. Measure the contrast of every pair in the document's table, in both themes; when a pair
     is below 4.5:1, propose a close shade that passes and ask before changing it
  4. Self-host the font: `.woff2` files in `priv/static/fonts/`, `@font-face` in `app.css`
     and `--font-sans` in its `@theme`
  5. Fill the typography roles, spacing, radius, icons and components sections
  6. Create a dev-only `/dev/components` LiveView (next to `/dev/dashboard` in the
     `dev_routes` scope) showing every component, text role, theme color and icon size
  7. Set the status to `defined`, run `mix precommit` and commit (`🎨 style: define design system`)
- Use only the typography roles of the document, never ad hoc text sizes
- Text contrast is at least 4.5:1; after changing a theme color, measure again and update the table
- Never load fonts with external `<link>` tags; self-host them in `priv/static/fonts/`
- When creating or changing a reusable component, add it to `/dev/components` and to the
  components table
- Every screen is listed in `docs/ui/screens.md` before it is built:
  - `Design: none`: build it from the specs and the screen entry; the developer reviews it in
    the browser
  - `Design: required`: design it first (see "Design (pen.dev)"); only the developer sets
    `approved`, and only approved screens are implemented
  - Keep the status up to date

## Design (pen.dev)

Screens with `Design: required` are designed in `design/app.pen` with the pen.dev MCP tools
(the file must be open in VS Code with the Pencil extension; if the tools say no file is open,
ask the developer to reconnect the MCP with `/mcp`). These rules override pen.dev's own
code-generation guide (React, `:root` variables, `bg-[var(--x)]`, Google Fonts links)

- The design file copies the design system from the code, never the opposite. Before the first
  designed screen, mirror it: variables named like the daisyUI variables, in `light` and `dark`
  modes (`color-primary`, `color-primary-content`, ..., `color-base-100`, `color-base-content`,
  `radius-box`, `radius-field`, `radius-selector`, `font-sans`), with the values of
  `assets/css/app.css` converted from oklch to hex; and a component library mirroring the
  components table, named `core/<component>` and `layouts/app`. Compare each library
  component with `/dev/components` using a `browser` node
- Screens use only variables (never hex colors), library components, spacing in multiples
  of 4, the typography roles and `icon` nodes from the `lucide` library
- Each screen has a `<Screen> / mobile` (390px) and a `<Screen> / desktop` (1440px) frame, with
  real Brazilian Portuguese text and the empty and error states. Set the frame `context` to the
  route and LiveView (e.g. `/orders · __APP_MODULE__Web.OrderLive.Index`), then set the screen
  status to `designed`
- Implementing an approved screen:
  - `$color-<name>` → `bg-<name>` / `text-<name>` / `border-<name>`; `$radius-box` → `rounded-box`
  - pen.dev spacing → Tailwind scale (`gap-4`, `p-6`); never arbitrary `[Npx]` values
  - library components → the function components in `core_components.ex`
  - `icon` nodes → `<.icon name="lucide-<icon>">`. pen.dev may use older Lucide names: when
    `deps/lucide/icons/<icon>.svg` does not exist, find the current name in the `aliases` of
    the JSON files (e.g. `trash-2` → `trash`)
  - text → `gettext("...")`; never paste pen.dev's HTML export into the code
- Visual check: with the server running, add a `browser` node next to the frame pointing to
  `http://localhost:__APP_HOST_PORT__/<route>`, take screenshots of both (mobile and desktop)
  and fix the differences before `mix precommit`; then set the status to `implemented`

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
