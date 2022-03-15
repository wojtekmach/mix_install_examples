Mix.install([
  {:fs, "~> 7.0"}
])

defmodule Loop do
  def loop do
    receive do
      event ->
        IO.inspect(event)
        loop()
    end
  end
end

{:ok, _} = :fs.start_link(:fs_watcher, __DIR__)
:fs.subscribe(:fs_watcher)

# touch the file in 100ms so we see the event
Task.async(fn ->
  Process.sleep(100)
  File.touch!(__ENV__.file)
end)
|> Task.await()

Loop.loop()
