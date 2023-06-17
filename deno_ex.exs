Mix.install([:deno_ex])

ExUnit.start()

defmodule DenoExTest do
  use ExUnit.Case, async: true

  test "deno_ex" do
    assert {:ok, "Hello, world.\n"} == DenoEx.run({:stdin, "console.log(\"Hello, world.\")"})
  end
end
