defmodule __APP_WEB_MODULE__.Prototypes.IndexLive do
  @moduledoc """
  Lists the screen prototypes, with links to each state, variant and to the frames.
  """
  use __APP_WEB_MODULE__, :live_view

  alias __APP_WEB_MODULE__.Prototypes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Prototypes", prototypes: Prototypes.list())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Prototypes
        <:subtitle>Screens with fake data, for review before they are built</:subtitle>
      </.header>

      <p :if={@prototypes == []} class="text-sm text-base-content/70">
        No prototypes yet: see "Prototypes" in AGENTS.md.
      </p>

      <ul class="space-y-4">
        <li :for={prototype <- @prototypes} class="rounded-box bg-base-200 p-4">
          <p class="font-semibold">{prototype.name}</p>
          <p class="text-xs text-base-content/70">{prototype.path}</p>
          <div class="mt-2 flex flex-wrap gap-2">
            <.link
              :for={state <- prototype.states}
              navigate={Prototypes.prototype_path(prototype.path, state, List.first(prototype.variants))}
              class="btn btn-xs"
            >
              {state}
            </.link>
            <.link
              :for={variant <- prototype.variants}
              navigate={Prototypes.prototype_path(prototype.path, List.first(prototype.states), variant)}
              class="btn btn-xs btn-secondary"
            >
              {variant}
            </.link>
            <.link
              navigate={~p"/dev/prototypes/frame?#{[path: prototype.path]}"}
              class="btn btn-xs btn-ghost"
            >
              Mobile and desktop
            </.link>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end
end
