Mix.install([
  {:brotli, "~> 0.3.0"}
])

{:ok, encoded} = :brotli.encode(["foo", ["bar", ["baz", "qux"]]])
{:ok, decoded} = :brotli.decode(encoded)
"foobarbazqux" = decoded

IO.inspect(encoded: encoded, decoded: decoded)
