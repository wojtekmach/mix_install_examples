Mix.install([
  {:gen_stage, "~> 1.1"}
])

defmodule Producer do
  use GenStage

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [], name: Producer)
  end

  def init(initial_state) do
    {:producer, initial_state}
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end
end

defmodule Consumer do
  use GenStage

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(initial_state) do
    {:consumer, initial_state, subscribe_to: [Producer]}
  end
end

defmodule Main do
  def main do
    children = [
      Producer,
      Consumer
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end

Main.main()
Process.sleep(:infinity)
