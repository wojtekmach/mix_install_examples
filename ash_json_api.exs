Mix.install(
  [
    {:ash, "~> 3.0"},
    {:ash_json_api, "~> 1.0"},
    {:plug_cowboy, "~> 2.5"},
    {:open_api_spex, "~> 3.16"}
  ],
  consolidate_protocols: false
)

defmodule Accounts.Profile do
  use Ash.Resource,
    domain: Accounts,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "profile"
  end

  actions do
    defaults [:read, :destroy, create: [:name], update: [:name]]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end
end

defmodule Accounts do
  use Ash.Domain,
    extensions: [AshJsonApi.Domain],
    validate_config_inclusion?: false # only necessary in this context because there is no config

  json_api do
    prefix "/api"

    routes do
      base_route "/profiles",  Accounts.Profile do
        index :read
        get :read
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  resources do
    resource Accounts.Profile do
      define :all_profiles, action: :read
      define :profile_by_id, get_by: [:id], action: :read
      define :create_profile, args: [:name], action: :create
      define :update_profile, args: [:name], action: :update
      define :delete_profile, action: :destroy
    end
  end
end

defmodule Accounts.JsonApiRouter do
  use AshJsonApi.Router,
    domains: [Accounts],
    json_schema: "/json_schema",
    open_api: "/open_api"
end

defmodule Router do
  use Plug.Router
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  forward "/api/swaggerui",
    to: OpenApiSpex.Plug.SwaggerUI,
    init_opts: [
      path: "/api/open_api",
      default_model_expand_depth: 4
    ]

  forward "/api", to: Accounts.JsonApiRouter

  match _ do
    send_resp(conn, 404, "not found")
  end
end

plug_cowboy = {Plug.Cowboy, plug: Router, scheme: :http, port: 4000}
require Logger
{:ok, _} = Supervisor.start_link([plug_cowboy], strategy: :one_for_one)
Logger.info("Server started at http://localhost:4000")

unless IEx.started?() do
  Process.sleep(:infinity)
end
