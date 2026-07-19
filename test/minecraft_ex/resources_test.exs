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

  test "loads resolved vanilla network tags with numeric protocol ids" do
    registry_tags = Resources.vanilla_tags()

    assert length(registry_tags) == 15
    assert Enum.sum(Enum.map(registry_tags, &length(&1.tags))) == 697

    block_tags = Enum.find(registry_tags, &(&1.registry_id == {"minecraft", "block"}))
    logs = Enum.find(block_tags.tags, &(&1.tag_id == {"minecraft", "logs"}))

    assert length(logs.entries) == 44
    assert Enum.take(logs.entries, 4) == [55, 77, 66, 85]

    dialog_tags = Enum.find(registry_tags, &(&1.registry_id == {"minecraft", "dialog"}))
    assert Enum.all?(dialog_tags.tags, &(&1.entries == []))
  end
end
