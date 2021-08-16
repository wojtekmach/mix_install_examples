Mix.install([
  :req
])

Req.get!("https://api.github.com/repos/elixir-lang/elixir").body["description"]
|> IO.inspect()
