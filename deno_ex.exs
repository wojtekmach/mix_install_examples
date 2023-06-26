Mix.install([:deno_ex])

DenoEx.run({:stdin, ~s|console.log("Hello, world.")|})
|> IO.inspect()
