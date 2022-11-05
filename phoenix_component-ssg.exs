# :phoenix deps requires (warn) this even if no-use.
Application.put_env(:phoenix, :json_library, Jason)
# Fixtures
layout = "<!DOCTYPE html><html lang='en'><body><%= @inner_content %></body></html>"
about_page = "<.home><:header><._header></._header></:header>about page</.home>"
index_page = "<.home><nav><%= link 'about', to: '/about.html' %></nav></.home>"
shared_header = "Shared header"
File.mkdir_p("templates/layout")
File.mkdir_p("templates/pages")
File.write("templates/layout/main.html.heex", layout)
File.write("templates/pages/index.html.heex", index_page)
File.write("templates/pages/about.html.heex", about_page)
File.write("templates/pages/_header.html.heex", shared_header)
# /Fixtures

Mix.install([
  {:phoenix_live_view, "~> 0.18.3"},
  {:jason, "~> 1.4"}
])

defmodule Page do
  use Phoenix.HTML
  use Phoenix.Component

  embed_templates "templates/layout/*"
  embed_templates "templates/pages/*"

  slot :inner_block, required: true
  slot :header, required: false

  def home(assigns) do
    ~H"""
    <%= render_slot(@header) %>
    <%= render_slot(@inner_block) %>
    """
  end
end

defmodule Main do
  @public_dir "_public"
  @data [
    {"index", %{tags: [:web, :elixir]}},
    {"about", %{}}
  ]

  def run do
    File.mkdir_p(@public_dir)

    for {page, _assigns} <- @data do
      rendered = render(page)
      write_file(page, rendered)
    end
  end

  defp write_file(page, content) do
    case File.write(Path.join(@public_dir, "#{page}.html"), content, [:utf8]) do
      :ok -> IO.inspect("write #{page} successfully")
      {:error, posix} -> throw(%{page: page, reson: posix})
    end
  end

  defp render(page, assigns \\ %{}) do
    assigns = Map.put(assigns, :layout, {Page, Map.get(assigns, :layout, "main")})
    Phoenix.Template.render_to_string(Page, page, "html", assigns)
  end
end

Main.run()
