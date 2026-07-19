defmodule MinecraftEx.PacketHandlers.LoginTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.LoginPackets.LoginAcknowledged
  alias MinecraftEx.Endpoint.NetworkCodec
  alias MinecraftEx.PacketHandlers.Login

  ## Test adapter

  defmodule Adapter do
    def send(test_process, data) do
      Kernel.send(test_process, {:sent, IO.iodata_to_binary(data)})
      :ok
    end
  end

  ## Tests

  test "enters configuration and sends the 26.2 core Known Pack" do
    socket = %Socket{
      adapter: Adapter,
      adapter_state: self(),
      encoder: NetworkCodec,
      assigns: %{state: :login, enc_key: nil}
    }

    assert {:cont, new_socket} = Login.handle_packet(%LoginAcknowledged{}, socket)
    assert new_socket.assigns.state == :configuration

    assert_receive {:sent, encoded}

    assert encoded ==
             <<22, 0x0E, 1, 9, "minecraft", 4, "core", 4, "26.2">>
  end
end
