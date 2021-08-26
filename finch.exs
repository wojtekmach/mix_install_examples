Mix.install([
  {:finch, "~> 0.8.0"}
])

{:ok, _} = Finch.start_link(name: MyFinch)

Finch.build(:get, "https://hex.pm/api/packages/finch")
|> Finch.request(MyFinch)
|> IO.inspect()
