defmodule MinecraftEx.Server.PlayPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Server.PlayPackets.Login

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
end
