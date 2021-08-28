# Initial skeleton copied from https://gist.github.com/teamon/a964dd80bc5c6802e3a8548efdda9cff

Mix.install([
  {:phoenix, "~> 1.6.0-rc.0", override: true},
  :jason,
  :plug_cowboy,
  {:phoenix_live_view, "~> 0.16.0"}
])

Application.put_env(:phoenix, :json_library, Jason)
Application.put_env(:my_app, MyApp.Endpoint, server: true, http: [port: 8081])

defmodule MyApp.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/", MyApp do
    pipe_through([:browser])
    get("/", PostsController, :new)
  end
end

defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "AD36PbaZ"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static,
    at: "/",
    from: :simple,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(MyApp.Router)
end

defmodule MyApp.PostsController do
  use Phoenix.Controller, namespace: MyApp

  def new(conn, _params) do
    conn
    |> json(%{hello: "world"})
  end
end

{:ok, pid} = MyApp.Endpoint.start_link()

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
