defmodule MinecraftEx.PacketHandlers.PlayTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.PlayPackets.ChatSessionUpdate
  alias MinecraftEx.PacketHandlers.Play
  alias MinecraftEx.Types.ChatSession

  ## Tests

  test "stores the client chat session" do
    chat_session = %ChatSession{
      session_id: "00010203-0405-0607-0809-0a0b0c0d0e0f",
      expires_at: 123,
      public_key: <<16, 17>>,
      key_signature: <<32, 33, 34>>
    }

    packet = %ChatSessionUpdate{chat_session: chat_session}
    socket = %Socket{assigns: %{state: :play}}

    assert {:cont, new_socket} = Play.handle_packet(packet, socket)
    assert new_socket.assigns.chat_session == chat_session
  end
end
