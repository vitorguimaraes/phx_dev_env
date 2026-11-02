---
name: prototype-screen
description: Build the prototype of a screen listed in docs/ui/screens.md as a dev-only LiveView with fake data under /dev/prototypes, with every state of its acceptance criteria, for the developer to review and approve in the browser. Use when the developer asks to prototype, mock up or design a screen, or to change a prototype.
argument-hint: <screen name or route>
---

# Prototype a screen

A prototype is the screen itself, built with the real components, theme, fonts and icons, but
fed with fake data. The developer reviews it in the browser; once approved, its markup becomes
the function component that the real LiveView renders. It decides how the screen looks and
behaves; it does not touch contexts, schemas or migrations.

## 1. Read the inputs

- The screen's entry in `docs/ui/screens.md` (the argument is its name or route). Without an
  argument, list the screens with `Prototype: required` and status `specified` and ask which
  one; never guess
- Its spec (the `Specs` field) and the Given/When/Then criteria of its stories, and its flow in
  `docs/ui/flows/`, when there is one
- `docs/ui/design-system.md`: while its status is `not defined`, stop and tell the developer
  that the design system comes first
- `GLOSSARY.md`, `core_components.ex` and `lib/__APP___web/components/`: reuse what exists
- The existing prototypes in `dev/__APP___web/prototypes/` and the `:prototypes` live session
  of the router

## 2. Build it

- One module per screen: the screen's LiveView name under `__APP_MODULE__Web.Prototypes`
  (`__APP_MODULE__Web.OrderLive.Index` → `__APP_MODULE__Web.Prototypes.OrderLive.Index`), in
  `dev/__APP___web/prototypes/order_live/index.ex`, with
  `use __APP_MODULE__Web.Prototypes, name: "<screen name>", states: ~w(...)` and `@impl true`
  on `render/1`
- Route it in the `:prototypes` live session: the screen's route under `/dev/prototypes`
  (`/orders` → `live "/prototypes/orders", OrderLive.Index`)
- States: one per criterion that changes what is shown (e.g. `filled`, `empty`, `error`,
  `not_found`), the main path first. `@state` holds the current one
- Fake data in the module, as plain maps (the schemas may not exist yet), with realistic
  Brazilian Portuguese content and enough rows to show long lists and long names
- Interactions are simulated in memory: forms validate with `to_form/2` and show real errors,
  modals open and close, flash messages appear. Links between screens of the same flow go to
  their prototypes (`~p"/dev/prototypes/..."`)
- Only the design system: components, typography roles, theme colors, the Tailwind scale,
  Lucide icons and `gettext` for every user-facing text; the real layout (`<Layouts.app>`,
  with a fake `current_scope` when the screen needs a user)
- Render `<.toolbar prototype={@prototype} />` after the layout
- Variants (`variants: ~w(a b)`, `@variant`) only when the developer asks to compare layouts,
  or when you recommend comparing two; delete the rejected ones after the choice

## 3. Check and hand it over

1. Run `mix precommit` (the prototypes test renders every state and variant)
2. Set the screen status to `prototyped` in `docs/ui/screens.md` and commit
   (`🎨 style(ui): prototype <screen>`)
3. Give the developer the links: `http://localhost:__APP_HOST_PORT__/dev/prototypes/<path>`,
   one per state, and the mobile and desktop frames (the toolbar has them too). Ask them to
   check both themes
4. Apply the requested changes with the same checks; only the developer sets `approved`

## 4. After the approval

When the developer approves it (status `approved`), record `Approved: <commit>` (the last
commit of the prototype) in the screen's entry and promote the markup:

- Move the screen's markup to a function component with `attr` and `slot` in
  `lib/__APP___web/components/<feature>_components.ex` (e.g. `order_list/1`), and make the
  prototype render it with its fake data. The prototype stays as the catalog of the screen's
  states
- The real LiveView, built in the screen's ticket, renders the same component with the real
  data; it never copies the markup
- When the screen changes later, change the component and keep the prototype's states in sync
  with the criteria
- Run `mix precommit` (the prototype must look the same) and commit
  (`♻️ refactor(ui): extract <screen> component`)

Then stop: the real LiveView, contexts and tests belong to the tickets.
