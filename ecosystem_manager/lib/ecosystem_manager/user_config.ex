defmodule EcosystemManager.UserConfig do
  @moduledoc """
  User configuration file support for EcosystemManager.

  Loads and manages user-specific configuration from ~/.config/ecosystem-manager/config.exs
  """

  @config_dir "~/.config/ecosystem-manager"
  @config_file "config.exs"

  @doc """
  Load user configuration file if it exists.
  Returns :ok if loaded successfully or if file doesn't exist.
  Returns {:error, reason} if there's a problem loading the file.
  """
  def load do
    config_path = get_config_path()

    if File.exists?(config_path) do
      try do
        # Read the config file using Config.Reader
        config_data = Config.Reader.read!(config_path)

        # Apply the configuration to the application
        if config_data[:ecosystem_manager] do
          Enum.each(config_data[:ecosystem_manager], fn {key, value} ->
            Application.put_env(:ecosystem_manager, key, value)
          end)
        end

        :ok
      rescue
        e in [CompileError, SyntaxError] ->
          {:error, "Invalid configuration file: #{Exception.message(e)}"}
      catch
        :error, reason ->
          {:error, "Failed to load configuration: #{inspect(reason)}"}
      end
    else
      :ok
    end
  end

  @doc """
  Get the full path to the user configuration file.
  """
  def get_config_path do
    Path.join(Path.expand(@config_dir), @config_file)
  end

  @doc """
  Get the user configuration directory path.
  """
  def get_config_dir do
    Path.expand(@config_dir)
  end

  @doc """
  Create example user configuration file.
  """
  def create_example_config do
    config_dir = get_config_dir()
    example_path = Path.join(config_dir, "config.example.exs")

    # Ensure directory exists
    File.mkdir_p!(config_dir)

    example_content = """
    # EcosystemManager User Configuration
    # Copy this file to config.exs and customize as needed

    import Config

    # Set your LaTeX ecosystem workspace path
    # This path will be used as the base directory for all operations
    config :ecosystem_manager,
      workspace_path: "~/SynologyDrive/semi/LaTeX/latex-ecosystem",
      
      # Optional: Override default repository list
      # repositories: [
      #   ".",
      #   "texlive-ja-textlint", 
      #   "latex-environment",
      #   "sotsuron-template",
      #   "my-custom-repo"
      # ]

    # You can override any other settings here
    # config :ecosystem_manager,
    #   default_concurrency: 4,
    #   github_timeout: 30_000,
    #   default_format: :long
    """

    case File.write(example_path, example_content) do
      :ok ->
        {:ok, example_path}

      {:error, reason} ->
        {:error, "Failed to create example config: #{reason}"}
    end
  end

  @doc """
  Create default user configuration file if it doesn't exist.
  """
  def create_default_config(workspace_path \\ nil) do
    config_path = get_config_path()

    if File.exists?(config_path) do
      {:error, "Configuration file already exists: #{config_path}"}
    else
      config_dir = get_config_dir()
      File.mkdir_p!(config_dir)

      default_content = """
      # EcosystemManager User Configuration
      # Generated on #{DateTime.utc_now() |> DateTime.to_string()}

      import Config

      # Set your LaTeX ecosystem workspace path
      config :ecosystem_manager,
        workspace_path: #{inspect(workspace_path || "~/path/to/latex-ecosystem")},
        
        # Optional: Custom repository list
        # repositories: [
        #   ".",
        #   "texlive-ja-textlint",
        #   "latex-environment",
        #   "sotsuron-template"
        # ]
      """

      case File.write(config_path, default_content) do
        :ok ->
          {:ok, config_path}

        {:error, reason} ->
          {:error, "Failed to create config: #{reason}"}
      end
    end
  end
end
