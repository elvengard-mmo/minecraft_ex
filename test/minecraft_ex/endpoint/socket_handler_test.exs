defmodule MinecraftEx.Endpoint.SocketHandlerTest do
  use ExUnit.Case, async: true

  alias ElvenGard.ECS.{Command, Query}
  alias ElvenGard.Network.Socket
  alias MinecraftEx.ECS.Bundles.Player
  alias MinecraftEx.ECS.Components.Session
  alias MinecraftEx.ECS.WorldPartition
  alias MinecraftEx.Endpoint
  alias MinecraftEx.Endpoint.{NetworkCodec, SocketHandler}
  alias MinecraftEx.Types.VarInt
  alias MinecraftEx.World.Flat

  ## Test adapter

  defmodule Adapter do
    def send(test_process, data) do
      Kernel.send(test_process, {:sent, IO.iodata_to_binary(data)})
      :ok
    end

    def setopts(test_process, options) do
      Kernel.send(test_process, {:setopts, options})
      :ok
    end
  end

  ## Tests

  test "stores the connection process when initializing a socket" do
    socket = %Socket{id: "socket", adapter: Adapter, adapter_state: self()}

    assert {:ok, new_socket} = SocketHandler.handle_init(socket)
    assert new_socket.assigns.connection_pid == self()
    assert_receive {:setopts, [packet: :raw, reuseaddr: true]}
  end

  test "routes domain commands to the connection process" do
    session = %Session{connection_pid: self()}

    assert {:keep_alive, 42} = Endpoint.send_to({:keep_alive, 42}, session)
    assert_receive {:keep_alive, 42}
  end

  test "renders and encodes Keep Alive commands inside the connection process" do
    socket = %Socket{
      adapter: Adapter,
      adapter_state: self(),
      encoder: NetworkCodec,
      assigns: %{enc_key: nil}
    }

    assert {:ok, ^socket} = SocketHandler.handle_info({:keep_alive, 42}, socket)

    assert_receive {:sent, encoded}
    {_packet_length, packet_data} = VarInt.decode(encoded)
    assert {0x2C, <<42::signed-64>>} = VarInt.decode(packet_data)
  end

  test "stops the connection on a disconnect command" do
    socket = %Socket{}

    assert {:stop, :keep_alive_timeout, ^socket} =
             SocketHandler.handle_info({:disconnect, :keep_alive_timeout}, socket)
  end

  test "despawns the Player entity when the connection halts" do
    uuid = "30010203-0405-0607-0809-#{System.unique_integer([:positive])}"

    spec =
      Player.new(
        uuid: uuid,
        connection_pid: self(),
        partition: WorldPartition.id(Flat)
      )

    {:ok, {entity, _components}} = Command.spawn_entity(spec)
    on_exit(fn -> Command.despawn_entity(entity) end)
    socket = %Socket{assigns: %{player_entity: entity}}

    assert {:ok, ^socket} = SocketHandler.handle_halt(:closed, socket)
    assert_eventually(fn -> Query.fetch_entity(entity.id) == {:error, :not_found} end)
  end

  ## Private functions

  defp assert_eventually(assertion, attempts \\ 200)

  defp assert_eventually(assertion, attempts) when attempts > 0 do
    case assertion.() do
      true ->
        :ok

      false ->
        Process.sleep(10)
        assert_eventually(assertion, attempts - 1)
    end
  end

  defp assert_eventually(_assertion, 0), do: flunk("condition did not become true")
end
