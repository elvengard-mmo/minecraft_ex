defmodule MinecraftEx.PacketHandlers.ConfigurationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Client.ConfigurationPackets.{
    AcknowledgeFinishConfiguration,
    KnownPacks,
    PluginMessage
  }

  alias MinecraftEx.PacketHandlers.Configuration
  alias MinecraftEx.Endpoint.NetworkCodec
  alias MinecraftEx.Types.{KnownPack, VarInt}

  ## Test adapter

  defmodule Adapter do
    def send(test_process, data) do
      Kernel.send(test_process, {:sent, IO.iodata_to_binary(data)})
      :ok
    end
  end

  ## Tests

  test "records the client brand from its channel payload" do
    packet = %PluginMessage{
      channel: {"minecraft", "brand"},
      data: <<7, "vanilla">>
    }

    socket = %Socket{assigns: %{state: :configuration}}

    assert {:cont, new_socket} = Configuration.handle_packet(packet, socket)
    assert new_socket.assigns.client_brand == "vanilla"
  end

  test "warns when the client brand is not vanilla" do
    packet = %PluginMessage{
      channel: {"minecraft", "brand"},
      data: <<6, "fabric">>
    }

    socket = %Socket{assigns: %{state: :configuration}}

    log =
      capture_log(fn ->
        assert {:cont, new_socket} = Configuration.handle_packet(packet, socket)
        assert new_socket.assigns.client_brand == "fabric"
      end)

    assert log =~ ~s[Non-vanilla client brand: "fabric"]
  end

  test "records the known packs selected by the client" do
    known_packs = [
      %KnownPack{namespace: "minecraft", id: "core", version: "26.2"}
    ]

    packet = %KnownPacks{known_packs: known_packs}

    socket = %Socket{
      adapter: Adapter,
      adapter_state: self(),
      encoder: NetworkCodec,
      assigns: %{state: :configuration, enc_key: nil}
    }

    assert {:cont, new_socket} = Configuration.handle_packet(packet, socket)
    assert new_socket.assigns.known_packs == known_packs

    encoded_registries =
      for _ <- 1..29 do
        assert_receive {:sent, encoded}
        encoded
      end

    assert length(encoded_registries) == 29

    assert Enum.all?(encoded_registries, fn encoded ->
             {_packet_length, packet} = VarInt.decode(encoded)
             {packet_id, _body} = VarInt.decode(packet)
             packet_id == 0x07
           end)

    assert_receive {:sent, encoded_tags}
    {_packet_length, packet} = VarInt.decode(encoded_tags)
    {packet_id, _body} = VarInt.decode(packet)
    assert packet_id == 0x0D

    assert_receive {:sent, encoded_finish}
    {_packet_length, packet} = VarInt.decode(encoded_finish)
    {packet_id, <<>>} = VarInt.decode(packet)
    assert packet_id == 0x03
  end

  test "enters play with the confirmed initial state" do
    socket = %Socket{
      adapter: Adapter,
      adapter_state: self(),
      encoder: NetworkCodec,
      assigns: %{state: :configuration, enc_key: nil}
    }

    assert {:cont, new_socket} =
             Configuration.handle_packet(%AcknowledgeFinishConfiguration{}, socket)

    assert new_socket.assigns.state == :play

    assert_receive {:sent, encoded_login}
    {_packet_length, packet} = VarInt.decode(encoded_login)
    {packet_id, body} = VarInt.decode(packet)

    assert packet_id == 0x31

    assert body ==
             <<1::32, 0, 1, 19, "minecraft:overworld", 100, 10, 10, 0, 1, 0, 0, 19,
               "minecraft:overworld", 0::64, 1, 255, 0, 0, 0, 0, 63, 1, 1>>
  end
end
