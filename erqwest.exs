Mix.install(
  [:erqwest],
  elixir: "~> 1.13-dev"
)

:ok = :erqwest.start_client(:default)

:erqwest.get(:default, "https://hex.pm/api/packages/erqwest", %{
  headers: [{"user-agent", "erqwest"}]
})
|> IO.inspect()
