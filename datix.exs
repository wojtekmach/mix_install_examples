Mix.install([
  {:datix, "~> 0.1.0"}
])

Datix.Time.parse!("09:10:20", "%H:%M:%S")
|> IO.inspect()

Datix.Date.parse!("2022-08-02", "%Y-%m-%d")
|> IO.inspect()

Datix.NaiveDateTime.parse!("2022-08-02 09:10:20", "%Y-%m-%d %H:%M:%S")
|> IO.inspect()
