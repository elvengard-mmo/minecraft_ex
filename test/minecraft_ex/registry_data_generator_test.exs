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

    manifest =
      RegistryDataGenerator.build_manifest(
        "26.3",
        777,
        registries
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
             ]
           }

    assert manifest |> RegistryDataGenerator.encode() |> JSON.decode!() == manifest
  end
end
