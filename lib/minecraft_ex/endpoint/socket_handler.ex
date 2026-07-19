defmodule MinecraftEx.Endpoint.SocketHandler do
  @moduledoc """
  Documentation for MinecraftEx.Endpoint.SocketHandler
  """

  use ElvenGard.Network.SocketHandler

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.ECS
  alias ElvenGard.Network.Socket
  alias MinecraftEx.ECS.Events.SessionDisconnected
  alias MinecraftEx.ECS.SystemPartition
  alias MinecraftEx.PacketViews

  ## SocketHandler callbacks

  @impl true
  def handle_init(%Socket{} = socket) do
    Logger.info("New connection: #{socket.id}")
    Logger.metadata(socket_id: socket.id)

    :ok = Socket.setopts(socket, packet: :raw, reuseaddr: true)

    {:ok,
     assign(socket,
       state: :init,
       token: nil,
       enc_key: nil,
       connection_pid: self()
     )}
  end

  @impl true
  def handle_message(message, %Socket{} = socket) do
    Logger.debug("New message (len: #{byte_size(message)})")
    {:ok, socket}
  end

  @impl true
  def handle_info({:keep_alive, id}, %Socket{} = socket) do
    packet = PacketViews.render(:keep_alive, %{id: id})
    :ok = Socket.send(socket, packet)
    {:ok, socket}
  end

  def handle_info({:disconnect, reason}, %Socket{} = socket) do
    {:stop, reason, socket}
  end

  @impl true
  def handle_halt(reason, %Socket{} = socket) do
    case socket.assigns do
      %{player_entity: player_entity} ->
        event = %SessionDisconnected{entity: player_entity, reason: reason}
        {:ok, [_event]} = ECS.push(event, partition: SystemPartition.id())

      _assigns ->
        :ok
    end

    Logger.info("disconnected (reason: #{inspect(reason)})")
    {:ok, socket}
  end
end
