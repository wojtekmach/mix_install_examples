Mix.install([
  {:mneme, ">= 0.0.0"}
])

ExUnit.start(seed: 0)
Mneme.start()

defmodule Parser do
  def parse_ints(string) when is_binary(string) do
    string
    |> String.split(",")
    |> Stream.map(&String.trim/1)
    |> Stream.map(&Integer.parse/1)
    |> Enum.flat_map(fn
      {num, ""} -> [num]
      _ -> []
    end)
  end

  def parse_ints(other) do
    raise ArgumentError, "expected a string, got #{inspect(other)}"
  end
end

defmodule ExampleTest do
  use ExUnit.Case
  use Mneme

  import Parser

  test "parse_ints/1 (new assertions)" do
    auto_assert(parse_ints("1, 2, 3"))

    auto_assert(parse_ints("1,2,3"))

    auto_assert(parse_ints("1, foo, 3"))

    auto_assert(parse_ints(""))
  end

  test "parse_ints/1 (updating assertions)" do
    auto_assert([1, 2, 3] <- parse_ints("1, 2foo, 3, 4"))
  end

  @mneme default_pattern: :last
  test "parse_ints/1 (raising assertions)" do
    auto_assert_raise(fn -> parse_ints(~c"1, 2, 3") end)
  end
end

ExUnit.run()
