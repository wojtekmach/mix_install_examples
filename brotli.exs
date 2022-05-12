Mix.install([
  {:brotli, "~> 0.3.0"}
])

{:ok, encoded} = :brotli.encode(["foo", ["bar"]])
{:ok, decoded} = :brotli.decode(encoded)
"foobar" = decoded

IO.inspect(encoded: encoded, decoded: decoded)
