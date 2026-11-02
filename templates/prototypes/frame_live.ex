defmodule __APP_WEB_MODULE__.Prototypes.FrameLive do
  @moduledoc """
  Shows a prototype in a mobile (390px) and a desktop (1440px, at 50%) frame, side by side.

  The frames share the theme of this page (the theme is kept in `localStorage`).
  """
  use __APP_WEB_MODULE__, :live_view

  @impl true
  def handle_params(params, _uri, socket) do
    path = params["path"] || ""

    if String.starts_with?(path, "/dev/prototypes/") do
      separator = if String.contains?(path, "?"), do: "&", else: "?"

      {:noreply,
       assign(socket, page_title: "Mobile and desktop", path: path, src: path <> separator <> "embed=1")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Unknown prototype")
       |> push_navigate(to: ~p"/dev/prototypes")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 p-4">
      <header class="mb-4 flex flex-wrap items-center gap-2">
        <.link navigate={~p"/dev/prototypes"} class="btn btn-ghost btn-sm">Prototypes</.link>
        <.link href={@path} class="link text-sm">{@path}</.link>
        <Layouts.theme_toggle />
      </header>

      <div class="flex flex-wrap items-start gap-6">
        <figure>
          <figcaption class="mb-2 text-xs text-base-content/70">Mobile · 390px</figcaption>
          <iframe
            src={@src}
            title="Mobile"
            class="rounded-box border border-base-300 bg-base-100"
            style="width: 390px; height: 844px"
          >
          </iframe>
        </figure>

        <figure>
          <figcaption class="mb-2 text-xs text-base-content/70">Desktop · 1440px at 50%</figcaption>
          <div
            class="overflow-hidden rounded-box border border-base-300"
            style="width: 720px; height: 450px"
          >
            <iframe
              src={@src}
              title="Desktop"
              class="origin-top-left bg-base-100"
              style="width: 1440px; height: 900px; transform: scale(0.5)"
            >
            </iframe>
          </div>
        </figure>
      </div>

      <Layouts.flash_group flash={@flash} />
    </div>
    """
  end
end
