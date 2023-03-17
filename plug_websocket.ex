Mix.install([
  {:plug, "~> 1.14"},
  {:bandit, "~> 0.6"},
  {:websock_adapter, "~> 0.5"}
])

defmodule EchoServer do
  def init(_args) do
    {:ok, []}
  end

  def handle_in({"ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end

  def terminate(:timeout, state) do
    {:ok, state}
  end
end

defmodule Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
    Output: <div id="output"></div>

    <script type="text/javascript">
    output = document.getElementById("output")
    sock = new WebSocket("ws://localhost:4000/websocket")
    sock.addEventListener("message", (message) =>
      output.append(message.data)
    )
    sock.addEventListener("open", () =>
      setInterval(() => sock.send("ping"), 1000)
    )
    </script>
    """)
  end

  get "/websocket" do
    conn
    |> WebSockAdapter.upgrade(EchoServer, [], timeout: 60_000)
    |> halt()
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

require Logger
webserver = {Bandit, plug: Router, scheme: :http, port: 4000}
{:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
Logger.info("Plug now running on localhost:4000")

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
