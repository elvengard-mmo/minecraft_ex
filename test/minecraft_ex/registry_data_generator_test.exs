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

    block_states = %{
      "minecraft:air" => 0,
      "minecraft:grass_block" => 9,
      "minecraft:stone" => 1
    }

    manifest =
      RegistryDataGenerator.build_manifest(
        "26.3",
        777,
        registries,
        tags,
        block_states
      )

    assert manifest == %{
             "minecraft_version" => "26.3",
             "protocol_version" => 777,
             "block_states" => block_states,
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
