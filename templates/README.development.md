
## Development

This project runs in Docker: Elixir and Erlang are not needed on the host.

After cloning, run once:

```bash
cp .env.example .env
git config core.hooksPath .githooks
```

Start the services and the server:

- `./scripts/dev.sh` opens a shell in the app container; then run `mix setup` and `make app`
- Or, from the host with `make` installed: `make up`, `make app.setup` and `make app`

Visit [`localhost:__APP_HOST_PORT__`](http://localhost:__APP_HOST_PORT__) (`APP_HOST_PORT` in `.env`). Run `make app.precommit` before committing:
it compiles with warnings as errors, formats the code and runs Credo, Sobelow and the tests.

Commit messages follow `<gitmoji> <type>(<scope>): <description>` and are validated by
`.githooks/commit-msg`. See `AGENTS.md` for the project conventions.

## Design system

Define it before building the first screen. The AI does the setup; you provide the identity:

1. **Theme**: create a `light` and a `dark` theme in the
   [daisyUI theme generator](https://daisyui.com/theme-generator/) (colors, radius, sizes,
   border) and copy the CSS of each one
2. **Font**: choose one family (optionally a second one for headings) in
   [Google Fonts](https://fonts.google.com); prefer a variable font
3. **Ask the AI**: "define the design system", pasting both themes and the font name.
   It applies the theme to `assets/css/app.css`, checks the text contrast (asking before
   changing any color), self-hosts the font, fills `docs/ui/design-system.md` and creates a
   component gallery
4. **Review** the gallery at
   [`localhost:__APP_HOST_PORT__/dev/components`](http://localhost:__APP_HOST_PORT__/dev/components)
   in light and dark mode, and ask for changes until you approve it

Then list the screens in `docs/ui/screens.md`. Mark `Design: required` only for screens whose
look needs to be decided first (they are designed in `design/app.pen` with pen.dev, see
`design/README.md`); the others are built directly from the specs and reviewed in the browser.
