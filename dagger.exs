Mix.install([:dagger])

# It's requires to have `docker` on the local machine first.
Dagger.with_connection(
  fn dag ->
    source =
      dag
      |> Dagger.Client.git("https://github.com/elixir-lang/elixir")
      |> Dagger.GitRepository.branch("main")
      |> Dagger.GitRef.tree()

    {:ok, version} = dag
    |> Dagger.Client.container()
    |> Dagger.Container.from("hexpm/erlang:27.0.1-alpine-3.20.2")
    |> Dagger.Container.with_exec(~w"apk add make")
    |> Dagger.Container.with_workdir("/elixir")
    |> Dagger.Container.with_mounted_directory("/elixir", source)
    |> Dagger.Container.with_exec(~w"make")
    |> Dagger.Container.with_exec(~w"./bin/elixir --version")
    |> Dagger.Container.stdout()

    IO.puts(version)
  end,
  connect_timeout: :timer.minutes(1)
)
