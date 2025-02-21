Mix.install([
  {:pythonx, "~> 0.3.0"}
])

Pythonx.uv_init("""
[project]
name = "myapp"
version = "0.0.0"
requires-python = "==3.13.*"
""")

defmodule Main do
  import Pythonx, only: :sigils

  def main do
    x = 1

    result =
      ~PY"""
      y = 10
      x + y
      """

    dbg(y)
    dbg(result)
  end
end

Main.main()
