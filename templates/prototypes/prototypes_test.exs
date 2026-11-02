defmodule __APP_WEB_MODULE__.PrototypesTest do
  use __APP_WEB_MODULE__.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias __APP_WEB_MODULE__.Prototypes

  test "lists the prototypes", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/dev/prototypes")

    for prototype <- Prototypes.list() do
      assert html =~ prototype.name
    end
  end

  test "renders every state and variant of every prototype", %{conn: conn} do
    for prototype <- Prototypes.list(),
        state <- prototype.states,
        variant <- if(prototype.variants == [], do: [nil], else: prototype.variants) do
      path = Prototypes.prototype_path(prototype.path, state, variant)

      assert {:ok, _view, _html} = live(conn, path), "#{path} does not render"
    end
  end

  test "shows a prototype in the mobile and desktop frames", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/dev/prototypes/frame?#{[path: "/dev/prototypes/orders"]}")

    assert html =~ ~s(src="/dev/prototypes/orders?embed=1")
  end

  test "frames only the prototypes", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/dev/prototypes"}}} =
             live(conn, ~p"/dev/prototypes/frame?#{[path: "https://example.com"]}")
  end
end
