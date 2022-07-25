# Based on scenic_new
# See: https://github.com/boydm/scenic_new#install-prerequisites

Mix.install([
  {:scenic, "~> 0.10"},
  {:scenic_driver_glfw, "~> 0.10", targets: :host}
])

defmodule Main do
  def main do
    main_viewport_config = %{
      name: :main_viewport,
      size: {700, 600},
      default_scene: {Example.Scene.Home, nil},
      drivers: [
        %{
          module: Scenic.Driver.Glfw,
          name: :glfw,
          opts: [resizeable: false, title: "example"]
        }
      ]
    }

    children = [
      {Scenic, viewports: [main_viewport_config]}
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule Example.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives

  @note """
  This is a very simple starter application.
  """

  @text_size 24

  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    glfw_ver = Application.spec(:scenic_driver_glfw, :vsn) |> to_string()

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        text_spec("scenic: v" <> scenic_ver, translate: {20, 40}),
        text_spec("glfw: v" <> glfw_ver, translate: {20, 40 + @text_size}),
        text_spec(@note, translate: {20, 120}),
        rect_spec({width, height})
      ])

    {:ok, graph, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end

Main.main()
System.no_halt(true)
