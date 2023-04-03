Mix.install([
  {:nimble_publisher, "~> 1.0"},
  {:makeup_elixir, ">= 0.0.0"},
  {:bandit, ">= 0.0.0"}
])

defmodule Example.Post do
  @enforce_keys [:id, :title, :body, :date]
  defstruct [:id, :title, :body, :date]

  def build(filename, attrs, body) do
    [year, month, day, id] =
      filename |> Path.rootname() |> Path.split() |> List.last() |> String.split("-", parts: 4)

    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end
end

defmodule Example.Blog do
  dir = Path.join(System.tmp_dir!(), "mix_install_examples_nimble_publisher")
  File.rm_rf!(dir)
  File.mkdir_p!(dir)

  File.write!(Path.join(dir, "2023-04-03-hello-world.md"), ~S"""
  %{
    title: "Hello world"
  }
  ---
  Body of the "Hello world" article.

  This is a *markdown* document with support for code highlighters:

  ```elixir
  IO.puts "hello world"
  ```
  """)

  use NimblePublisher,
    build: Example.Post,
    from: "#{dir}/*.md",
    as: :posts,
    highlighters: [:makeup_elixir]

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  def list_posts do
    @posts
  end
end

defmodule Example.Plug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _) do
    html = ~S"""
    <style>
    <%= Makeup.stylesheet(:tango_style, "makeup") %>
    </style>

    <h1>NimblePublisher example</h1>

    <%= for post <- posts do %>
      <h2><%= post.title %> (<%= post.date %>)</h2>
      <%= post.body %>
    <% end %>
    """

    posts = Example.Blog.list_posts()
    html = EEx.eval_string(html, posts: posts)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
end

bandit = {Bandit, plug: Example.Plug, scheme: :http, options: [port: 4000]}
{:ok, _} = Supervisor.start_link([bandit], strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
