Mix.install([:httpoison])

HTTPoison.get!("https://hex.pm/api/packages/httpoison")
|> IO.inspect()
