defmodule EcosystemManager.Application do
  @moduledoc """
  Application module for EcosystemManager.

  Loads user configuration on startup.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Load user configuration
    case EcosystemManager.UserConfig.load() do
      :ok ->
        :ok

      {:error, reason} ->
        IO.puts("Warning: Failed to load user configuration: #{reason}")
    end

    # No supervision tree needed for a CLI tool
    opts = [strategy: :one_for_one, name: EcosystemManager.Supervisor]
    Supervisor.start_link([], opts)
  end
end
