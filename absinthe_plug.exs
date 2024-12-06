Mix.install([
  {:absinthe, "~> 1.7"},
  {:absinthe_plug, "~> 1.5"},
  {:jason, "~> 1.4"},
  {:bandit, "~> 1.1"}
])

defmodule ContentTypes do
  use Absinthe.Schema.Notation

  object(:post) do
    field(:id, :id)
    field(:title, :string)
    field(:body, :string)
  end
end

defmodule Schema do
  use Absinthe.Schema

  import_types(ContentTypes)

  query do
    field :posts, list_of(:post) do
      resolve(fn _parent, _args, _context ->
        posts = [
          %{
            id: 1,
            title: "Foo",
            body: "Bar"
          }
        ]

        {:ok, posts}
      end)
    end
  end
end

defmodule Router do
  use Plug.Router
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Jason
  )

  forward("/api",
    to: Absinthe.Plug,
    init_opts: [schema: Schema]
  )
end

bandit = {Bandit, plug: Router, scheme: :http, port: 4000}
require Logger
Logger.info("starting #{inspect(bandit)}")
{:ok, _} = Supervisor.start_link([bandit], strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end

# Example request
# curl --request POST \
#   --url http://127.0.0.1:4000/api \
#   --data '{posts {id title}}'
