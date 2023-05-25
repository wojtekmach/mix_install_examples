Mix.install([
  {:glob_ex, "~> 0.1"}
])

defmodule Example do
  import GlobEx.Sigils

  def run do
    GlobEx.ls(~g|e*.exs|) |> dbg()
    GlobEx.match?(~g|*.ex|, "glob_ex.exs") |> dbg()
  end
end

Example.run()
