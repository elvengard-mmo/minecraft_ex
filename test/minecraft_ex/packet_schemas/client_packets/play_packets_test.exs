defmodule MinecraftEx.Client.PlayPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.PlayPackets
  alias MinecraftEx.Types.ChatSession

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
end
