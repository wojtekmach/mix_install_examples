Mix.install([:wallaby])

defmodule Main do
  use Wallaby.DSL

  def main do
    {:ok, session} = Wallaby.start_session()

    session
    |> visit("https://elixir-lang.org")
    |> page_title()
    |> IO.inspect()

    Wallaby.end_session(session)
  end
end

Main.main()
