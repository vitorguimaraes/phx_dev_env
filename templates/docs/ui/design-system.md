# Design system

Status: not defined   <!-- not defined | defined (só depois que a pessoa desenvolvedora aprova o /dev/components) -->

Definido pela primeira tarefa de UI do projeto: veja "1. Design system" no `README.md` para o que
a pessoa desenvolvedora fornece, e "Design system and screens" no `AGENTS.md` para os passos da
configuração.

## Tema

- Fonte: `assets/css/app.css` (temas `light` e `dark` do daisyUI)
- Exportação do gerador: `docs/ui/themes/light.css` e `docs/ui/themes/dark.css` (o ponto de
  partida; os ajustes seguintes são feitos só no `app.css`)
- Identidade: <descrição curta da marca e do papel de cada cor>

### Contraste (WCAG: no mínimo 4.5:1 para texto)

| Par | Claro | Escuro |
|---|---|---|
| `base-content` sobre `base-100` / `base-200` / `base-300` | | |
| `base-content/70` (legendas) sobre `base-100` / `base-200` | | |
| `primary-content` sobre `primary` (o mesmo para secondary, accent, neutral) | | |
| `info` / `success` / `warning` / `error` sobre `base-100` | | |
| `<color>-content` sobre `<color>` para info, success, warning, error | | |

## Tipografia

- Famílias (servidas pelo projeto em `priv/static/fonts/`, com `@font-face` e `@theme` no `app.css`):
  - Figtree (variável, de 300 a 900, normal e itálico): `--font-sans`, a interface e os textos
  - Lato (400 e 700): `--font-display` (classe `font-display`), só nos títulos de página e de seção

| Papel | Classes |
|---|---|
| Título da página | `font-display text-xl font-bold` |
| Título de seção | `font-display text-lg font-bold` |
| Texto | `text-sm` |
| Rótulo de campo | `text-sm font-medium` |
| Legenda / ajuda | `text-xs text-base-content/70` |

## Espaçamento e raio

- Escala do Tailwind (múltiplos de 4px); padding da página, espaço entre seções e entre campos
  de formulário: <valores>
- Raio do tema: `rounded-box` (cards, modais, tabelas), `rounded-field` (botões, inputs),
  `rounded-selector` (checkboxes, badges)

## Ícones

- Lucide com `<.icon name="lucide-...">`; tamanhos: <ex.: `size-4` no texto, `size-5` em botões>

## Componentes

| Componente | Uso |
|---|---|
| `<.button>` | <variantes e quando usar cada uma> |
| `<.input>` | <tipos de campo> |
| `<.table>` | <listas> |
| `<.header>` | <cabeçalho da página com título, subtítulo e ações> |
| `<.list>` | <detalhes> |
| `<.flash>` | <mensagens de feedback> |

Referência visual: `/dev/components` (só em dev)
