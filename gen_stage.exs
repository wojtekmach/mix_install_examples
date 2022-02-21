Mix.install([
  {:gen_stage, "~> 1.1"}
])

defmodule Producer do
  use GenStage

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [], name: Producer)
  end

  def init(_) do
    {:producer, 0}
  end

  def handle_demand(demand, counter) do
    # If the counter is 3 and we ask for 2 items, we will
    # emit the items 3 and 4, and set the state to 5.
    events = Enum.to_list(counter..counter+demand-1)
    {:noreply, events, counter + demand}
  end
end

defmodule Consumer do
  use GenStage

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [])
  end

  def init(_) do
    {:consumer, :whatever, subscribe_to: [{Producer, min_demand: 0, max_demand: 5}]}
  end

  def handle_events(events, _from, state) do
    # Wait for a second.
    Process.sleep(1_000)

    # Inspect the events.
    IO.inspect(events)

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
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

# Unless running from IEx, sleep indefinitely so stages keep running
unless IEx.started?() do
  Process.sleep(:infinity)
end
