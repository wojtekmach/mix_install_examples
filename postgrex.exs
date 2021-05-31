Mix.install([
  {:postgrex, "~> 0.15.0"}
])

{:ok, pid} = Postgrex.start_link(database: "")
IO.inspect(Postgrex.query!(pid, "SELECT NOW()", []))
