defmodule MinecraftEx.PacketHandlers.ConfigurationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Client.ConfigurationPackets.{
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
  end
end
