defmodule MinecraftEx.Endpoint.SocketHandler do
  @moduledoc """
  Documentation for MinecraftEx.Endpoint.SocketHandler
  """

  use ElvenGard.Network.SocketHandler

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.Network.Socket

  ## SocketHandler callbacks

  @impl true
  def handle_init(%Socket{} = socket) do
    Logger.info("New connection: #{socket.id}")
    Logger.metadata(socket_id: socket.id)

    :ok = Socket.setopts(socket, packet: :raw, reuseaddr: true)

    {:ok, assign(socket, state: :init, token: nil, enc_key: nil)}
  end

  @impl true
  def handle_message(message, %Socket{} = socket) do
    Logger.debug("New message (len: #{byte_size(message)})")
    {:ok, socket}
  end

  @impl true
  def handle_halt(reason, %Socket{} = socket) do
    Logger.info("disconnected (reason: #{inspect(reason)})")
    {:ok, socket}
  end
end
