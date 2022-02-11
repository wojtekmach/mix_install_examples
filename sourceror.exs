# Example of Code Mod
# changes `|> (fn -> end().()` into `|> then(fn -end)

Mix.install([
  {:sourceror, "~> 0.9"}
])

source = """
foo
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
