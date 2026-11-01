# Screens

Every screen comes from the user stories of a spec and is listed here before it is built (see
"Domain, specs and screens" and "Design system and screens" in `AGENTS.md`).

- Design: `none` (built directly from the specs) or `required` (designed in `design/app.pen` first)
- Status with `Design: required`: `specified` → `designed` → `approved` (set by the developer
  only) → `implemented`
- Status with `Design: none`: `specified` → `implemented` → `reviewed` (set by the developer
  only, after checking it in the browser)

## <Screen name>

- Route: `/orders` — LiveView: `__APP_MODULE__Web.OrderLive.Index`
- Specs: <the user stories it covers: issue link or file in `docs/`, e.g. `#12 (stories 3, 4)`>
- Data shown: <...>
- Actions: <...>
- States: <from the acceptance criteria: empty, error, success>
- Flow: <`docs/ui/flows/<spec-slug>.md`, when the spec has two or more screens>
- Design: none
- Status: specified
