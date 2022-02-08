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

tmp_dir = Path.join(System.tmp_dir!(), "mix_install_ex_doc")
beam_path = "#{tmp_dir}/_build/dev/lib/example/ebin/#{module}.beam"
File.mkdir_p!(Path.dirname(beam_path))
File.write!(beam_path, beam)

Hex.start()

defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "1.0.0",
      build_path: "#{unquote(tmp_dir)}/_build",
      lockfile: "#{unquote(tmp_dir)}/mix.lock",
      deps_path: "#{unquote(tmp_dir)}/deps"
    ]
  end
end

Mix.Task.run("docs", ~w(--formatter html --main Foo --output #{tmp_dir}/doc --open))
