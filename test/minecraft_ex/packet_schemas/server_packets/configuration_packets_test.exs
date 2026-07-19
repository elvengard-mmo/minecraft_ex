defmodule MinecraftEx.Server.ConfigurationPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Server.ConfigurationPackets.{
    FinishConfiguration,
    KnownPacks
  }

  alias MinecraftEx.Types.KnownPack

  ## Tests

  test "serializes Finish Configuration on its 26.2 packet id" do
    assert {0x03, []} = FinishConfiguration.serialize(%FinishConfiguration{}, %Socket{})
  end

  test "serializes Known Packs on its 26.2 packet id" do
    packet = %KnownPacks{
      known_packs: [
        %KnownPack{namespace: "minecraft", id: "core", version: "26.2"}
      ]
    }

    assert {0x0E, encoded} = KnownPacks.serialize(packet, %Socket{})

    assert IO.iodata_to_binary(encoded) ==
             <<1, 9, "minecraft", 4, "core", 4, "26.2">>
  end
end
