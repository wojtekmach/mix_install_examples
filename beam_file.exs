Mix.install([:beam_file])

defmodule MyServer do
  use GenServer

  def init(_) do
    {:ok, nil}
  end
end
|> BeamFile.elixir_code!()
|> IO.puts()
