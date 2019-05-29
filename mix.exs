defmodule Bolt.Ecto.MixProject do
  use Mix.Project

  def project do
    [
      app: :bolt_ecto,
      version: "0.1.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Ecto 3.x adapter for Neo4J.",
      name: "Bolt.Ecto",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Giang Nguyen"],
      links: %{"Github" => "https://github.com/bluecloudy/bolt_ecto"}
    }
  end

  defp elixirc_paths(:test),
    do: [
      "lib",
      "test/support"
    ]

  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0.6"},
      {:bolt_sips, "~> 1.0.0-rc2"},
      {:poison, "~> 2.2 or ~> 3.0", optional: true},
      # Dev dependencies
      {:ecto_sql, "~> 3.0.4"},
      {:mix_test_watch, "~> 0.9", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
