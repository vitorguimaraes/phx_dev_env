defmodule __APP_WEB_MODULE__.Prototypes do
  @moduledoc """
  Screen prototypes: dev-only LiveViews with fake data, served under `/dev/prototypes`
  (see "Prototypes" in `AGENTS.md`). The `dev/` folder is not compiled in production.

      defmodule __APP_WEB_MODULE__.Prototypes.OrderLive.Index do
        use __APP_WEB_MODULE__.Prototypes,
          name: "Lista de pedidos",
          states: ~w(filled empty error)

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <Layouts.app flash={@flash}>
            <OrderComponents.order_list orders={orders(@state)} />
          </Layouts.app>
          <.toolbar prototype={@prototype} />
          \"\"\"
        end
      end

  Each prototype is routed in the `:prototypes` live session of the router. The state
  (`?state=`) and the variant (`?v=`) of the URL are assigned as `@state` and `@variant`.
  """
  use __APP_WEB_MODULE__, :html

  defmacro __using__(opts) do
    quote do
      use __APP_WEB_MODULE__, :live_view

      import __APP_WEB_MODULE__.Prototypes, only: [toolbar: 1]

      @doc false
      def __prototype__, do: Map.new(unquote(opts))

      @impl true
      def handle_params(params, uri, socket) do
        {:noreply, __APP_WEB_MODULE__.Prototypes.assign_prototype(socket, __MODULE__, params, uri)}
      end

      defoverridable handle_params: 3
    end
  end

  @doc """
  Assigns `@state`, `@variant` and `@prototype` (used by `toolbar/1`) from the URL.

  Unknown states and variants fall back to the first one.
  """
  def assign_prototype(socket, module, params, uri) do
    config = module.__prototype__()
    states = Map.get(config, :states, ["default"])
    variants = Map.get(config, :variants, [])
    state = pick(params["state"], states)
    variant = pick(params["v"], variants)

    Phoenix.Component.assign(socket,
      state: state,
      variant: variant,
      prototype: %{
        name: config.name,
        path: URI.parse(uri).path,
        states: states,
        state: state,
        variants: variants,
        variant: variant,
        embed: params["embed"] == "1"
      }
    )
  end

  defp pick(value, [first | _] = values), do: if(value in values, do: value, else: first)
  defp pick(_value, []), do: nil

  @doc """
  Lists the routed prototypes, sorted by path.
  """
  def list do
    for %{path: path, metadata: %{phoenix_live_view: live_view}} <-
          Phoenix.Router.routes(__APP_WEB_MODULE__.Router),
        module = elem(live_view, 0),
        Code.ensure_loaded?(module) and function_exported?(module, :__prototype__, 0) do
      config = module.__prototype__()

      %{
        name: config.name,
        path: path,
        states: Map.get(config, :states, ["default"]),
        variants: Map.get(config, :variants, [])
      }
    end
    |> Enum.sort_by(& &1.path)
  end

  @doc """
  Prototype path with the given state and variant.
  """
  def prototype_path(path, state, variant) do
    query = Enum.reject([state: state, v: variant], fn {_key, value} -> is_nil(value) end)
    if query == [], do: path, else: path <> "?" <> URI.encode_query(query)
  end

  @doc """
  Dev toolbar of a prototype: state, variant, mobile and desktop frames and theme.

  Hidden inside the frames (`?embed=1`).
  """
  attr :prototype, :map, required: true

  def toolbar(%{prototype: %{embed: true}} = assigns), do: ~H""

  def toolbar(assigns) do
    ~H"""
    <nav
      aria-label="Prototype"
      class="fixed bottom-4 left-1/2 z-50 flex -translate-x-1/2 flex-wrap items-center gap-2 rounded-box bg-base-300 p-2 text-xs shadow-lg"
    >
      <.link navigate={~p"/dev/prototypes"} class="btn btn-ghost btn-xs">Prototypes</.link>
      <span class="font-semibold">{@prototype.name}</span>
      <div class="join">
        <.link
          :for={state <- @prototype.states}
          patch={prototype_path(@prototype.path, state, @prototype.variant)}
          class={["btn btn-xs join-item", state == @prototype.state && "btn-primary"]}
        >
          {state}
        </.link>
      </div>
      <div :if={@prototype.variants != []} class="join">
        <.link
          :for={variant <- @prototype.variants}
          patch={prototype_path(@prototype.path, @prototype.state, variant)}
          class={["btn btn-xs join-item", variant == @prototype.variant && "btn-secondary"]}
        >
          {variant}
        </.link>
      </div>
      <.link
        navigate={
          ~p"/dev/prototypes/frame?#{[path: prototype_path(@prototype.path, @prototype.state, @prototype.variant)]}"
        }
        class="btn btn-ghost btn-xs"
      >
        Mobile and desktop
      </.link>
      <Layouts.theme_toggle />
    </nav>
    """
  end
end
