Mix.install([:mint, :castore])

defmodule Main do
  def main do
    {:ok, conn} = Mint.HTTP.connect(:https, "httpbin.org", 443)
    {:ok, conn, ref} = Mint.HTTP.request(conn, "GET", "/anything", [], nil)
    {:ok, _conn, response} = receive_response(conn, ref, 5000)
    IO.inspect(response)
  end

  defp receive_response(conn, ref, timeout) do
    receive_response([], %{status: nil, headers: [], body: ""}, conn, ref, timeout)
  end

  defp receive_response([{:status, ref, status} | rest], acc, conn, ref, timeout) do
    receive_response(rest, %{acc | status: status}, conn, ref, timeout)
  end

  defp receive_response([{:headers, ref, headers} | rest], acc, conn, ref, timeout) do
    receive_response(rest, update_in(acc.headers, &(&1 ++ headers)), conn, ref, timeout)
  end

  defp receive_response([{:data, ref, data} | rest], acc, conn, ref, timeout) do
    receive_response(rest, update_in(acc.body, &(&1 <> data)), conn, ref, timeout)
  end

  defp receive_response([{:done, ref} | _], acc, conn, ref, _timeout) do
    {:ok, conn, acc}
  end

  defp receive_response([], acc, conn, ref, timeout) do
    start_time = System.monotonic_time(:millisecond)

    receive do
      message ->
        timeout =
          if timeout == :infinity do
            timeout
          else
            elapsed = System.monotonic_time(:millisecond) - start_time
            timeout - elapsed
          end

        with {:ok, conn, responses} <- Mint.HTTP.stream(conn, message) do
          receive_response(responses, acc, conn, ref, timeout)
        end
    after
      timeout ->
        {:error, conn, :timeout}
    end
  end
end

Main.main()
