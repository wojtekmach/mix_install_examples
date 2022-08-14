try do
  # fake an existing config file (to keep things in a single file here),
  # which would otherwise exist somewhere outside of git
  File.write!("config.exs", """
  import Config
  config :my_app, :my_config_key, "some-secret-value"
  """)

  config = Config.Reader.read!("config.exs")

  value = "some-secret-value" = config[:my_app][:my_config_key]
  IO.puts("Yay, secret config is #{value |> inspect}")
after
  File.rm!("config.exs")
end
