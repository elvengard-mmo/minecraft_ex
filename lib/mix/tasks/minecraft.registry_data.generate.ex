defmodule Mix.Tasks.Minecraft.RegistryData.Generate do
  use Mix.Task

  alias MinecraftEx.RegistryDataGenerator

  @shortdoc "Generates synchronized registry data and tags from an official Minecraft version"

  @moduledoc """
  Generates the Minecraft version manifest, synchronized vanilla registries, and network tags.

      mix minecraft.registry_data.generate VERSION

      mix minecraft.registry_data.generate VERSION --check

  The task uses a matching local Minecraft installation when available and downloads
  missing official artifacts into the Mix build cache. The `--check` option verifies
  that the committed manifest is reproducible without rewriting it.
  """

  ## Mix.Task callbacks

  @impl Mix.Task
  def run(args) do
    {opts, positional} =
      OptionParser.parse!(args,
        strict: [
          cache_path: :string,
          check: :boolean,
          minecraft_path: :string,
          output_path: :string
        ]
      )

    minecraft_version = parse_version!(positional)
    project_path = Mix.Project.project_file() |> Path.dirname() |> Path.expand()

    cache_path =
      Keyword.get(
        opts,
        :cache_path,
        Path.join(Mix.Project.build_path(), "minecraft_registry_data")
      )

    output_path =
      Keyword.get(opts, :output_path, Path.join(project_path, "priv/minecraft_data.json"))

    generator_opts = [
      cache_path: cache_path,
      check: Keyword.get(opts, :check, false),
      output_path: output_path,
      probe_path: Path.join(project_path, "scripts/MinecraftRegistryDataProbe.java")
    ]

    generator_opts =
      case Keyword.fetch(opts, :minecraft_path) do
        {:ok, minecraft_path} -> Keyword.put(generator_opts, :minecraft_path, minecraft_path)
        :error -> generator_opts
      end

    Mix.shell().info("Generating registry data for Minecraft #{minecraft_version}...")
    manifest = RegistryDataGenerator.generate(minecraft_version, generator_opts)

    registry_count = manifest |> Map.fetch!("registries") |> length()
    registry_tags = Map.fetch!(manifest, "tags")
    tag_count = Enum.sum(Enum.map(registry_tags, &length(&1["tags"])))

    Mix.shell().info(
      "Generated #{registry_count} synchronized registries and " <>
        "#{tag_count} tags across #{length(registry_tags)} registries"
    )
  end

  ## Private functions

  defp parse_version!([minecraft_version]), do: minecraft_version

  defp parse_version!(_args) do
    Mix.raise("Usage: mix minecraft.registry_data.generate VERSION")
  end
end
