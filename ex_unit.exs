# Regular use:
# `elixir ex_unit.exs`
#
# Focused use with autostart on file change:
# `find ex_unit.exs | FOCUS=1 entr -c elixir ex_unit.exs`

focus_options = if System.get_env("FOCUS") == "1", do: [exclude: :test, include: :focus], else: []

# Ref: https://hexdocs.pm/ex_unit/ExUnit.html
ExUnit.start([trace: true] |> Keyword.merge(focus_options))

defmodule MyTests do
  use ExUnit.Case, async: true

  test "a failing test" do
    assert 1 == 2
  end

  test "a successful test" do
    assert 1 == 1
  end

  @tag :focus
  test "a focused test" do
    assert "hello" == "world"
  end
end
