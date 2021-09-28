Application.put_env(:phoenix, :json_library, Jason)
Application.put_env(:esbuild, :version, "0.12.18")

Mix.install([
  {:phoenix, "~> 1.6.0"},
  :jason,
  :plug_cowboy,
  {:phoenix_live_view, "~> 0.16.0"},
  {:esbuild, "~> 0.3.0"}
])

Application.put_env(:esbuild, :default,
  args: ~w(app.js --bundle --target=es2016 --outdir=../priv/static/assets),
  cd: Path.expand("assets", __DIR__),
  env: %{"NODE_PATH" => Path.expand(Application.app_dir(:phoenix, "../../../../deps"))}
)

Application.put_env(:live_clock, LiveClock.Endpoint,
  server: true,
  http: [ip: {127, 0, 0, 1}, port: 8081],
  secret_key_base: "vuLgz/lXn+03HJIPTHbTMeZGd16UzvFxLgThphnLdafNmlZqCSGEZJe3Hp9cRhVs",
  live_view: [signing_salt: "xF2dLhep"],
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]
)

defmodule LiveClock.ClockLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  def render(assigns) do
    ~L"""
    <div id="svg-container">
      <svg id="clock" width="600" height="650">
        <g transform="scale(3)">
          <circle style="fill: #9ab" cx="102" cy="102" r="83"/>
          <circle style="fill: #666" cx="100" cy="100" r="83"/>
          <circle style="fill: #FFF" cx="100" cy="100" r="77"/>
          <%= for h <- (0..59) do %>
          <line style="stroke: #eee; stroke-width: 1px" x1="100" y1="28" x2="100" y2="34" transform="rotate(<%= 360 * h / 60.0 %> 100 100)"/>
          <% end %>
          <%= for h <- (0..11) do %>
          <line style="stroke: #aaa; stroke-width: 1px" x1="100" y1="28" x2="100" y2="35" transform="rotate(<%= 360 * h / 12.0 %> 100 100)"/>
          <% end %>
          <line style="stroke: #888; stroke-width: 3px" x1="100" y1="100" x2="100" y2="50"
            transform="rotate(<%= 360 * (@date.hour + @date.minute / 60.0) / 12.0 %> 100 100)"/>
          <line style="stroke: #888; stroke-width: 3px" x1="100" y1="100" x2="100" y2="27"
            transform="rotate(<%= 360 * (@date.minute + @date.second / 60.0) / 60.0 %> 100 100)"/>
          <line style="stroke: #E88; stroke-width: 1px" x1="100" y1="100" x2="100" y2="27"
            transform="rotate(<%= 360 * @date.second / 60.0 %> 100 100)"/>
        </g>
        <text x="130" y="585" font-family="cursive" font-size="17" style="fill: #789">
           The "almost-one-file" Phoenix LiveView clock app
        </text>
      </svg>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(100, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  defp put_date(socket) do
    assign(socket, date: NaiveDateTime.local_now())
  end
end

defmodule LiveClock.LayoutView do
  use Phoenix.View,
    root: "templates",
    namespace: LiveClock

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  alias LiveClock.Router.Helpers, as: Routes

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <%= csrf_meta_tag() %>
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/assets/app.css")}/>
        <script defer phx-track-static type="text/javascript" src={Routes.static_path(@conn, "/assets/app.js")}></script>
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end

defmodule LiveClock.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {LiveClock.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through([:browser])
    live("/", LiveClock.ClockLive)
  end
end

defmodule LiveClock.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_clock

  @session_options [
    store: :cookie,
    key: "_live_clock_app_key",
    signing_salt: "AD36PbaZ"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static,
    at: "/",
    from: "priv/static",
    gzip: false,
    only: ~w(assets)
  )

  plug(Plug.Session, @session_options)
  plug(LiveClock.Router)
end

{:ok, _pid} = LiveClock.Endpoint.start_link()

unless IEx.started?(), do: Process.sleep(:infinity)
