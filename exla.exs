Mix.install([
  {:nx, "~> 0.1.0", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"}
])

defmodule Foo do
  import Nx.Defn

  @defn_compiler EXLA
  defn softmax(tensor) do
    Nx.exp(tensor) / Nx.sum(Nx.exp(tensor))
  end
end

IO.inspect(Foo.softmax(Nx.tensor([[1, 2], [3, 4]])))
