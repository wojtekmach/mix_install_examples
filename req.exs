Mix.install([
  :req
])

Req.get!("https://hex.pm/api/packages/req").body["meta"]["description"]
|> IO.inspect()
