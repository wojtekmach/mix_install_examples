path = Path.join(System.tmp_dir(), "foo")
System.put_env("MIX_INSTALL_DIR", path)

Mix.install([
  {:decompilerl, github: "aerosol/decompilerl"}
])

{:module, _, beam, _} =
  defmodule Foo do
    def foo(opts) do
      with {:ok, width} <- Map.fetch(opts, :width),
           {:ok, height} <- Map.fetch(opts, :height) do
        {:ok, width * height}
      end
    end
  end

ebin_path = Path.join(path, "ebin")
File.mkdir_p!(ebin_path)
File.write!("Elixir.Foo.beam", beam)

Decompilerl.decompile(Foo, skip_info: true)
