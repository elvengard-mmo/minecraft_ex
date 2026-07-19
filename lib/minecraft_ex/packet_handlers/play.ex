defmodule MinecraftEx.PacketHandlers.Play do
  @moduledoc """
  Handles packets received during the Play state.
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias MinecraftEx.ChatSecurity
  alias MinecraftEx.Client.PlayPackets.{ChatMessage, ChatSessionUpdate, ClientTickEnd}
  alias MinecraftEx.Mojang.ServicesKeySet
  alias MinecraftEx.Types.ChatSession

  ## Public API

  def handle_packet(%ChatSessionUpdate{} = packet, socket) do
    %ChatSessionUpdate{chat_session: chat_session} = packet
    %ChatSession{session_id: session_id} = chat_session
    %{uuid: player_uuid} = socket.assigns
    services_key_set = Map.get(socket.assigns, :services_key_set, ServicesKeySet)

    with {:ok, service_keys} <- ServicesKeySet.profile_public_keys(services_key_set),
         {:ok, public_key} <-
           ChatSecurity.validate_chat_session(
             chat_session,
             player_uuid,
             service_keys,
             System.system_time(:millisecond)
           ) do
      Logger.info("Validated chat session: #{session_id}")

      new_socket =
        assign(socket,
          chat_session: chat_session,
          chat_public_key: public_key,
          chat_chain: ChatSecurity.new_chain()
        )

      {:cont, new_socket}
    else
      {:error, reason} ->
        Logger.warning("Rejected chat session #{session_id}: #{inspect(reason)}")
        {:halt, reason, socket}
    end
  end

  def handle_packet(%ChatMessage{} = packet, socket) do
    %ChatMessage{message: message} = packet

    %{
      uuid: player_uuid,
      username: username,
      chat_session: chat_session,
      chat_public_key: public_key,
      chat_chain: chat_chain
    } = socket.assigns

    case ChatSecurity.validate_signed_chat_message(
           packet,
           player_uuid,
           chat_session,
           public_key,
           chat_chain,
           System.system_time(:millisecond)
         ) do
      {:ok, new_chat_chain} ->
        Logger.info("Verified chat message from #{username}: #{inspect(message)}")
        {:cont, assign(socket, chat_chain: new_chat_chain)}

      {:error, reason} ->
        Logger.warning("Rejected chat message from #{username}: #{inspect(reason)}")
        {:halt, reason, socket}
    end
  end

  def handle_packet(%ClientTickEnd{}, socket) do
    {:cont, socket}
  end
end
