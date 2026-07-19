defmodule MinecraftEx.PacketHandlers.HandshakeTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.HandshakePackets.{Handshake, StatusRequest}
  alias MinecraftEx.Endpoint.NetworkCodec
  alias MinecraftEx.PacketHandlers.Handshake, as: HandshakeHandler
  alias MinecraftEx.Types.{MCString, VarInt}

  ## Test adapter

  defmodule Adapter do
    def send(test_process, data) do
      Kernel.send(test_process, {:sent, IO.iodata_to_binary(data)})
      :ok
    end
  end

  ## Tests

  test "enters login state while preserving the transfer intent" do
    packet =
      struct!(Handshake, %{
        protocol_version: 776,
        server_address: "localhost",
        server_port: 25_565,
        intent: :transfer
      })

    socket = %Socket{assigns: %{state: :init}}

    assert {:cont, new_socket} = HandshakeHandler.handle_packet(packet, socket)
    assert new_socket.assigns.state == :login
    assert new_socket.assigns.intent == :transfer
  end

  test "advertises Minecraft 26.2 protocol 776 in Status Response" do
    socket = %Socket{
      adapter: Adapter,
      adapter_state: self(),
      encoder: NetworkCodec,
      assigns: %{state: :status, enc_key: nil}
    }

    assert {:cont, ^socket} = HandshakeHandler.handle_packet(%StatusRequest{}, socket)
    assert_receive {:sent, encoded}

    {packet_length, packet} = VarInt.decode(encoded)
    assert byte_size(packet) == packet_length

    {0x00, body} = VarInt.decode(packet)
    {json, <<>>} = MCString.decode(body)
    status = JSON.decode!(json)

    assert status["version"] == %{"name" => "26.2-ex", "protocol" => 776}
    refute Map.has_key?(status, "previewsChat")
  end
end
