Mix.install([
  {:rustler_precompiled, "~> 0.1.0"}
])

File.write!("checksum-Elixir.RustlerPrecompilationExample.Native.exs", """
%{
  "libexample-v0.2.0-nif-2.16-x86_64-apple-darwin.so.tar.gz" => "sha256:75acb8daa6bfc7af51ec60dd660e1bdcf544e154f412cfe681c95e4966132df4",
}
""")

defmodule RustlerPrecompilationExample.Native do
  version = "0.2.0"

  use RustlerPrecompiled,
    otp_app: :elixir,
    crate: "example",
    base_url:
      "https://github.com/philss/rustler_precompilation_example/releases/download/v#{version}",
    version: version

  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end

IO.inspect(RustlerPrecompilationExample.Native.add(1, 2))
