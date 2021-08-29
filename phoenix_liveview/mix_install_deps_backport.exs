defmodule InstallFolderTemporaryBackport do
  # temporary backport from code at https://github.com/elixir-lang/elixir/blob/7e4d934d164f8280bbc71759789db92c7260ac07/lib/mix/lib/mix.ex#L575
  def determine_build_folder(deps) do
    build_id = compute_build_id(deps)
    base_folder = Path.join(Mix.Utils.mix_cache(), "installs")
    runtime_version = "elixir-#{System.version()}-erts-#{:erlang.system_info(:version)}"

    base_folder
    |> Path.join(runtime_version)
    |> Path.join(build_id)
  end

  def compute_build_id(deps) do
    deps =
      Enum.map(deps, fn
        dep when is_atom(dep) ->
          {dep, ">= 0.0.0"}

        {app, opts} when is_atom(app) and is_list(opts) ->
          {app, maybe_expand_path_dep(opts)}

        {app, requirement, opts} when is_atom(app) and is_binary(requirement) and is_list(opts) ->
          {app, requirement, maybe_expand_path_dep(opts)}

        other ->
          other
      end)

    deps |> :erlang.term_to_binary() |> :erlang.md5() |> Base.encode16(case: :lower)
  end

  def maybe_expand_path_dep(opts) do
    if Keyword.has_key?(opts, :path) do
      Keyword.update!(opts, :path, &Path.expand/1)
    else
      opts
    end
  end
end
