# Screens

Every screen comes from the user stories of a spec and is listed here before it is built (see
"Domain, specs and screens" and "Design system and screens" in `AGENTS.md`).

- Prototype: `none` (built directly from the specs) or `required` (a prototype with fake data,
  under `/dev/prototypes`, is approved before it is built; see "Prototypes" in `AGENTS.md`)
- Status with `Prototype: required`: `specified` → `prototyped` → `approved` (set by the
  developer only) → `implemented` → `reviewed`
- Status with `Prototype: none`: `specified` → `implemented` → `reviewed` (set by the developer
  only, after checking it in the browser)
- Approved: the commit of the approved prototype, recorded when the status becomes `approved`

## <Screen name>

- Route: `/orders` — LiveView: `__APP_MODULE__Web.OrderLive.Index`
- Specs: <the user stories it covers: issue link or file in `docs/`, e.g. `#12 (stories 3, 4)`>
- Data shown: <...>
- Actions: <...>
- States: <from the acceptance criteria: empty, error, success>
- Flow: <`docs/ui/flows/<spec-slug>.md`, when the spec has two or more screens>
- Prototype: none
- Status: specified
