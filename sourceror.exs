# Example of Code Mod
# Changes
#
#     |> (fn ... end().()
#
# into:
#
#     |> then(fn ... end)

Mix.install([
  {:sourceror, "~> 0.9"}
])

source = """
42
|> (fn i -> i * 2 end).()
"""

IO.puts(["Before: \n", source, "\nAfter: "])

source
|> Sourceror.parse_string!()
|> Sourceror.postwalk(fn
  {:|>, meta, [prev, {{:., _, [{:fn, _, _} | _] = contents}, _, _}]}, state ->
    {{:|>, meta, [prev, {:then, [], contents}]}, state}

  rest, state ->
    {rest, state}
end)
|> Sourceror.to_string()
|> IO.puts()
