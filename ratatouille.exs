Mix.install([:ratatouille])

# fxf
#
# Basic implemention of fzf using Elixir and Ratatouille
# 
# Usage:
# 
# $ elixir ratatouille.exs # recursively lists all files in the current directory
#
# $ git ls-files | elixir ratatouille.exs -- # lists whatever is piped into stdin (note the arg '--')

defmodule Fxf.State do
  alias Ratatouille.Runtime.Command
  import Ratatouille.Constants

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  @up [
    key(:ctrl_p),
    key(:arrow_up)
  ]

  @down [
    key(:ctrl_n),
    key(:arrow_down)
  ]

  @spacebar key(:space)

  @enter key(:enter)

  def on_query_change(msg, %{query: query} = model) do
    case msg do
      {:event, %{key: key}} when key in @delete_keys ->
        new_q = String.slice(query, 0..-2)
        new_model = %{model | query: new_q}

        {:halt, {new_model, Command.new(fn -> filter_lines(new_model) end, :filtered)}}

      {:event, %{key: @spacebar}} ->
        new_model = %{model | query: query <> " "}

        {:halt, {new_model, Command.new(fn -> filter_lines(new_model) end, :filtered)}}

      {:event, %{ch: ch}} when ch > 0 ->
        new_model = %{model | query: query <> <<ch::utf8>>}

        {:halt, {new_model, Command.new(fn -> filter_lines(new_model) end, :filtered)}}

      _ ->
        model
    end
  end

  def on_filter_results(msg, model) do
    case msg do
      {:filtered, filtered_model} ->
        %{model | filtered_lines: filtered_model.filtered_lines}

      _ ->
        model
    end
  end

  def on_arrow_pressed(msg, old_filtered_lines, model) do
    case msg do
      {:event, %{key: key}} when key in @up ->
        %{model | selected_row: max(model.selected_row - 1, 0)}

      {:event, %{key: key}} when key in @down ->
        %{model | selected_row: min(model.selected_row + 1, length(old_filtered_lines) - 1)}

      _ ->
        model
    end
  end

  def on_enter_pressed(msg, model) do
    case msg do
      {:event, %{key: @enter}} ->
        word =
          model.filtered_lines
          |> Enum.with_index(fn f, i -> {i, f} end)
          |> then(&Map.new(&1)[model.selected_row])
          |> Enum.map_join(fn {g, _, _} -> g end)

        Agent.update(:capture_proc, fn _ -> word end)

        quit()

        model

      _ ->
        model
    end
  end

  def calculate_y_offset(
        old_filtered_lines,
        %{height: height, selected_row: selected_row, y_offset: y_offset} = model
      ) do
    height = height - 2

    # re-calculate the selected row if the results have changed
    %{selected_row: selected_row} =
      model =
      if length(old_filtered_lines) != length(model.filtered_lines) do
        %{
          model
          | selected_row: min(selected_row, min(height, max(length(model.filtered_lines) - 1, 0)))
        }
      else
        model
      end

    # recalculate the scroll position of the window based on which row is selected
    cond do
      selected_row in y_offset..(height + y_offset) ->
        model

      selected_row < height ->
        %{model | y_offset: 0}

      y_offset > selected_row ->
        %{model | y_offset: selected_row}

      selected_row > height + y_offset ->
        %{model | y_offset: selected_row - height}

      true ->
        model
    end
  end

  def calculate_view_window(%{filtered_lines: lines, y_offset: y_offset, height: height} = model) do
    %{
      model
      | viewable_rows: lines |> Enum.with_index() |> Enum.slice(y_offset..(y_offset + height - 2))
    }
  end

  def handle({:halt, model}, _), do: {:halt, model}
  def handle(model, handler), do: handler.(model)

  def finish({:halt, model}), do: model
  def finish(model), do: model

  defp quit() do
    # we fake a keystroke to quit the tui
    send(self(), {:event, %{key: key(:esc)}})
  end

  def filter_lines(%{query: ""} = model) do
    %{
      model
      | filtered_lines:
          Enum.map(model.lines, fn word ->
            word
            |> break_down_word()
            |> Enum.map(fn {g, idx} -> {g, idx, false} end)
          end)
    }
  end

  def filter_lines(model) do
    filtered_lines =
      model.lines
      |> Enum.map(&scan_word(&1, model.query))
      |> Enum.filter(fn {_, _, length} -> length == String.length(model.query) end)
      |> Enum.sort_by(fn {_, score, length} -> {length, -score} end, &>/2)
      |> Enum.map(fn {scanned, _, _} -> scanned end)

    %{model | filtered_lines: filtered_lines}
  end

  # incomplete implementation of the V1 fzf algorithm
  defp scan_word(word, query) do
    scanned_word =
      word
      |> break_down_word()
      |> Enum.reduce({[], String.graphemes(query)}, fn {char, idx}, {acc, query} ->
        {query_fragment, rest} =
          case query do
            [] ->
              {"", []}

            [query_fragment | rest] ->
              {query_fragment, rest}
          end

        if String.downcase(char) == String.downcase(query_fragment) do
          {[{char, idx, true} | acc], rest}
        else
          {[{char, idx, false} | acc], [query_fragment | rest]}
        end
      end)
      |> then(fn {scanned_word, _} -> scanned_word end)
      |> Enum.reverse()

    found =
      scanned_word
      |> Enum.filter(fn {_, _, found?} -> found? end)

    score =
      found
      |> Enum.min_max_by(fn {_, idx, _} -> idx end, fn -> {{nil, 0, nil}, {nil, 0, nil}} end)
      |> then(fn {{_, min, _}, {_, max, _}} -> max - min end)

    {scanned_word, score, Enum.count(found)}
  end

  defp break_down_word(word) do
    word
    |> String.graphemes()
    |> Enum.with_index()
  end
end

defmodule Fxf do
  @behaviour Ratatouille.App

  import Ratatouille.View

  def init(%{window: %{height: height}}) do
    lines =
      case System.argv() do
        ["--"] ->
          IO.read(:eof)
          |> String.trim()
          |> String.split("\n")

        _ ->
          Path.wildcard("./**/*")
      end

    %{
      query: "",
      lines: lines,
      filtered_lines: [],
      selected_row: 0,
      height: height - 1,
      y_offset: 0,
      viewable_rows: []
    }
    |> Fxf.State.filter_lines()
    |> Fxf.State.calculate_view_window()
  end

  def update(%{filtered_lines: old_filtered_lines} = model, msg) do
    model
    |> Fxf.State.handle(&Fxf.State.on_query_change(msg, &1))
    |> Fxf.State.handle(&Fxf.State.on_filter_results(msg, &1))
    |> Fxf.State.handle(&Fxf.State.on_arrow_pressed(msg, old_filtered_lines, &1))
    |> Fxf.State.handle(&Fxf.State.on_enter_pressed(msg, &1))
    |> Fxf.State.handle(&Fxf.State.calculate_y_offset(old_filtered_lines, &1))
    |> Fxf.State.handle(&Fxf.State.calculate_view_window(&1))
    |> Fxf.State.finish()
  end

  def render(model) do
    %{
      query: query,
      filtered_lines: lines,
      lines: total_lines,
      selected_row: selected_row,
      viewable_rows: viewable_rows
    } = model

    view do
      label do
        text(content: ">", color: :blue)
        text(content: " #{query}")
      end

      label do
        text(content: "#{length(lines)}/#{length(total_lines)}", color: :yellow)
      end

      viewport do
        for {line, idx} <- viewable_rows do
          row do
            column size: 12 do
              label do
                arrow(idx == selected_row)
                gutter(idx == selected_row)

                for {g, _, found?} <- line do
                  letter(g, %{found?: found?, selected?: idx == selected_row})
                end
              end
            end
          end
        end
      end
    end
  end

  defp letter(g, %{found?: true, selected?: true}) do
    text(content: g, color: :green, background: :white)
  end

  defp letter(g, %{found?: true, selected?: false}) do
    text(content: g, color: :green, background: :default)
  end

  defp letter(g, %{found?: false, selected?: true}) do
    text(content: g, color: :black, background: :white)
  end

  defp letter(g, %{found?: false, selected?: false}) do
    text(content: g, color: :default, background: :default)
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
end

# there isn't a way to return output from the tui, so we use some global state 😜
Agent.start_link(fn -> nil end, name: :capture_proc)

Ratatouille.run(Fxf,
  quit_events: [
    {:key, Ratatouille.Constants.key(:ctrl_c)},
    {:key, Ratatouille.Constants.key(:esc)}
  ]
)

word = Agent.get(:capture_proc, & &1)

IO.puts(word)
