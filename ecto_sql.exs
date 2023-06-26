Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

Application.put_env(:foo, Repo, database: "mix_install_examples")

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
  import Ecto.Query, warn: false

  def main do
    children = [
      Repo
    ]

    _ = Repo.__adapter__().storage_down(Repo.config())
    :ok = Repo.__adapter__().storage_up(Repo.config())

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true, log_migrations_sql: :debug)
    Repo.insert!(%Post{title: "Hello, World!"})

    from(Post)
    |> Repo.all()
    |> IO.inspect()
  end
end

Main.main()
