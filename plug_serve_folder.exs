Mix.install([
  {:plug_cowboy, "~> 2.5"}
])

defmodule Router do
  use Plug.Router
  plug(Plug.Logger)
  plug(Plug.Static, from: ".", at: "/")
  plug(:match)
  plug(:dispatch)

  get "/" do
    content = (["Available files:"] ++ Path.wildcard("*")) |> Enum.join("\n")
    send_resp(conn, 200, content)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

plug_cowboy = {Plug.Cowboy, plug: Router, scheme: :http, port: port = 4000}
require Logger
Logger.info("Server available at http://127.0.0.1:#{port}")
{:ok, _} = Supervisor.start_link([plug_cowboy], strategy: :one_for_one)

Process.sleep(:infinity)
