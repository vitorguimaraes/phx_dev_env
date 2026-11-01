# Design

`themes/light.css` and `themes/dark.css` hold the themes exported from the
[daisyUI theme generator](https://daisyui.com/theme-generator/) for the design system setup
(see "Building the application" in `README.md`).

Screens marked `Design: required` in `docs/ui/screens.md` are designed in `design/app.pen`
with [pen.dev](https://pen.dev).

- Before the first designed screen, create `design/app.pen` with the Pencil extension in
  VS Code (new file, saved in this folder)
- Keep `design/app.pen` open in VS Code while the AI works on it: the AI uses the pen.dev MCP
  server, which connects to VS Code. If the AI says no file is open, reconnect it with `/mcp`
  in Claude Code
- The design copies the design system defined in `docs/ui/design-system.md`
  (variables and a component library), never the opposite
- `.pen` files are encrypted: commit them, but their diffs are not readable

See "Design (pen.dev)" in `AGENTS.md` for the rules the AI follows.
