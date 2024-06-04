Mix.install([
  :postgrex,
  :jason,
  {:ex_audit, "~> 0.10.0"}
])

Application.put_env(:myapp, MyApp.Repo, database: "mix_install_examples")

Application.put_env(:ex_audit, :repos, [MyApp.Repo])
Application.put_env(:ex_audit, :version_schema, MyApp.Version)
Application.put_env(:ex_audit, :tracked_schemas, [MyApp.Post])
Application.put_env(:ex_audit, :primitive_structs, [Date, DateTime, NaiveDateTime, Time])

defmodule MyApp.Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :myapp

  use ExAudit.Repo
end

defmodule Migration do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add(:patch, :binary)
      add(:entity_id, :integer)
      add(:entity_schema, :string)
      add(:action, :string)
      add(:recorded_at, :utc_datetime)
      add(:rollback, :boolean, default: false)
    end

    create(index(:versions, [:entity_schema, :entity_id]))

    create table("posts") do
      add(:title, :string)
      add(:content, :string)
      timestamps(type: :utc_datetime)
    end
  end
end

defmodule MyApp.Version do
  use Ecto.Schema

  schema "versions" do
    field(:patch, ExAudit.Type.Patch)
    field(:entity_id, :integer)
    field(:entity_schema, ExAudit.Type.Schema)
    field(:action, ExAudit.Type.Action)
    field(:recorded_at, :utc_datetime)
    field(:rollback, :boolean, default: false)
  end

  def changeset(struct, params \\ %{}) do
    Ecto.Changeset.cast(struct, params, [
      :patch,
      :entity_id,
      :entity_schema,
      :action,
      :recorded_at,
      :rollback
    ])
  end
end

defmodule MyApp.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:content, :string)

    timestamps(type: :utc_datetime)
  end
end

defmodule Main do
  import Ecto.Query, warn: false
  alias MyApp.Repo

  def main do
    _ = Repo.__adapter__().storage_down(Repo.config())
    :ok = Repo.__adapter__().storage_up(Repo.config())
    children = [Repo]
    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    Ecto.Migrator.run(Repo, [{0, Migration}], :up, all: true, log_migrations_sql: :debug)

    post = Repo.insert!(%MyApp.Post{title: "Post 1", content: "Content 1"})
    post |> Ecto.Changeset.change(content: "Content 1 (updated)") |> Repo.update!()
    Repo.insert!(%MyApp.Post{title: "Post 2", content: "Content 2"})

    dbg(Repo.all(MyApp.Version))
  end
end

Main.main()
