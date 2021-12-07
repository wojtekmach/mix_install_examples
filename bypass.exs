Mix.install([
  :bypass,
  :req
])

ExUnit.start()

defmodule BypassTest do
  use ExUnit.Case, async: true

  test "bypass" do
    bypass = Bypass.open()

    Bypass.expect(bypass, "GET", "/", fn conn ->
      Plug.Conn.send_resp(conn, 200, "ok")
    end)

    assert Req.get!("http://localhost:#{bypass.port}").body == "ok"
  end
end
