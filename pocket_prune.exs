Mix.install([
  {:finch, "~> 0.8.0"},
  {:jason, "~> 1.0"},
  {:plug_cowboy, "~> 1.0"},
  {:plug, "~> 1.12"}
])

consumer_key = System.fetch_env!("CONSUMER_KEY")
post_count = System.fetch_env!("BATCH_SIZE")
token_file = System.get_env("TOKEN_FILE", ".pocket_access_token")
auth_url = "https://getpocket.com/v3/oauth/request"
authorize_url = "https://getpocket.com/v3/oauth/authorize"
get_url = "https://getpocket.com/v3/get"
modify_url = "https://getpocket.com/v3/send"
redirect_uri = "http://lvh.me:8080/callback"

{:ok, _} = Finch.start_link(name: MyFinch)

make_request = fn method, url, headers, body, retry ->
  body = if is_map(body), do: Jason.encode!(body), else: body

  headers =
    [{"Content-Type", "application/json; charset=UTF-8"}, {"X-Accept", "application/json"}] ++
      headers

  case method |> Finch.build(url, headers, body) |> Finch.request(MyFinch) do
    {:ok, %{body: body, status: 200}} ->
      body =
        case Jason.decode(body) do
          {:ok, decoded} -> decoded
          _ -> body
        end

      {200, body}

    {:ok, %{body: body, status: 429}} ->
      retry.(method, url, headers, body, retry)

    resp ->
      raise inspect(resp)
  end
end

sleepy = fn method, url, headers, body, retry ->
  IO.puts("Got 429 - Sleeping for 30 seconds")
  Process.sleep(:timer.seconds(30))
  make_request.(method, url, headers, body, retry)
end

authorize = fn ->
  defmodule OAuthCallbackListener do
    use Plug.Router

    plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
    plug(:match)
    plug(:dispatch)

    get "/callback" do
      send(GlobalParent, :callback)

      conn
      |> resp(200, "Auth complete - you can close this tab now!")
      |> send_resp()
    end

    match _ do
      send_resp(conn, 404, "Not Found")
    end

    def start() do
      opts = [
        port: 8080,
        protocol_options: [
          max_header_name_length: 500,
          max_header_value_length: 20_000,
          max_headers: 100,
          max_request_line_length: 20_000
        ]
      ]

      {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [], opts)
    end

    def stop() do
      Plug.Adapters.Cowboy.shutdown(__MODULE__.HTTP)
    end
  end

  Process.register(self(), GlobalParent)
  OAuthCallbackListener.start()

  {200, %{"code" => request_token}} =
    make_request.(
      :post,
      auth_url,
      [],
      %{
        consumer_key: consumer_key,
        redirect_uri: redirect_uri
      },
      sleepy
    )

  url = "https://getpocket.com/auth/authorize?request_token=#{request_token}&redirect_uri=#{URI.encode(redirect_uri)}"

  start_browser_command =
    case :os.type do
      {:win32, _} ->
        "start"
      {:unix, :darwin} ->
        "open"
      {:unix, _} ->
        "xdg-open"
    end

  if System.find_executable(start_browser_command) do
    System.cmd(start_browser_command, [url])
  else
    Mix.raise "Command not found: #{start_browser_command}"
  end

  receive do
    :callback -> :ok
  end

  {200, %{"access_token" => access_token}} =
    make_request.(
      :post,
      authorize_url,
      [],
      %{
        consumer_key: consumer_key,
        code: request_token
      },
      sleepy
    )

  access_token
end

delete_posts = fn access_token, callback ->
  get_body = %{
    consumer_key: consumer_key,
    access_token: access_token,
    count: post_count,
    sort: "oldest",
    detailType: "simple",
    state: "archive"
  }

  {200, %{"list" => posts}} = make_request.(:post, get_url, [], get_body, sleepy)

  if posts == [] do
    :ok
  else
    actions =
      posts
      |> Map.keys()
      |> Enum.map(&%{action: "delete", item_id: to_string(&1)})

    query =
      URI.encode_query(%{
        actions: Jason.encode!(actions),
        access_token: access_token,
        consumer_key: consumer_key
      })

    url =
      modify_url
      |> URI.parse()
      |> Map.put(:query, query)
      |> URI.to_string()

    case make_request.(:get, url, [], nil, sleepy) do
      {200, _} -> IO.puts("Successfully deleted #{post_count} archived items")
      resp -> raise inspect(resp)
    end

    callback.(access_token, callback)
  end
end

access_token =
  if File.exists?(token_file) do
    File.read!(token_file)
  else
    token = authorize.()
    File.write!(token_file, token)
    token
  end

delete_posts.(access_token, delete_posts)
