# Design

Screens marked `Design: required` in `docs/ui/screens.md` are designed in `design/app.pen`
with [pen.dev](https://pen.dev).

- Open `design/app.pen` in VS Code with the Pencil extension: the AI works on it through
  the pen.dev MCP server, which connects to VS Code. If the AI says no file is open,
  reconnect it with `/mcp` in Claude Code
- The design copies the design system defined in `docs/ui/design-system.md`
  (variables and a component library), never the opposite
- `.pen` files are encrypted: commit them, but their diffs are not readable

See "Design (pen.dev)" in `AGENTS.md` for the rules the AI follows.
