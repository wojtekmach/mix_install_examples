Mix.install([
  {:bandit, ">= 0.0.0"}
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

bandit = {Bandit, plug: Router, scheme: :http, port: 4000}
require Logger
Logger.info("starting #{inspect(bandit)}")
{:ok, _} = Supervisor.start_link([bandit], strategy: :one_for_one)
System.no_halt(true)
