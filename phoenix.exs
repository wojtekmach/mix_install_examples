# https://gist.github.com/Gazler/b4e92e9ab7527c7e326f19856f8a974a

Application.put_env(:phoenix, :json_library, Jason)

Application.put_env(:sample, SamplePhoenix.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "~> 1.6"}
])

defmodule SamplePhoenix.SampleController do
  use Phoenix.Controller

  def index(conn, _) do
    send_resp(conn, 200, "Hello, World!")
  end
end

defmodule Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", SamplePhoenix do
    pipe_through(:browser)

    get("/", SampleController, :index)

    # Prevent a horrible error because ErrorView is missing
    get("/favicon.ico", SampleController, :index)
  end
end

defmodule SamplePhoenix.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  plug(Router)
end

{:ok, _} = Supervisor.start_link([SamplePhoenix.Endpoint], strategy: :one_for_one)
Process.sleep(:infinity)
