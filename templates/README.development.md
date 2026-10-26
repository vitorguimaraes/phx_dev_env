
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

Visit [`localhost:4000`](http://localhost:4000). Run `make app.precommit` before committing.

Commit messages follow `<gitmoji> <type>(<scope>): <description>` and are validated by
`.githooks/commit-msg`. See `AGENTS.md` for the project conventions.
