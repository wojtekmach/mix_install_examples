Mix.install(
  [
    {:ex_doc, "~> 0.28.0"}
  ],
  elixir: "~> 1.13"
)

{:module, _, foo, _} =
  defmodule Foo do
    @moduledoc """
    A module.
    """

    @doc """
    A function.
    """
    def foo do
    end
  end

# begin private APIs!

File.write!("tmp/ex_doc/_build/shared/lib/example/ebin/Elixir.Foo.beam", foo)

Hex.start()

defmodule Example.MixProject do
  def project do
    []
  end
end

config = [
  app: :example,
  version: "1.0.0",
  build_embedded: false,
  build_per_environment: false,
  build_path: "tmp/ex_doc/_build",
  lockfile: "tmp/ex_doc/mix.lock",
  deps_path: "tmp/ex_doc/deps",
  erlc_paths: [],
  elixirc_paths: [],
  consolidate_protocols: false
]

Mix.ProjectStack.push(Example.MixProject, config, __ENV__.file)

# end private APIs!

Mix.Task.run("docs", ~w(--formatter html --main Foo --output tmp/ex_doc/doc --open))
