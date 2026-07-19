defmodule MinecraftEx.Endpoint.PacketHandler do
  @moduledoc """
  Documentation for MinecraftEx.Endpoint.PacketHandler
  """

  @behaviour ElvenGard.Network.PacketHandler

  require Logger

  ## PacketHandler callbacks

  @impl true
  def handle_packet(%struct{} = packet, socket) do
    case Module.split(struct) do
      ["MinecraftEx", "Client", "HandshakePackets" | _] ->
        MinecraftEx.PacketHandlers.Handshake.handle_packet(packet, socket)

      ["MinecraftEx", "Client", "LoginPackets" | _] ->
        MinecraftEx.PacketHandlers.Login.handle_packet(packet, socket)

      ["MinecraftEx", "Client", "ConfigurationPackets" | _] ->
        MinecraftEx.PacketHandlers.Configuration.handle_packet(packet, socket)

      ["MinecraftEx", "Client", "PlayPackets" | _] ->
        MinecraftEx.PacketHandlers.Play.handle_packet(packet, socket)

      _ ->
        Logger.error("No handler found for #{inspect(packet)}")
        {:halt, :handler_not_found, socket}
    end
  end
end
