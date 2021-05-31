Mix.install([
  {:myxql, "~> 0.5.0"}
])

{:ok, pid} = MyXQL.start_link(username: "root")
IO.inspect(MyXQL.query!(pid, "SELECT NOW()"))
