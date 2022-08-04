Mix.install([:brod])

:ok = :brod.start_client([{"localhost", 9092}], :default)

:brod.start_producer(:default, "default", [])

:brod.produce_sync_offset(:default, "default", 0, :undefined, "{\"name\": \"elixir\"}")
|> IO.inspect(label: "producing")

:brod.fetch(:default, "default", 0, 0)
|> IO.inspect(label: "consuming")
