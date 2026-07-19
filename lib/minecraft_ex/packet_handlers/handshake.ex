defmodule MinecraftEx.PacketHandlers.Handshake do
  @moduledoc """
  TODO: Documentation for MinecraftEx.PacketHandlers.Handshake
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Client.HandshakePackets.{
    Handshake,
    PingRequest,
    StatusRequest
  }

  alias MinecraftEx.PacketViews
  alias MinecraftEx.Protocol
  alias MinecraftEx.Resources

  ## Public API

  def handle_packet(%Handshake{} = packet, socket) do
    state =
      case packet.intent do
        :status -> :status
        intent when intent in [:login, :transfer] -> :login
      end

    {:cont, assign(socket, state: state, intent: packet.intent)}
  end

  def handle_packet(%StatusRequest{}, socket) do
    render = PacketViews.render(:status_response, %{status: status_response()})
    :ok = Socket.send(socket, render)
    {:cont, socket}
  end

  def handle_packet(%PingRequest{payload: payload}, socket) do
    render = PacketViews.render(:pong_response, %{payload: payload})
    :ok = Socket.send(socket, render)
    {:halt, socket}
  end

  def handle_packet(packet, socket) do
    Logger.warning("no handler for #{inspect(packet)} in #{inspect(__MODULE__)}")
    {:halt, socket}
  end

  ## Private functions

  defp status_response() do
    %{
      version: %{
        name: "#{Protocol.minecraft_version()}-ex",
        protocol: Protocol.protocol_version()
      },
      players: %{
        max: 100,
        online: 1,
        sample: [
          %{
            name: "DarkyZ",
            id: "4566e69f-c907-48ee-8d71-d7ba5aa00d20"
          }
        ]
      },
      description: [
        %{text: "Hello from "},
        %{
          text: "Elixir",
          color: "dark_purple"
        },
        %{text: "!\n"},
        %{
          text: "ElixirElixirElixirElixirElixirElixirElixir",
          obfuscated: true
        }
      ],
      favicon: Resources.favicon(),
      enforcesSecureChat: true
    }
  end
end
