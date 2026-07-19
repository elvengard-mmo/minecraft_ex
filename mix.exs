defmodule MinecraftEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :minecraft_ex,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh, :inets],
      mod: {MinecraftEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elvengard_ecs, github: "elvengard-mmo/elvengard_ecs"},
      {:elvengard_network, github: "elvengard-mmo/elvengard_network"},
      {:ranch, "~> 2.2"},
      {:simple_enum, "~> 1.0"}
    ]
  end
end
