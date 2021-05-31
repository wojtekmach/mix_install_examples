Mix.install([
  {:ecto_sql, "~> 3.6.2"},
  {:postgrex, "~> 0.15.0"}
])

Application.put_env(:foo, Repo, database: "")

defmodule Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :foo
end

defmodule Migration0 do
  use Ecto.Migration

  def change do
    create table("posts") do
      add(:title, :string)
      timestamps(type: :utc_datetime_usec)
    end
  end
end

defmodule Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    timestamps(type: :utc_datetime_usec)
  end
end

defmodule Main do
  def main do
    children = [
      Repo
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Repo.query!("DROP TABLE IF EXISTS schema_migrations")
    Repo.query!("DROP TABLE IF EXISTS posts")
    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true, log_sql: :debug)
    Repo.insert!(%Post{title: "Hello, World!"})

    IO.inspect(Repo.all(Post))
  end
end

Main.main()
