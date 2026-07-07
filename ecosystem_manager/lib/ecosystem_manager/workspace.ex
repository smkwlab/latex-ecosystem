defmodule EcosystemManager.Workspace do
  @moduledoc """
  Multi-workspace support.

  Resolves which ecosystem workspace a command operates on, from the configured
  list of workspaces and the current working directory.
  """

  alias EcosystemManager.Config

  defstruct [:name, :path]

  @type t :: %__MODULE__{name: String.t(), path: String.t()}

  @doc """
  Return the configured workspaces as a list of `%Workspace{}` with `~`
  expanded to absolute paths.

  Uses `:workspaces` (a `[name: path]` keyword list) when configured; otherwise
  falls back to the legacy single `:workspace_path` as one workspace named
  after its directory. Returns `[]` when neither is configured.
  """
  def list do
    case Config.workspaces() do
      nil -> legacy_list()
      [] -> legacy_list()
      workspaces -> Enum.map(workspaces, &normalize/1)
    end
  end

  @doc "Names of the configured workspaces."
  def names, do: Enum.map(list(), & &1.name)

  @doc """
  Resolve which workspace a command operates on.

    * an explicit `name` (from `--workspace`) selects that workspace by name
    * otherwise the workspace containing `cwd` (deepest match) is used
    * otherwise, when exactly one workspace is configured, that one is used
    * otherwise `:none` (the caller falls back to the current directory)

  Returns `{:ok, %Workspace{}}`, `{:error, message}` (unknown name) or `:none`.
  """
  def resolve(name, cwd) do
    workspaces = list()

    if is_binary(name) and name != "" do
      find_by_name(workspaces, name)
    else
      resolve_by_cwd(workspaces, cwd)
    end
  end

  defp legacy_list do
    case Config.workspace_path() do
      nil ->
        []

      "" ->
        []

      path ->
        expanded = Path.expand(path)
        [%__MODULE__{name: Path.basename(expanded), path: expanded}]
    end
  end

  defp normalize({name, path}) do
    %__MODULE__{name: to_string(name), path: Path.expand(path)}
  end

  defp find_by_name(workspaces, name) do
    case Enum.find(workspaces, &(&1.name == name)) do
      nil -> {:error, unknown_message(workspaces, name)}
      ws -> {:ok, ws}
    end
  end

  @doc """
  Return the configured workspace that contains `cwd` (deepest match), or nil.

  Unlike `resolve/2`, this applies no single-workspace fallback: it is used by
  `repos --sync` to register the workspace for the current directory.
  """
  def containing(cwd), do: deepest_containing(list(), cwd)

  defp resolve_by_cwd(workspaces, cwd) do
    case deepest_containing(workspaces, cwd) do
      nil ->
        case workspaces do
          [single] -> {:ok, single}
          _ -> :none
        end

      ws ->
        {:ok, ws}
    end
  end

  # Workspace whose path equals cwd or is an ancestor of cwd; deepest wins.
  defp deepest_containing(workspaces, cwd) do
    case Enum.filter(workspaces, &contains?(&1.path, cwd)) do
      [] -> nil
      matches -> Enum.max_by(matches, &String.length(&1.path))
    end
  end

  defp contains?(path, cwd) do
    cwd == path or String.starts_with?(cwd, path <> "/")
  end

  defp unknown_message([], name) do
    "Unknown workspace: #{name}. No workspaces are configured."
  end

  defp unknown_message(workspaces, name) do
    registered = Enum.map_join(workspaces, ", ", & &1.name)
    "Unknown workspace: #{name}. Registered: #{registered}"
  end
end
