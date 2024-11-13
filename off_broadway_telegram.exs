Mix.install([
  {:off_broadway_telegram, "~> 1.0"},
  {:req, "~> 0.5.7"}
])

defmodule Poller do
  use Broadway

  def start_link(bot_token) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {OffBroadway.Telegram.Producer,
           [
             client: {OffBroadway.Telegram.ReqClient, [token: bot_token]}
           ]},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 2]
      ]
    )
  end

  @impl Broadway
  def handle_message(
        _processor,
        %Broadway.Message{
          data: update
        } = message,
        _context
      ) do
    update
    |> IO.inspect(label: "UPDATE")
    |> EchoBot.process_message()

    message
  end
end

defmodule EchoBot do
  def secret_bot_token(), do: "your_bot_token"

  def process_message(%{"message" => %{"text" => text, "chat" => %{"id" => chat_id}}})
      when is_binary(text),
      do: send_response(chat_id, text)

  def process_message(%{"message" => %{"chat" => %{"id" => chat_id}}}),
    do: send_response(chat_id, "Huh?")

  def send_response(chat_id, text) do
    Req.post!("https://api.telegram.org/bot{token}/sendMessage",
      json: %{chat_id: chat_id, text: text},
      path_params: [token: secret_bot_token()],
      path_params_style: :curly
    )
  end
end

poller = {Poller, [EchoBot.secret_bot_token()]}
{:ok, _} = Supervisor.start_link([poller], strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
