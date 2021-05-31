Mix.install([
  {:req, github: "wojtekmach/req", branch: "main"}
])

IO.inspect(Req.get!("https://api.github.com/repos/elixir-lang/elixir").body["description"])
