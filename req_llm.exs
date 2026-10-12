# Usage: ANTHROPIC_API_KEY=... elixir req_llm.exs
#
# A tour of ReqLLM (https://github.com/agentjido/req_llm), a unified API for LLM
# providers built on Req and Finch. Swap the model string, e.g.
# "openai:gpt-5" or "google:gemini-2.5-flash", to run against another provider.
Mix.install([
  {:req_llm, "~> 1.28"}
])

defmodule Demo do
  @model "anthropic:claude-sonnet-5-5"

  def run do
    section("1. Text generation with a system prompt", &text/0)
    section("2. Structured output (validated against a schema)", &structured_output/0)
    section("3. Streaming with usage and cost", &streaming/0)
    section("4. Tool calling", &tool_calling/0)
    section("5. Multi-turn conversation", &conversation/0)
  end

  # 1. ReqLLM.Context holds messages; it is provider-agnostic.
  defp text do
    context =
      ReqLLM.Context.new([
        ReqLLM.Context.system("You are a terse Elixir expert. Answer in one sentence."),
        ReqLLM.Context.user("Why is pattern matching useful?")
      ])

    {:ok, response} = ReqLLM.generate_text(@model, context, temperature: 0.2, max_tokens: 200)

    IO.puts(ReqLLM.Response.text(response))
  end

  # 2. Pass a NimbleOptions-style schema and get back a validated map.
  defp structured_output do
    schema = [
      name: [type: :string, required: true, doc: "Library name"],
      purpose: [type: :string, required: true, doc: "What it does, in a few words"],
      stars_out_of_ten: [type: :pos_integer, required: true]
    ]

    object =
      ReqLLM.generate_object!(
        @model,
        "Describe the Elixir library Phoenix",
        schema,
        max_tokens: 300
      )

    IO.inspect(object)
  end

  # 3. stream_text/3 returns immediately: tokens are a lazy stream, while
  #    usage/cost metadata is collected in the background and available at the end.
  defp streaming do
    {:ok, stream} =
      ReqLLM.stream_text(@model, "Write a haiku about the BEAM virtual machine.", max_tokens: 200)

    stream
    |> ReqLLM.StreamResponse.tokens()
    |> Stream.each(&IO.write/1)
    |> Stream.run()

    IO.puts("")

    usage = ReqLLM.StreamResponse.usage(stream)
    IO.puts("tokens: #{usage.input_tokens} in / #{usage.output_tokens} out")

    case usage do
      %{total_cost: cost} -> IO.puts("cost:   $#{cost}")
      _ -> IO.puts("cost:   unavailable (#{inspect(usage.pricing.status)})")
    end
  end

  # 4. Tools are plain Elixir functions with a typed parameter schema. ReqLLM
  #    validates arguments, but *you* own the loop: call the model, run the
  #    requested tools, append the results, and repeat until there are no more calls.
  defp tool_calling do
    tools = [
      ReqLLM.tool(
        name: "get_weather",
        description: "Get the current weather for a city",
        parameter_schema: [
          city: [type: :string, required: true, doc: "City name"],
          unit: [type: {:in, ["celsius", "fahrenheit"]}, default: "celsius"]
        ],
        callback: fn %{city: city, unit: unit} ->
          {:ok, "It is 21 degrees #{unit}, sunny, in #{city}."}
        end
      ),
      ReqLLM.tool(
        name: "get_time",
        description: "Get the current UTC time",
        parameter_schema: [],
        callback: fn _args -> {:ok, DateTime.utc_now() |> DateTime.to_iso8601()} end
      )
    ]

    context =
      ReqLLM.Context.new([
        ReqLLM.Context.user("What's the weather in Lisbon, and what time is it in UTC?")
      ])

    tool_loop(context, tools)
  end

  defp tool_loop(context, tools, round \\ 1) when round <= 5 do
    {:ok, response} = ReqLLM.generate_text(@model, context, tools: tools, max_tokens: 500)

    case ReqLLM.Response.tool_calls(response) do
      [] ->
        IO.puts("\nFinal answer: #{ReqLLM.Response.text(response)}")

      tool_calls ->
        results =
          for call <- tool_calls do
            name = ReqLLM.ToolCall.name(call)
            args = ReqLLM.ToolCall.args_map(call)
            tool = Enum.find(tools, &(&1.name == name))
            {:ok, output} = ReqLLM.Tool.execute(tool, args)

            IO.puts("[round #{round}] #{name}(#{inspect(args)}) -> #{output}")
            ReqLLM.Context.tool_result(call.id, name, output)
          end

        {:ok, context} = ReqLLM.Context.append_tool_exchange(context, response, results)
        tool_loop(context, tools, round + 1)
    end
  end

  # 5. response.context is the full history including the assistant reply,
  #    so continuing a conversation is just appending the next user message.
  defp conversation do
    {:ok, first} =
      ReqLLM.generate_text(@model, "My name is Ada. Reply with just 'Noted.'", max_tokens: 50)

    context = ReqLLM.Context.append(first.context, ReqLLM.Context.user("What is my name?"))
    {:ok, second} = ReqLLM.generate_text(@model, context, max_tokens: 50)

    IO.puts(ReqLLM.Response.text(second))
  end

  defp section(title, fun) do
    IO.puts("\n\e[1m== #{title} ==\e[0m")
    fun.()
  end
end

Demo.run()
