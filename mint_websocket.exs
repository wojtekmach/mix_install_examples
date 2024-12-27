Mix.install([
  {:mint_web_socket, "~> 1.0"},
  {:bandit, "~> 1.0"},
  {:websock_adapter, "~> 0.5.8"}
])

defmodule UpcaseServer do
  def init(_args) do
    {:ok, nil}
  end

  def handle_in({text, [opcode: :text]}, state) do
    {:reply, :ok, {:text, String.upcase(text)}, state}
  end
end

{:ok, _pid} =
  Bandit.start_link(
    port: 9999,
    plug: fn conn, _ ->
      WebSockAdapter.upgrade(conn, UpcaseServer, [], timeout: 60_000)
    end,
    startup_log: false
  )

{:ok, conn} = Mint.HTTP.connect(:http, "localhost", 9999)
{:ok, conn, ref} = Mint.WebSocket.upgrade(:ws, conn, "/", [])

message =
  receive do
    message -> message
  end

{:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, headers}, {:done, ^ref}]} =
  Mint.WebSocket.stream(conn, message)

{:ok, conn, ws} =
  Mint.WebSocket.new(conn, ref, status, headers)

{:ok, ws, data} = Mint.WebSocket.encode(ws, {:text, "hello"})
{:ok, conn} = Mint.WebSocket.stream_request_body(conn, ref, data)

message =
  receive do
    message -> message
  end

{:ok, conn, [{:data, ^ref, data}]} = Mint.WebSocket.stream(conn, message)
{:ok, ws, messages} = Mint.WebSocket.decode(ws, data)
_ = conn
_ = ws
dbg(messages)
