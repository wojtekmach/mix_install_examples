Mix.install([:tesla])

defmodule HexClient do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://hex.pm/api")
  plug(Tesla.Middleware.Headers, [{"user-agent", "tesla"}])
end

HexClient.get("/packages/tesla")
|> IO.inspect()
