# Screens

Every screen is listed here before it is built (see "Design system and screens" in `AGENTS.md`).

- Design: `none` (built directly from the specs) or `required` (designed in `design/app.pen` first)
- Status with `Design: required`: `specified` → `designed` → `approved` (set by the developer
  only) → `implemented`
- Status with `Design: none`: `specified` → `implemented` → `reviewed` (set by the developer
  only, after checking it in the browser)

## <Screen name>

- Route: `/orders` — LiveView: `__APP_MODULE__Web.OrderLive.Index`
- Specs: <links to the product specs in `docs/`>
- Data shown: <...>
- Actions: <...>
- States: empty, loading, error, success
- Design: none
- Status: specified
