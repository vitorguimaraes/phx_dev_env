---
name: design-system
description: Set up or change the project's design system from the daisyUI theme generator export (CSS files or a design system Markdown file) - apply the light and dark themes to app.css, measure the text contrast, fill docs/ui/design-system.md and build the /dev/components gallery for the developer to approve. Use when the developer asks to define, set up, import or change the design system, the theme or the colors.
argument-hint: <theme files or design system Markdown, default docs/ui/themes/>
---

# Design system

This step runs once, before the first screen is prototyped or built, and again whenever the
developer brings a new theme export. It can run in parallel with `/grill-with-docs`,
`/to-spec` and `/screens`, in its own conversation. It decides how the application looks; it
does not build screens.

## 1. Read the inputs

- The argument: one or more files, or a folder (default `docs/ui/themes/`). They can be:
  - CSS exported by the [daisyUI theme generator](https://daisyui.com/theme-generator/)
    (`@plugin "daisyui/theme" { ... }` blocks)
  - a Markdown file describing the design system (from the generator or written by hand):
    theme blocks or color tokens, and possibly the identity, the role of each color, spacing,
    radius and how to use the components
  - the same content pasted in the chat: save it in `docs/ui/themes/` first (`light.css`,
    `dark.css`, or `design-system-source.md` for Markdown) and work from the files
- Without an argument and with `docs/ui/themes/` empty, explain the export (section 1 of the
  `README.md`) and stop; never invent a theme
- `docs/ui/design-system.md` (its status), `assets/css/app.css` (the `light` and `dark` theme
  blocks, the fonts and `@theme`) and `core_components.ex`

## 2. Get the two themes

The project has exactly two themes, `light` and `dark`, and they share the radius, sizes,
border and effects; only the colors change.

- From a Markdown file, extract each theme into `docs/ui/themes/light.css` and
  `docs/ui/themes/dark.css` (oklch, hex or rgb values are fine; keep the original names of the
  variables). Keep the Markdown in `docs/ui/themes/` as the record of what was received
- When only one theme exists, ask whether to derive the other one: propose its colors (same
  hues, inverted lightness for the bases, contents that pass the contrast check) and write it
  only after the developer agrees
- When the radius, sizes, border or effects differ between the two, ask which ones to keep
- Guidance in the Markdown that conflicts with `AGENTS.md` (palette colors, hex values in the
  markup, other fonts, external resources) does not override it: list the conflicts and ask

## 3. Apply them

1. Copy only the variables of each file into the matching theme block of
   `assets/css/app.css`; keep the block names, the flags (`default`, `prefersdark`,
   `color-scheme`) and the plugin path (`daisyui/packages/bundle/daisyui-theme`, not the
   generator's `daisyui/theme`). When a file has a variable that the blocks do not have, ask
   before adding it. From then on `app.css` is the source of truth: later color fixes are made
   only there
2. Measure the contrast of every pair in the table of `docs/ui/design-system.md`, in both
   themes, with a script: convert the colors to sRGB and compute the WCAG ratio (for
   `base-content/70`, blend it over the background first); never estimate by eye. When a pair
   is below 4.5:1, propose a close shade that passes and ask before changing it
3. The fonts are already installed: Figtree (`--font-sans`) and Lato (`--font-display`) in
   `priv/static/fonts/` and `app.css`. Do not add or replace fonts without asking, even when
   the Markdown names others
4. Fill `docs/ui/design-system.md` in Brazilian Portuguese: identity (from the Markdown, or
   ask the developer for one sentence), contrast values, spacing, icons and components. Align
   the titles of the existing components (e.g. the `<h1>` of `<.header>`) with the typography
   roles
5. Create (or update) the dev-only `/dev/components` LiveView
   (`__APP_MODULE__Web.Prototypes.ComponentsLive` in `dev/__APP___web/prototypes/`, routed in
   the `:prototypes` live session) showing every component, text role, theme color and icon
   size

## 4. Check and hand it over

1. Run `mix precommit` and commit (`🎨 style: set up design system`, or
   `🎨 style(ui): update theme` for a later change)
2. Ask the developer to review
   `http://localhost:__APP_HOST_PORT__/dev/components` in light and dark mode
3. Apply the requested changes with the same checks (measure the contrast again after every
   color change). Only when the developer approves it, set the status to `defined` and commit
   (`📝 docs(ui): approve design system`)

When the theme changes after screens were prototyped, tell the developer which prototypes to
check again in `/dev/prototypes`. Then stop: the next step is `/prototype-screen <screen>` for
the `required` screens, or `/screens <spec>` when none is listed yet.
