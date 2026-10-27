defmodule __APP_WEB_MODULE__.Plugs.ContentSecurityPolicyTest do
  use __APP_WEB_MODULE__.ConnCase, async: true

  alias __APP_WEB_MODULE__.Plugs.ContentSecurityPolicy

  test "allows only the scripts with the request nonce", %{conn: conn} do
    conn = ContentSecurityPolicy.call(conn, [])

    assert [policy] = get_resp_header(conn, "content-security-policy")
    assert policy =~ "script-src 'self' 'nonce-#{conn.assigns.csp_nonce}';"
    refute policy =~ "script-src 'self' 'unsafe-inline'"
  end

  test "uses a new nonce for every request", %{conn: conn} do
    first = ContentSecurityPolicy.call(conn, [])
    second = ContentSecurityPolicy.call(conn, [])

    assert byte_size(first.assigns.csp_nonce) >= 24
    assert first.assigns.csp_nonce != second.assigns.csp_nonce
  end

  test "renders the nonce in the inline scripts of the root layout", %{conn: conn} do
    conn = get(conn, ~p"/")
    nonce = conn.assigns.csp_nonce

    assert html_response(conn, 200) =~ ~s(<script nonce="#{nonce}">)
  end
end
