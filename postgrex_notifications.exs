Mix.install([
  {:postgrex, "~> 0.18"}
])

{:ok, _} =
  Supervisor.start_link(
    [
      {Postgrex, name: :pg, database: ""},
      {Postgrex.Notifications, name: :pg_notify, database: ""}
    ],
    strategy: :one_for_one
  )

{:ok, listen_ref} = Postgrex.Notifications.listen(:pg_notify, "channel")

Task.start_link(fn ->
  Postgrex.query!(:pg, ~s|NOTIFY channel, 'Hello, World!'|, [])
end)

receive do
  {:notification, _pid, ^listen_ref, channel, payload} ->
    IO.inspect(channel: channel, payload: payload)
end
