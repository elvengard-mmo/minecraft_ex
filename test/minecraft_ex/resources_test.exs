defmodule MinecraftEx.ResourcesTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Resources

  ## Tests

  test "loads every synchronized vanilla registry in Mojang order" do
    registries = Resources.vanilla_registries()

    assert length(registries) == 29
    assert Enum.sum(Enum.map(registries, &length(&1.entries))) == 397

    assert hd(registries).registry_id == {"minecraft", "worldgen/biome"}
    assert hd(registries).entries |> hd() == {"minecraft", "badlands"}
    assert hd(registries).entries |> List.last() == {"minecraft", "wooded_badlands"}

    assert Enum.find(registries, &(&1.registry_id == {"minecraft", "dimension_type"})).entries ==
             [
               {"minecraft", "overworld"},
               {"minecraft", "overworld_caves"},
               {"minecraft", "the_end"},
               {"minecraft", "the_nether"}
             ]
  end
end
