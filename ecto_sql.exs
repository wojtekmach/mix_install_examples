Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
  # {:myxql, ">= 0.0.0"}
  # {:ecto_sqlite3, "~> 0.17"}
])

Application.put_env(:myapp, Repo, database: "mix_install_examples")

defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres, otp_app: :myapp
  # use Ecto.Repo, adapter: Ecto.Adapters.MyXQL, otp_app: :myapp
  # use Ecto.Repo, adapter: Ecto.Adapters.SQLite3, otp_app: :myapp
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
    Repo.__adapter__().storage_down(Repo.config())
    :ok = Repo.__adapter__().storage_up(Repo.config())
    {:ok, _} = Repo.start_link([])
    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true, log_migrations_sql: :info)

    Repo.insert!(%Post{
      title: "Post 1"
    })

    Repo.all(from(p in Post))
    |> dbg()
  end
end

Main.main()
