---
name: next-step
description: Read the state of the project (design system, glossary, specs, screens, prototypes, tickets and the git branch) and tell the developer which step of the building workflow comes next and which skill to run. Use when the developer asks what to do next, where the project stands, which skill to use, or is picking the project up after a break.
argument-hint: <optional spec, to look only at it>
---

# Next step

A read-only check of where the project stands in the building workflow of the `README.md`
("Construção da aplicação"). It changes no file, runs no other skill and makes no commit: it
reports and recommends, and the developer runs the next skill.

## 1. Read the state

Read only what exists; a missing file is information, not an error.

- `docs/ui/design-system.md`: its status (`not defined` or `defined`), and whether
  `docs/ui/themes/` has an export (CSS or Markdown) waiting to be applied
- `GLOSSARY.md` and `docs/adr/`: whether the domain was ever discussed
- The specs: where `/setup-matt-pocock-skills` put them (GitHub issues, with
  `gh issue list --state open`, or files in `docs/`); with an argument, only that spec
- `docs/ui/screens.md` and `docs/ui/flows/`: every screen with its `Specs`, `Prototype` and
  `Status`
- The tickets of each spec (issues or files, as above) and which ones are open or blocked
- `git status` and `git log --oneline -10`: uncommitted work and the current branch

## 2. Find the step

For each spec, the first rule that matches is its step:

| State | Step | Skill |
|---|---|---|
| No spec, no glossary | Domain | `/grill-with-docs <idea>`, then `/to-spec` and `/screens` in the same conversation |
| A spec without entries in `screens.md` | Screens | `/screens <spec>` (with `/grill-with-docs` first when there is no `GLOSSARY.md`) |
| `required` screens `specified` and the design system `not defined` | Design system | `/design-system` (the screens wait for it) |
| `required` screens `specified` or `prototyped` | Prototype | `/prototype-screen <screen>`, one conversation per screen; `prototyped` ones wait for the developer's review |
| All `required` screens `approved` (or none `required`), no tickets | Tickets | `/to-tickets <spec>` |
| Open tickets | Implementation | `/implement <ticket>` for the first unblocked one (the skeleton first), or `/implement-spec <spec>` |
| Screens `implemented` | Review | the developer checks them in the browser and sets `reviewed` (optionally after `/web-design-guidelines`) |
| All tickets closed, branch not merged | Pull request | `/pr` |
| All screens `reviewed` and merged | Retrospective / next feature | `/retro` in the implementation conversation, then `/grill-with-docs` for the next feature |

Independently of the specs, the design system is a step of its own while it is `not defined`:
recommend it in parallel with the domain and screens steps, never after the prototypes.

For each screen with tickets, report its progress (e.g. "Lista de pedidos: 2 de 4 tickets
fechados, faltam os critérios de vazio e de autorização").

Flag what breaks the workflow instead of skipping it: a screen past `specified` without a
spec, a `required` screen being implemented without `approved`, tickets created before every
`required` screen was approved, tickets sliced by layer (e.g. "create the schemas", "build
the LiveViews") instead of tracer bullets, a spec without a skeleton ticket, an acceptance
criterion that no ticket covers, a screen `implemented` while one of its tickets is open,
uncommitted work, or `docs/ui/themes/` newer than the last change to `app.css`.

## 3. Report

In Brazilian Portuguese, short:

1. One line per spec: its step and the status of its screens (e.g. "#12 Pedidos: protótipo,
   2 de 3 telas `approved`")
2. The design system status
3. The screens by status, in one compact table with a column per status in the workflow
   order and the screens' names in the cells (`Prototype: required` ones marked with `*`);
   leave out the columns with no screen, and skip the table when there is no screen yet:

   | specified | prototyped | approved | implemented | reviewed |
   |---|---|---|---|---|
   | Novo pedido* | Lista de pedidos* | Detalhe do pedido* (tickets 1/3) | Lista de clientes | Entrar |
   | Cadastro de cliente | | | Painel de vendas* ⚠ | |

   Next to a screen, add its ticket progress when it has tickets, and ⚠ when it has a
   problem listed below. List the entries of `docs/ui/screens.md` that could not be read
   (missing `Route` or `Status`, or an unknown status) under the table, never drop them
4. The problems found, if any
5. **The next step**: one skill, with its argument, and whether it needs a new conversation
   (`/clear`). When two steps can run in parallel (the design system and a spec), say so

Then stop and wait for the developer.
