defmodule MinecraftEx.Server.PlayPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Server.PlayPackets.{
    ChunkBatchFinished,
    ChunkBatchStart,
    GameEvent,
    LevelChunkWithLight,
    Login,
    PlayerPosition,
    SetChunkCacheCenter,
    SetChunkCacheRadius,
    SetSimulationDistance
  }

  alias MinecraftEx.Types.ChunkData

  ## Tests

  test "serializes Login with the 26.2 packet id and fields" do
    packet =
      struct!(Login, %{
        entity_id: 1,
        is_hardcore: false,
        dimensions: [{"minecraft", "overworld"}],
        max_players: 20,
        view_distance: 10,
        simulation_distance: 10,
        reduced_debug_info: false,
        enable_respawn_screen: true,
        limited_crafting: false,
        dimension_type: 0,
        dimension_name: {"minecraft", "overworld"},
        hashed_seed: 0,
        game_mode: :survival,
        previous_game_mode: :undefined,
        is_debug: false,
        is_flat: false,
        has_death_location: false,
        death_dimension_name: nil,
        death_location: nil,
        portal_cooldown: 0,
        sea_level: 63,
        online_mode: true,
        enforces_secure_chat: false
      })

    assert {0x31, encoded} = Login.serialize(packet, %Socket{})

    assert IO.iodata_to_binary(encoded) ==
             <<1::32, 0, 1, 19, "minecraft:overworld", 20, 10, 10, 0, 1, 0, 0, 19,
               "minecraft:overworld", 0::64, 0, 255, 0, 0, 0, 0, 63, 1, 0>>
  end

  test "serializes the 26.2 initial position and chunk control packets" do
    position = %PlayerPosition{
      teleport_id: 1,
      x: 0.5,
      y: 64.0,
      z: 0.5,
      delta_x: 0.0,
      delta_y: 0.0,
      delta_z: 0.0,
      yaw: 0.0,
      pitch: 0.0,
      relative_flags: 0
    }

    assert {0x48, encoded_position} = PlayerPosition.serialize(position, %Socket{})

    assert IO.iodata_to_binary(encoded_position) ==
             <<1, 0.5::float-64, 64.0::float-64, 0.5::float-64, 0.0::float-64, 0.0::float-64,
               0.0::float-64, 0.0::float-32, 0.0::float-32, 0::signed-32>>

    assert {0x26, encoded_event} =
             GameEvent.serialize(%GameEvent{event: 13, value: 0.0}, %Socket{})

    assert IO.iodata_to_binary(encoded_event) == <<13, 0.0::float-32>>

    assert {0x5E, [<<0>>, <<0>>]} =
             SetChunkCacheCenter.serialize(%SetChunkCacheCenter{x: 0, z: 0}, %Socket{})

    assert {0x5F, [<<10>>]} =
             SetChunkCacheRadius.serialize(%SetChunkCacheRadius{radius: 10}, %Socket{})

    assert {0x6F, [<<10>>]} =
             SetSimulationDistance.serialize(%SetSimulationDistance{distance: 10}, %Socket{})

    assert {0x0C, []} = ChunkBatchStart.serialize(%ChunkBatchStart{}, %Socket{})

    assert {0x0B, [<<1>>]} =
             ChunkBatchFinished.serialize(%ChunkBatchFinished{batch_size: 1}, %Socket{})
  end

  test "serializes Level Chunk With Light with its 26.2 framing" do
    chunk = %LevelChunkWithLight{
      x: 0,
      z: 0,
      data: %ChunkData{
        heightmaps: [],
        sections: [],
        block_entities: [],
        sky_light_mask: [],
        block_light_mask: [],
        empty_sky_light_mask: [],
        empty_block_light_mask: [],
        sky_light_updates: [],
        block_light_updates: []
      }
    }

    assert {0x2D, encoded} = LevelChunkWithLight.serialize(chunk, %Socket{})

    assert IO.iodata_to_binary(encoded) ==
             <<0::signed-32, 0::signed-32, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  end
end
