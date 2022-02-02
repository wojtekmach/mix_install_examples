Mix.install([
  {:decompilerl, github: "aerosol/decompilerl"}
])

defmodule Foo do
  def foo(opts) do
    with {:ok, width} <- Map.fetch(opts, :width),
         {:ok, height} <- Map.fetch(opts, :height) do
      {:ok, width * height}
    end
  end
end
|> Decompilerl.decompile(skip_info: true)
