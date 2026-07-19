defmodule MinecraftEx.PacketHandlers.ConfigurationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.ConfigurationPackets.PluginMessage
  alias MinecraftEx.PacketHandlers.Configuration

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
end
