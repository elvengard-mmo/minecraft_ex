defmodule MinecraftEx.PacketViewsTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.PacketViews
  alias MinecraftEx.Protocol
  alias MinecraftEx.Types.{KnownPack, RegistryEntry}

  ## Tests

  test "requests authentication during online-mode login" do
    packet = PacketViews.render(:encryption_request, %{token: <<1, 2, 3, 4>>})

    assert Map.fetch!(packet, :should_authenticate)
  end

  test "includes the server session id in Login Success" do
    packet =
      PacketViews.render(:login_success, %{
        uuid: "00010203-0405-0607-0809-0a0b0c0d0e0f",
        username: "Player"
      })

    assert Map.fetch!(packet, :session_id) == Protocol.server_session_id()
  end

  test "advertises the confirmed 26.2 core pack" do
    packet = PacketViews.render(:known_packs, %{})

    assert packet.known_packs == [
             %KnownPack{namespace: "minecraft", id: "core", version: "26.2"}
           ]
  end

  test "renders Registry Data entries without NBT" do
    packet =
      PacketViews.render(:registry_data, %{
        registry_id: "dimension_type",
        entries: ["overworld"]
      })

    assert packet.registry_id == "dimension_type"
    assert packet.entries == [%RegistryEntry{id: "overworld"}]
  end
end
