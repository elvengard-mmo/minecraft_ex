defmodule MinecraftEx.Client.ConfigurationPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.ConfigurationPackets
  alias MinecraftEx.Types.KnownPack

  ## Tests

  test "decodes Particle Status in Client Information" do
    data = <<5, "en_us", 12, 0, 1, 0x7F, 1, 0, 1, 2>>
    socket = %Socket{assigns: %{state: :configuration}}

    packet = ConfigurationPackets.deserialize(0x00, data, socket)

    assert packet.locale == "en_us"
    assert packet.particle_status == :minimal
  end

  test "decodes Plugin Message on its 26.2 packet id without a packet-level data prefix" do
    data = <<15, "minecraft:brand", 7, "vanilla">>
    socket = %Socket{assigns: %{state: :configuration}}

    packet = ConfigurationPackets.deserialize(0x02, data, socket)

    assert packet.channel == {"minecraft", "brand"}
    assert packet.data == <<7, "vanilla">>
  end

  test "decodes Acknowledge Finish Configuration on its 26.2 packet id" do
    socket = %Socket{assigns: %{state: :configuration}}

    packet = ConfigurationPackets.deserialize(0x03, <<>>, socket)

    assert packet.__struct__ ==
             MinecraftEx.Client.ConfigurationPackets.AcknowledgeFinishConfiguration
  end

  test "decodes Known Packs on its 26.2 packet id" do
    data = <<1, 9, "minecraft", 4, "core", 4, "26.2">>
    socket = %Socket{assigns: %{state: :configuration}}

    packet = ConfigurationPackets.deserialize(0x07, data, socket)

    assert packet.known_packs == [
             %KnownPack{namespace: "minecraft", id: "core", version: "26.2"}
           ]
  end

  test "decodes an empty Known Packs response" do
    socket = %Socket{assigns: %{state: :configuration}}

    packet = ConfigurationPackets.deserialize(0x07, <<0>>, socket)

    assert packet.known_packs == []
  end
end
