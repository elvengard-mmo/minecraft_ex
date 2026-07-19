defmodule MinecraftEx.PacketHandlers.LoginTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.LoginPackets.LoginAcknowledged
  alias MinecraftEx.PacketHandlers.Login

  ## Tests

  test "enters configuration without sending Finish Configuration" do
    socket = %Socket{assigns: %{state: :login}}

    assert {:cont, new_socket} = Login.handle_packet(%LoginAcknowledged{}, socket)
    assert new_socket.assigns.state == :configuration
  end
end
