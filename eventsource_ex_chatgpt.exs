# Usage: elixir eventsource_ex_chatgpt.exs openai-api-key "prompt"

Mix.install([
  {:eventsource_ex, "~> 2.0"},
  {:httpoison, "~> 1.5"},
  {:jason, "~> 1.4"}
])

defmodule ChatGPTStreamer do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, request_completion(state[:api_key], state[:messages], state[:parent_pid])}
  end

  def handle_info(
        %EventsourceEx.Message{
          data: "[DONE]",
          event: "message"
        },
        parent_pid
      ) do
    IO.puts("")
    send(parent_pid, :done)
    {:stop, :normal, nil}
  end

  def handle_info(
        %EventsourceEx.Message{
          data: jason_payload,
          event: "message"
        },
        state
      ) do
    jason_payload |> Jason.decode!() |> extract_text() |> IO.write()

    {:noreply, state}
  end

  def extract_text(%{"choices" => choices}) do
    for %{"delta" => delta} <- choices,
        %{"content" => content} <- if(Map.has_key?(delta, "content"), do: [delta], else: []),
        into: "" do
      content
    end
  end

  def extract_text(_) do
    ""
  end

  @chat_completion_url "https://api.openai.com/v1/chat/completions"
  @model "gpt-3.5-turbo"

  defp request_completion(api_key, messages, parent_pid) do
    body = %{
      model: @model,
      messages: messages,
      stream: true
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    options = [method: :post, body: Jason.encode!(body), headers: headers]
    {:ok, _pid} = EventsourceEx.new(@chat_completion_url, options)
    parent_pid
  end
end

Logger.configure(level: :info)

[api_key, prompt] = System.argv()

{:ok, _pid} =
  ChatGPTStreamer.start_link(
    api_key: api_key,
    messages: [%{role: "user", content: prompt}],
    parent_pid: self()
  )

receive do
  :done -> true
end
