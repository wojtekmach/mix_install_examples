Mix.install([
  {:localize, "~> 0.1.0"}
])

Application.put_env(:localize, :allow_runtime_locale_download, true)

dbg(Localize.Date.to_string(~D[2025-03-22], format: :long, locale: :pl))
