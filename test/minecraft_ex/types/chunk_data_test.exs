defmodule MinecraftEx.Types.ChunkDataTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Types.{ChunkData, ChunkSection, PalettedContainer}

  ## Tests

  test "encodes both 26.2 section counters before the palettes" do
    section = %ChunkSection{
      non_air_blocks: 4_096,
      fluid_count: 0,
      block_states: %PalettedContainer{bits_per_entry: 0, palette: [1], data: []},
      biomes: %PalettedContainer{bits_per_entry: 0, palette: [40], data: []}
    }

    chunk = %ChunkData{
      heightmaps: [],
      sections: [section],
      block_entities: [],
      sky_light_mask: [],
      block_light_mask: [],
      empty_sky_light_mask: [],
      empty_block_light_mask: [],
      sky_light_updates: [],
      block_light_updates: []
    }

    assert ChunkData.encode(chunk) ==
             <<0, 8, 4_096::signed-16, 0::signed-16, 0, 1, 0, 40, 0, 0, 0, 0, 0, 0, 0>>
  end
end
