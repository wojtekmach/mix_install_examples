Mix.install([:ratatouille])

# Selector
#
# Basic option chooser using Elixir and Ratatouille
# 
# Usage:
# 
# $ echo "Option 1\nOption 2\nOption 3" | elixir ratatouille.exs 

defmodule RatatouilleSelector do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  @up [key(:ctrl_p), key(:arrow_up)]
  @down [key(:ctrl_n), key(:arrow_down)]
  @enter key(:enter)

  def init(%{window: %{height: height}}) do
    lines =
      IO.read(:eof)
      |> String.trim()
      |> String.split("\n")

    %{
      lines: lines,
      selected_row: 0,
      height: height - 1
    }
  end

  def update(%{lines: lines} = model, msg) do
    model
    |> then(&on_arrow_pressed(msg, lines, &1))
    |> then(&on_enter_pressed(msg, &1))
  end

  def render(%{lines: lines, selected_row: selected_row}) do
    view do
      viewport do
        for {line, idx} <- Enum.with_index(lines) do
          row do
            column size: 12 do
              label do
                arrow(idx == selected_row)
                gutter(idx == selected_row)

                line(line, %{selected?: idx == selected_row})
              end
            end
          end
        end
      end
    end
  end

  defp line(l, %{selected?: true}) do
    text(content: l, color: :black, background: :white)
  end

  defp line(l, %{selected?: false}) do
    text(content: l, color: :default, background: :default)
  end

  defp gutter(true) do
    text(content: " ", background: :white)
  end

  defp gutter(false) do
    text(content: " ", background: :default)
  end

  defp arrow(true) do
    text(content: ">", color: :red, background: :white)
  end

  defp arrow(false) do
    text(content: " ", background: :white)
  end

  def on_arrow_pressed(msg, lines, model) do
    case msg do
      {:event, %{key: key}} when key in @up ->
        %{model | selected_row: max(model.selected_row - 1, 0)}

      {:event, %{key: key}} when key in @down ->
        %{model | selected_row: min(model.selected_row + 1, length(lines) - 1)}

      _ ->
        model
    end
  end

  def on_enter_pressed(msg, model) do
    case msg do
      {:event, %{key: @enter}} ->
        word =
          model.lines
          |> Enum.with_index(fn f, i -> {i, f} end)
          |> then(&Map.new(&1)[model.selected_row])

        Agent.update(:capture_proc, fn _ -> word end)

        quit()

        model

      _ ->
        model
    end
  end

  defp quit() do
    # we fake a keystroke to quit the tui
    send(self(), {:event, %{key: key(:esc)}})
  end
end

# there isn't a way to return output from the tui, so we use some global state 😜
Agent.start_link(fn -> nil end, name: :capture_proc)

Ratatouille.run(RatatouilleSelector,
  quit_events: [
    {:key, Ratatouille.Constants.key(:ctrl_c)},
    {:key, Ratatouille.Constants.key(:esc)}
  ]
)

selection = Agent.get(:capture_proc, & &1)

IO.puts(selection)
