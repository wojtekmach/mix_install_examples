Mix.install(
  [
    {:ash, "~> 3.0.0-rc"}
  ],
  consolidate_protocols: false
)

defmodule Accounts.Profile do
  use Ash.Resource,
    domain: Accounts,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults [:read, :destroy, create: [:name], update: [:name]]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end
end

defmodule Accounts do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Accounts.Profile do
      define :all_profiles, action: :read
      define :create_profile, args: [:name], action: :create
      define :update_profile, args: [:name], action: :update
      define :delete_profile, action: :destroy
    end
  end
end

IO.puts("#{IO.ANSI.yellow()}\nAsh: With the code interface we defined on the Accounts domain (preferred)")

Accounts.create_profile!("Joe Armstrong")
[profile] = Accounts.all_profiles!() |> IO.inspect()
Accounts.update_profile!(profile, "José Valim")
Accounts.all_profiles!() |> IO.inspect()
Accounts.destroy!(profile)
Accounts.all_profiles!() |> IO.inspect()

IO.puts("#{IO.ANSI.yellow()}\nAsh: Interacting with resource actions directly (equivalent to the above)")

Accounts.Profile
|> Ash.Changeset.for_create(:create, %{name: "Joe Armstrong"})
|> Ash.create!()

[profile] =
  Accounts.Profile
  |> Ash.read!()
  |> IO.inspect()

profile
|> Ash.Changeset.for_update(:update, %{name: "José Valim"})
|> Ash.update!()

Accounts.Profile
|> Ash.read!()
|> IO.inspect()

Ash.destroy!(profile)

Accounts.Profile
|> Ash.read!()
|> IO.inspect()
