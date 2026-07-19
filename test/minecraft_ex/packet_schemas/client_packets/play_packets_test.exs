defmodule MinecraftEx.Client.PlayPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.PlayPackets
  alias MinecraftEx.Types.{ChatSession, LastSeenMessagesUpdate}

  ## Tests

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
