defmodule MinecraftEx.PacketHandlers.Play do
  @moduledoc """
  Handles packets received during the Play state.
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias MinecraftEx.Client.PlayPackets.{ChatSessionUpdate, ClientTickEnd}
  alias MinecraftEx.Types.ChatSession

  ## Public API

  def handle_packet(%ChatSessionUpdate{} = packet, socket) do
    %ChatSessionUpdate{chat_session: chat_session} = packet
    %ChatSession{session_id: session_id} = chat_session

    Logger.info("Updated chat session: #{session_id}")

    {:cont, assign(socket, chat_session: chat_session)}
  end

  def handle_packet(%ClientTickEnd{}, socket) do
    {:cont, socket}
  end
end
