defmodule MinecraftEx.World.FlatTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.MinecraftData
  alias MinecraftEx.World.Flat

  ## Tests

  test "builds the confirmed initial spawn" do
    assert Flat.spawn_position() == %{
             x: 0.5,
             y: 64.0,
             z: 0.5,
             delta_x: 0.0,
             delta_y: 0.0,
             delta_z: 0.0,
             yaw: 0.0,
             pitch: 0.0
           }

    assert Flat.spawn_chunk_position() == {0, 0}
    assert Flat.teleport_id() == 1
  end

  test "builds a 24-section Overworld chunk with grass at Y 63" do
    chunk = Flat.chunks_around_spawn(0) |> hd()
    stone_id = MinecraftData.block_state_id!("minecraft:stone")
    grass_id = MinecraftData.block_state_id!("minecraft:grass_block")
    air_id = MinecraftData.block_state_id!("minecraft:air")
    plains_id = MinecraftData.registry_entry_id!("minecraft:worldgen/biome", "minecraft:plains")

    assert %{x: 0, z: 0, data: %{sections: sections}} = chunk
    assert length(sections) == 24

    assert Enum.all?(Enum.take(sections, 7), fn section ->
             section.non_air_blocks == 4_096 and section.fluid_count == 0 and
               section.block_states.palette == [stone_id]
           end)

    surface = Enum.at(sections, 7)
    assert surface.non_air_blocks == 4_096
    assert surface.fluid_count == 0
    assert surface.block_states.palette == [stone_id, grass_id]

    assert Enum.all?(Enum.drop(sections, 8), fn section ->
             section.non_air_blocks == 0 and section.fluid_count == 0 and
               section.block_states.palette == [air_id]
           end)

    assert Enum.all?(sections, &(&1.biomes.palette == [plains_id]))
  end

  test "builds the complete chunk square around spawn, nearest first" do
    chunks = Flat.chunks_around_spawn(1)

    assert length(chunks) == 9
    assert %{x: 0, z: 0} = hd(chunks)

    assert MapSet.new(Enum.map(chunks, &{&1.x, &1.z})) ==
             MapSet.new(for(x <- -1..1, z <- -1..1, do: {x, z}))
  end
end
