defmodule MinecraftEx.RegistryDataGeneratorTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.RegistryDataGenerator

  ## Tests

  test "builds a deterministic manifest from the ordered probe output" do
    registries = [
      %{
        "registry_id" => "minecraft:worldgen/biome",
        "entries" => ["minecraft:alpha", "example:nested/alpha", "minecraft:zebra"]
      },
      %{
        "registry_id" => "minecraft:damage_type",
        "entries" => ["minecraft:generic"]
      }
    ]

    tags = [
      %{
        "registry_id" => "minecraft:block",
        "tags" => [
          %{"tag_id" => "minecraft:logs", "entries" => [4, 7, 9]}
        ]
      }
    ]

    manifest =
      RegistryDataGenerator.build_manifest(
        "26.3",
        777,
        registries,
        tags
      )

    assert manifest == %{
             "minecraft_version" => "26.3",
             "protocol_version" => 777,
             "registries" => [
               %{
                 "registry_id" => "minecraft:worldgen/biome",
                 "entries" => [
                   "minecraft:alpha",
                   "example:nested/alpha",
                   "minecraft:zebra"
                 ]
               },
               %{
                 "registry_id" => "minecraft:damage_type",
                 "entries" => ["minecraft:generic"]
               }
             ],
             "tags" => tags
           }

    assert manifest |> RegistryDataGenerator.encode() |> JSON.decode!() == manifest
  end
end
