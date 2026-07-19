defmodule MinecraftEx.Client.PlayPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.PlayPackets
  alias MinecraftEx.Types.{ChatSession, LastSeenMessagesUpdate}

  ## Tests

  test "decodes the initial play acknowledgements on their 26.2 packet ids" do
    socket = %Socket{assigns: %{state: :play}}

    accept_teleportation = PlayPackets.deserialize(0x00, <<1>>, socket)
    assert accept_teleportation.teleport_id == 1

    chunk_batch_received = PlayPackets.deserialize(0x0B, <<2.5::float-32>>, socket)
    assert chunk_batch_received.desired_chunks_per_tick == 2.5

    keep_alive = PlayPackets.deserialize(0x1C, <<123::signed-64>>, socket)
    assert keep_alive.id == 123

    player_abilities = PlayPackets.deserialize(0x28, <<0x02>>, socket)
    assert player_abilities.flags == 0x02

    player_input = PlayPackets.deserialize(0x2B, <<0x10>>, socket)
    assert player_input.flags == 0x10

    player_loaded = PlayPackets.deserialize(0x2C, <<>>, socket)
    assert player_loaded.__struct__ == MinecraftEx.Client.PlayPackets.PlayerLoaded
  end

  test "decodes the four movement packet shapes" do
    socket = %Socket{assigns: %{state: :play}}

    position =
      PlayPackets.deserialize(
        0x1E,
        <<0.5::float-64, 64.0::float-64, 0.5::float-64, 1>>,
        socket
      )

    assert %{x: 0.5, y: 64.0, z: 0.5, flags: 1} = position

    position_and_rotation =
      PlayPackets.deserialize(
        0x1F,
        <<0.5::float-64, 64.0::float-64, 0.5::float-64, 90.0::float-32, 10.0::float-32, 0>>,
        socket
      )

    assert %{yaw: 90.0, pitch: 10.0, flags: 0} = position_and_rotation

    rotation = PlayPackets.deserialize(0x20, <<45.0::float-32, 5.0::float-32, 0>>, socket)
    assert %{yaw: 45.0, pitch: 5.0, flags: 0} = rotation

    status = PlayPackets.deserialize(0x21, <<3>>, socket)
    assert status.flags == 3
  end

  test "decodes Chat Session Update on its 26.2 packet id" do
    data =
      <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 123::signed-64, 2, 16, 17, 3, 32,
        33, 34>>

    socket = %Socket{assigns: %{state: :play}}
    packet = PlayPackets.deserialize(0x0A, data, socket)

    assert packet.chat_session == %ChatSession{
             session_id: "00010203-0405-0607-0809-0a0b0c0d0e0f",
             expires_at: 123,
             public_key: <<16, 17>>,
             key_signature: <<32, 33, 34>>
           }
  end

  test "decodes Client Tick End on its 26.2 packet id" do
    socket = %Socket{assigns: %{state: :play}}
    packet = PlayPackets.deserialize(0x0D, <<>>, socket)

    assert packet.__struct__ == MinecraftEx.Client.PlayPackets.ClientTickEnd
  end

  test "decodes a signed Chat Message on its 26.2 packet id" do
    signature = :binary.copy(<<0xAB>>, 256)

    data =
      <<2, "hi", 1_800_000_000_123::signed-64, 42::signed-64, 1, signature::binary, 0, 0, 0, 0,
        1>>

    socket = %Socket{assigns: %{state: :play}}
    packet = PlayPackets.deserialize(0x09, data, socket)

    assert packet.message == "hi"
    assert packet.timestamp == 1_800_000_000_123
    assert packet.salt == 42
    assert packet.signature == signature

    assert packet.last_seen_messages == %LastSeenMessagesUpdate{
             offset: 0,
             acknowledged: 0,
             checksum: 1
           }
  end
end
