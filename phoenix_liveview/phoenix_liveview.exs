Application.put_env(:phoenix, :json_library, Jason)
Application.put_env(:esbuild, :version, "0.12.18")

Mix.install(
  deps = [
    {:phoenix, "~> 1.6.0-rc.0", override: true},
    :jason,
    :plug_cowboy,
    {:phoenix_live_view, "~> 0.16.0"},
    {:esbuild, "~> 0.2"}
  ]
)

defmodule InstallFolderTemporaryBackport do
  # temporary backport from code at https://github.com/elixir-lang/elixir/blob/7e4d934d164f8280bbc71759789db92c7260ac07/lib/mix/lib/mix.ex#L575
  def determine_build_folder(deps) do
    build_id = compute_build_id(deps)
    base_folder = Path.join(Mix.Utils.mix_cache(), "installs")
    runtime_version = "elixir-#{System.version()}-erts-#{:erlang.system_info(:version)}"

    base_folder
    |> Path.join(runtime_version)
    |> Path.join(build_id)
  end

  def compute_build_id(deps) do
    deps =
      Enum.map(deps, fn
        dep when is_atom(dep) ->
          {dep, ">= 0.0.0"}

        {app, opts} when is_atom(app) and is_list(opts) ->
          {app, maybe_expand_path_dep(opts)}

        {app, requirement, opts} when is_atom(app) and is_binary(requirement) and is_list(opts) ->
          {app, requirement, maybe_expand_path_dep(opts)}

        other ->
          other
      end)

    deps |> :erlang.term_to_binary() |> :erlang.md5() |> Base.encode16(case: :lower)
  end

  def maybe_expand_path_dep(opts) do
    if Keyword.has_key?(opts, :path) do
      Keyword.update!(opts, :path, &Path.expand/1)
    else
      opts
    end
  end
end

Application.put_env(:esbuild, :default,
  args: ~w(app.js --bundle --target=es2016 --outdir=../priv/static/assets),
  cd: Path.expand("assets", __DIR__),
  env: %{"NODE_PATH" => InstallFolderTemporaryBackport.determine_build_folder(deps) <> "/deps"}
)

Application.put_env(:my_app, MyApp.Endpoint,
  server: true,
  http: [ip: {127, 0, 0, 1}, port: 8081],
  secret_key_base: "vuLgz/lXn+03HJIPTHbTMeZGd16UzvFxLgThphnLdafNmlZqCSGEZJe3Hp9cRhVs",
  live_view: [signing_salt: "xF2dLhep"],
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]
)

defmodule SimpleWeb.ClockLive do
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

defmodule SimpleWeb.LayoutView do
  use Phoenix.View,
    root: "templates",
    namespace: SimpleWeb

  use Phoenix.HTML
  alias MyApp.Router.Helpers, as: Routes
end

defmodule MyApp.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {SimpleWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through([:browser])
    live("/", SimpleWeb.ClockLive)
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
    from: "priv/static",
    gzip: false,
    only: ~w(assets)
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

{:ok, _pid} = MyApp.Endpoint.start_link()

unless IEx.started?() do
  Process.sleep(:infinity)
end
