Mix.install([
  {:gun, "1.3.3"}
])

{:ok, conn_pid} = :gun.open(~c"httpbin.org", 443)
{:ok, :http2} = :gun.await_up(conn_pid)
stream_ref = :gun.post(conn_pid, "/anything", [{"user-agent", "gun/1.3.3"}], "hi")
{:response, :nofin, status, headers} = :gun.await(conn_pid, stream_ref)
{:ok, body} = :gun.await_body(conn_pid, stream_ref)
IO.inspect(status: status, headers: headers, body: body)
