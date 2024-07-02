# https://hex.pm/packages/nanoid
# https://github.com/ai/nanoid
# https://zelark.github.io/nano-id-cc/

Mix.install([
  {:nanoid, "~> 2.1"}
])

IO.inspect(Nanoid.generate(12, "0123456789abcdefghijklmnopqrstuvwxyz"))
