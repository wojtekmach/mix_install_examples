# $ brew install libevent

Mix.install([
  {:katipo, "~> 1.0"}
])

{:ok, _} = :katipo_pool.start(MyKatipo, 2)

:katipo.get(MyKatipo, "https://api.github.com/repos/puzza007/katipo", %{
  headers: [{"User-Agent", "katipo"}]
})
|> IO.inspect()
