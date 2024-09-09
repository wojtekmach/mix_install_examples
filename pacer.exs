Mix.install([
  {:pacer, "~> 0.1"},
  {:req, "~> 0.5"}
])

defmodule HexPackagesWorkflow do
  use Pacer.Workflow

  @base_url "https://hex.pm/api/packages"
  @default_download_data %{"all" => 0, "recent" => 0, "day" => 0, "week" => 0}

  defmodule PackageDownloads do
    def req(%{base_url: base_url}), do: Req.get!("#{base_url}/req").body["downloads"]
    def phoenix(%{base_url: base_url}), do: Req.get!("#{base_url}/phoenix").body["downloads"]
    def pacer(%{base_url: base_url}), do: Req.get!("#{base_url}/pacer").body["downloads"]
  end

  defmodule DownloadDataAggregator do
    @base %{"all" => 0, "recent" => 0, "day" => 0, "week" => 0}

    def calculate(%{req: req, phoenix: phoenix, pacer: pacer}) do
      Enum.reduce([req, phoenix, pacer], @base, fn package_downloads, all_downloads ->
        all_downloads
        |> Map.update!("all", &(&1 + package_downloads["all"]))
        |> Map.update!("recent", &(&1 + package_downloads["recent"]))
        |> Map.update!("day", &(&1 + package_downloads["day"]))
        |> Map.update!("week", &(&1 + package_downloads["week"]))
      end)
    end
  end

  defmodule DownloadsTable do
    @column_length 12
    def build(%{req: req, phoenix: phoenix, pacer: pacer, aggregate_downloads: totals}) do
      line_builder = fn package ->
        Enum.reduce(~w(all recent week day), "", fn key, line ->
          line_open = "\s#{package[key]}"

          "#{line}#{String.pad_trailing(line_open, @column_length)}|"
        end)
      end

      """
              | All        | Recent     | Week       | Day        |
      -------------------------------------------------------------
      Req     |#{line_builder.(req)}
      Phoenix |#{line_builder.(phoenix)}
      Pacer   |#{line_builder.(pacer)}
      --------------------------------------------------------------
      Totals  |#{line_builder.(totals)}
      """
    end
  end

  graph do
    field(:base_url, default: @base_url)

    batch :fetch_package_data do
      field(:req,
        dependencies: [:base_url],
        resolver: &PackageDownloads.req/1,
        default: @default_download_data
      )

      field(:phoenix,
        dependencies: [:base_url],
        resolver: &PackageDownloads.phoenix/1,
        default: @default_download_data
      )

      field(:pacer,
        dependencies: [:base_url],
        resolver: &PackageDownloads.pacer/1,
        default: @default_download_data
      )
    end

    field(:aggregate_downloads,
      dependencies: [:req, :phoenix, :pacer],
      resolver: &DownloadDataAggregator.calculate/1
    )

    field(:downloads_table,
      dependencies: [:aggregate_downloads, :req, :phoenix, :pacer],
      resolver: &DownloadsTable.build/1
    )
  end
end

HexPackagesWorkflow
|> Pacer.Workflow.execute()
|> then(&IO.puts(&1.downloads_table))
