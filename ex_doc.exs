Mix.install(
  [
    {:ex_doc, "~> 0.28.0"}
  ],
  elixir: "~> 1.13"
)

{:module, module, beam, _} =
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

tmp_dir = Path.join(System.tmp_dir!(), "ex_doc")
beam_path = "#{tmp_dir}/_build/shared/lib/example/ebin/#{module}.beam"
File.mkdir_p!(Path.dirname(beam_path))
File.write!(beam_path, beam)

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
  build_path: "#{tmp_dir}/_build",
  lockfile: "#{tmp_dir}/mix.lock",
  deps_path: "#{tmp_dir}/deps",
  erlc_paths: [],
  elixirc_paths: [],
  consolidate_protocols: false
]

Mix.ProjectStack.push(Example.MixProject, config, __ENV__.file)

# end private APIs!

Mix.Task.run("docs", ~w(--formatter html --main Foo --output #{tmp_dir}/doc --open))
