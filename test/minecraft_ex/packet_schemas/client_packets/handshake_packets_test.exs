defmodule MinecraftEx.Client.HandshakePacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.HandshakePackets

  ## Tests

  test "decodes the 26.2 transfer intent" do
    data = <<0x88, 0x06, 9, "localhost", 25_565::unsigned-16, 3>>
    socket = %Socket{assigns: %{state: :init}}

    packet = HandshakePackets.deserialize(0x00, data, socket)

    assert packet.protocol_version == 776
    assert packet.server_address == "localhost"
    assert packet.server_port == 25_565
    assert packet.intent == :transfer
  end
end
