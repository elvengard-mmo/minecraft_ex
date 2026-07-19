defmodule MinecraftEx.PacketHandlers.Configuration do
  @moduledoc """
  TODO: Documentation for MinecraftEx.PacketHandlers.Configuration
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Client.ConfigurationPackets.{
    AcknowledgeFinishConfiguration,
    ClientInformation,
    PluginMessage
  }

  alias MinecraftEx.PacketViews
  alias MinecraftEx.Types.MCString

  ## Public API

  def handle_packet(%PluginMessage{channel: {"minecraft", "brand"}} = packet, socket) do
    %PluginMessage{data: data} = packet
    {client_brand, <<>>} = MCString.decode(data)

    case client_brand do
      "vanilla" -> :ok
      brand -> Logger.warning("Non-vanilla client brand: #{inspect(brand)}")
    end

    {:cont, assign(socket, client_brand: client_brand)}
  end

  def handle_packet(%ClientInformation{} = info, socket) do
    Logger.info("Got info: #{inspect(info)}")
    {:cont, socket}
  end

  def handle_packet(%AcknowledgeFinishConfiguration{}, socket) do
    info = %{entity_id: 123}
    render = PacketViews.render(:play_login, info)
    :ok = Socket.send(socket, render)

    {:cont, assign(socket, state: :play)}
  end
end
