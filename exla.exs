Mix.install([
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:exla_precompiled, "~> 0.1.0-dev", github: "jonatanklosko/exla_precompiled"}
])

defmodule Foo do
  import Nx.Defn

  @defn_compiler EXLA
  defn softmax(tensor) do
    Nx.exp(tensor) / Nx.sum(Nx.exp(tensor))
  end
end

IO.inspect(Foo.softmax(Nx.tensor([[1, 2], [3, 4]])))
