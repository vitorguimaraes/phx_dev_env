defmodule __APP_WEB_MODULE__.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Sets the Content-Security-Policy header with a new nonce for every request.

  Inline scripts run only with the nonce, available in the templates as `@csp_nonce`:

      <script nonce={@csp_nonce}>...</script>

  Inline styles are allowed: `style` attributes cannot use a nonce, and a nonce in
  `style-src` would make browsers ignore `'unsafe-inline'`.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy(nonce))
  end

  # add an origin to a directive only when an external resource is really needed
  defp policy(nonce) do
    Enum.join(
      [
        "default-src 'self'",
        "script-src 'self' 'nonce-#{nonce}'",
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' data: blob:",
        "font-src 'self' data:",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'self'"
      ],
      "; "
    )
  end
end
