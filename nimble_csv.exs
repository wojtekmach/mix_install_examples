Mix.install([
  {:nimble_csv, "~> 1.0"}
])

alias NimbleCSV.RFC4180, as: CSV

"foo,bar\r\nbaz,qux\r\n"
|> IO.inspect(label: :input)
|> CSV.parse_string(skip_headers: false)
|> IO.inspect(label: :parsed)
|> CSV.dump_to_iodata()
|> IO.inspect(label: :dumped)
