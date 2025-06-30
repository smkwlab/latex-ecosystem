defmodule EcosystemManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecosystem_manager,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: EcosystemManager.CLI, name: "ecosystem-manager"],
      test_coverage: [
        threshold: 90,
        # UserConfig is excluded due to high environmental dependencies
        # (filesystem, HOME variable, permissions) which make reliable
        # testing complex without significant infrastructure
        ignore_modules: [
          EcosystemManager.UserConfig
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix],
        flags: [:error_handling, :underspecs, :unmatched_returns],
        ignore_warnings: "dialyzer.ignore-warnings"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EcosystemManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.4"},
      # Development and testing tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
