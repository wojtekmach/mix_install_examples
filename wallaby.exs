Mix.install([:wallaby])

Application.ensure_all_started(:wallaby)

defmodule Scraper do
  use Wallaby.DSL

  def run do
    {:ok, session} = Wallaby.start_session()

    session
    |> visit("https://elixir-lang.org")
    |> page_title()
    |> IO.inspect()

    Wallaby.end_session(session)
  end
end

Scraper.run()
