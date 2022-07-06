defmodule Dice.MixProject do
  use Mix.Project

  def project do
    [
      app: :dice,
      name: "Dice",
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dice.Application, []}
    ]
  end

  # TODO: remove ex_ncurses
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
      # {:handi_utils, path: "../handi_utils"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "deps.compile", "format", "compile"],
      dialyzer: ["compile", "dialyzer"],
      test: ["format", "compile", "test"]
    ]
  end

  defp preferred_cli_env() do
    [
      dialyzer: :dev,
      format: :dev,
      test: :test,
      docs: :dev
    ]
  end
end
