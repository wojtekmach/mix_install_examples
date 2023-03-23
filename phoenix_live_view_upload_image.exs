# Based on https://hexdocs.pm/phoenix_live_view/0.18.18/uploads.html

Application.put_env(:sample, Example.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64),
  pubsub_server: Example.PubSub
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "~> 1.7.2"},
  {:phoenix_live_view, "~> 0.18.18"}
])

defmodule Example.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Example.HomeLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_urls, [])
     |> allow_upload(
       :image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    tmp_dir = Path.join(System.tmp_dir!(), "phoenix_live_view_upload_example")
    File.mkdir_p!(tmp_dir)

    uploaded_urls =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        dest = Path.join(tmp_dir, entry.client_name)
        File.cp!(path, dest)
        {:ok, "/uploads/#{entry.client_name}"}
      end)

    {:noreply, update(socket, :uploaded_urls, &(&1 ++ uploaded_urls))}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def render("live.html", assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.2/priv/static/phoenix.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.18/priv/static/phoenix_live_view.min.js"></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <%= @inner_content %>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Phoenix LiveView Upload Image Example</h1>
    <div phx-drop-target={@uploads.image.ref}>
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.image} />
        <button type="submit">Upload</button>
      </form>

      <%= for entry <- @uploads.image.entries do %>
        <article class="upload-entry">
          <h2>Preview</h2>

          <figure>
            <.live_img_preview entry={entry} width="400" />
            <figcaption><%= entry.client_name %></figcaption>
          </figure>

          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

          <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} aria-label="cancel">&times;</button>

          <%= for err <- upload_errors(@uploads.image, entry) do %>
            <p class="alert alert-danger">1: <%= err %></p>
          <% end %>

        </article>
      <% end %>

      <%= for err <- upload_errors(@uploads.image) do %>
        <p class="alert alert-danger">2: <%= err %></p>
      <% end %>
    </div>

    <h2>Uploaded Files</h2>

    <p :if={@uploaded_urls == []}>No files yet.</p>
    <div :for={url <- @uploaded_urls}>
      <img src={url} style="max-width: 400px">
    </div>
    """
  end
end

defmodule Example.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", Example do
    pipe_through(:browser)

    live("/", HomeLive, :index)
  end
end

defmodule Example.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Static,
    at: "/uploads",
    from: Path.join(System.tmp_dir!(), "phoenix_live_view_upload_example")
  )

  plug(Example.Router)
end

children = [
  {Phoenix.PubSub, name: Example.PubSub},
  Example.Endpoint
]

{:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
