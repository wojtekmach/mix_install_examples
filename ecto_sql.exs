Mix.install([
  {:ecto_sql, "~> 3.7.0"},
  {:postgrex, "~> 0.15.0"}
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
  def main do
    children = [
      Repo
    ]

    _ = Repo.__adapter__().storage_down(Repo.config())
    :ok = Repo.__adapter__().storage_up(Repo.config())

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Ecto.Migrator.run(Repo, [{0, Migration0}], :up, all: true, log_sql: :debug)
    Repo.insert!(%Post{title: "Hello, World!"})

    IO.inspect(Repo.all(Post))
  end
end

Main.main()
