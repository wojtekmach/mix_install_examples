Mix.install([
  {:explorer, "~> 0.1.0"}
])

alias Explorer.DataFrame
alias Explorer.Series

Explorer.Datasets.iris()
|> DataFrame.select(["sepal_length", "sepal_width", "species"])
|> DataFrame.filter(fn df -> Series.less(df["sepal_length"], 5.0) end)
|> DataFrame.group_by(["species"])
|> DataFrame.summarise(sepal_width: [:max], sepal_length: [:mean])
|> IO.inspect()
