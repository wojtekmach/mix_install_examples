Mix.install([
  {:ezstd, "~> 1.0"}
])

encoded = :ezstd.compress("hello world")
decoded = :ezstd.decompress(encoded)
"hello world" = decoded
IO.inspect(encoded: encoded, decoded: decoded)
