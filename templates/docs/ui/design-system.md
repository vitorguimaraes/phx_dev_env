# Design system

Status: not defined   <!-- not defined | defined -->

Defined by the first UI task of the project: see "Design system" in `README.md` for what the
developer provides, and "Design system and screens" in `AGENTS.md` for the setup steps.

## Theme

- Source: `assets/css/app.css` (daisyUI themes `light` and `dark`)
- Identity: <short description of the brand and of each color's role>

### Contrast (WCAG: at least 4.5:1 for text)

| Pair | Light | Dark |
|---|---|---|
| `base-content` on `base-100` / `base-200` / `base-300` | | |
| `primary-content` on `primary` (same for secondary, accent, neutral) | | |
| `info` / `success` / `warning` / `error` on `base-100` | | |
| `<color>-content` on `<color>` for info, success, warning, error | | |

## Typography

- Families: <e.g. Inter (UI)>, self-hosted in `priv/static/fonts/`, set as `--font-sans` in `app.css`

| Role | Classes |
|---|---|
| Page title | `text-xl font-semibold` |
| Section title | `text-lg font-semibold` |
| Body | `text-sm` |
| Field label | `text-sm font-medium` |
| Caption / help | `text-xs text-base-content/70` |

## Spacing and radius

- Tailwind scale (multiples of 4px); page padding, section gap and form field gap: <values>
- Radius from the theme: `rounded-box` (cards, modals, tables), `rounded-field` (buttons,
  inputs), `rounded-selector` (checkboxes, badges)

## Icons

- Lucide with `<.icon name="lucide-...">`; sizes: <e.g. `size-4` inline, `size-5` in buttons>

## Components

| Component | Use for |
|---|---|
| `<.button>` | <variants and when to use each> |
| `<.input>` | <field types> |
| `<.table>` | <lists> |
| `<.header>` | <page header with title, subtitle and actions> |
| `<.list>` | <details> |
| `<.flash>` | <feedback messages> |

Visual reference: `/dev/components` (dev only)
