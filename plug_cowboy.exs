Mix.install([
  {:plug_cowboy, "~> 2.5"}
])

defmodule Router do
  use Plug.Router
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello, World!")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

plug_cowboy = {Plug.Cowboy, plug: Router, scheme: :http, port: 4000}
require Logger
Logger.info("starting #{inspect(plug_cowboy)}")
{:ok, _} = Supervisor.start_link([plug_cowboy], strategy: :one_for_one)
System.no_halt(true)
