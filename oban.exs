Mix.install([
  {:ecto_sql, "~> 3.6.2"},
  {:postgrex, "~> 0.15.0"},
  {:oban, "~> 2.8"}
])

Application.put_env(:myapp, Repo,
  database: "mix_install_oban"
  # You may need the below depending on your setup. Uncomment as neeeded.
  # port: 5454,
  # username: "your_username",
  # password: "your_password"
)

defmodule Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :myapp
end

defmodule Migration0 do
  use Ecto.Migration

  def change do
    Oban.Migrations.up()
  end
end

defmodule Main do
  def main do
    children = [
      Repo,
      {Oban, repo: Repo, plugins: [Oban.Plugins.Pruner], queues: [default: 10]}
    ]

    Repo.__adapter__().storage_down(Repo.config())
    Repo.__adapter__().storage_up(Repo.config())
    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true)

    Oban.insert!(Worker.new(%{id: 1}))
    Oban.insert!(Worker.new(%{id: 2}))

    Oban.Job
    |> Repo.all()
    |> IO.inspect()
  end
end

defmodule Worker do
  use Oban.Worker

  @impl true
  def perform(%Oban.Job{}) do
    :ok
  end
end

Main.main()
