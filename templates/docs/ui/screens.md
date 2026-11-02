# Telas

Toda tela vem das user stories de uma spec e é listada aqui antes de ser construída (veja
"Domain, specs and screens" e "Design system and screens" no `AGENTS.md`). Os nomes dos campos
e os valores de status ficam em inglês: as skills e o `AGENTS.md` dependem deles.

- Prototype: `none` (construída direto a partir das specs) ou `required` (um protótipo com
  dados falsos, em `/dev/prototypes`, é aprovado antes de ela ser construída; veja "Prototypes"
  no `AGENTS.md`)
- Status com `Prototype: required`: `specified` → `prototyped` → `approved` (definido só pela
  pessoa desenvolvedora) → `implemented` → `reviewed`
- Status com `Prototype: none`: `specified` → `implemented` → `reviewed` (definido só pela
  pessoa desenvolvedora, depois de conferir a tela no navegador)
- Approved: o commit do protótipo aprovado, registrado quando o status vira `approved`

## <Nome da tela>

- Route: `/orders` — LiveView: `__APP_MODULE__Web.OrderLive.Index`
- Specs: <as user stories que ela cobre: link da issue ou arquivo em `docs/`, ex.: `#12 (stories 3, 4)`>
- Data shown: <...>
- Actions: <...>
- States: <dos critérios de aceite: vazio, erro, sucesso>
- Flow: <`docs/ui/flows/<spec-slug>.md`, quando a spec tem duas ou mais telas>
- Prototype: none
- Status: specified
