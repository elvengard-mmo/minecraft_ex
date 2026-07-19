defmodule MinecraftEx.PacketHandlers.Play do
  @moduledoc """
  Handles packets received during the Play state.
  """

  require Logger

  import Bitwise, only: [{:&&&, 2}]
  import ElvenGard.Network.Socket, only: [assign: 2]

  alias MinecraftEx.ChatSecurity

  alias MinecraftEx.Client.PlayPackets.{
    AcceptTeleportation,
    ChatMessage,
    ChatSessionUpdate,
    ChunkBatchReceived,
    ClientTickEnd,
    MovePlayerPosition,
    MovePlayerPositionAndRotation,
    MovePlayerRotation,
    MovePlayerStatusOnly,
    PlayerAbilities,
    PlayerInput,
    PlayerLoaded
  }

  alias MinecraftEx.Mojang.ServicesKeySet
  alias MinecraftEx.Types.ChatSession

  ## Public API

  def handle_packet(%AcceptTeleportation{} = packet, socket) do
    %AcceptTeleportation{teleport_id: teleport_id} = packet

    case socket.assigns do
      %{pending_teleport_id: ^teleport_id} ->
        {:cont, assign(socket, pending_teleport_id: nil)}

      %{pending_teleport_id: pending_teleport_id} ->
        Logger.warning(
          "Rejected teleport confirmation #{teleport_id}, expected #{inspect(pending_teleport_id)}"
        )

        {:halt, :unexpected_teleport_id, socket}
    end
  end

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

  def handle_packet(%ChunkBatchReceived{} = packet, socket) do
    %ChunkBatchReceived{desired_chunks_per_tick: desired_chunks_per_tick} = packet
    {:cont, assign(socket, desired_chunks_per_tick: desired_chunks_per_tick)}
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

  def handle_packet(%MovePlayerPosition{} = packet, socket) do
    %MovePlayerPosition{x: x, y: y, z: z, flags: flags} = packet

    {:cont,
     assign(socket,
       player_position: {x, y, z},
       movement_flags: flags
     )}
  end

  def handle_packet(%MovePlayerPositionAndRotation{} = packet, socket) do
    %MovePlayerPositionAndRotation{
      x: x,
      y: y,
      z: z,
      yaw: yaw,
      pitch: pitch,
      flags: flags
    } = packet

    {:cont,
     assign(socket,
       player_position: {x, y, z},
       player_rotation: {yaw, pitch},
       movement_flags: flags
     )}
  end

  def handle_packet(%MovePlayerRotation{} = packet, socket) do
    %MovePlayerRotation{yaw: yaw, pitch: pitch, flags: flags} = packet

    {:cont,
     assign(socket,
       player_rotation: {yaw, pitch},
       movement_flags: flags
     )}
  end

  def handle_packet(%MovePlayerStatusOnly{} = packet, socket) do
    %MovePlayerStatusOnly{flags: flags} = packet
    {:cont, assign(socket, movement_flags: flags)}
  end

  def handle_packet(%PlayerAbilities{} = packet, socket) do
    %PlayerAbilities{flags: flags} = packet
    {:cont, assign(socket, player_flying: (flags &&& 0x02) != 0)}
  end

  def handle_packet(%PlayerInput{} = packet, socket) do
    %PlayerInput{flags: flags} = packet
    {:cont, assign(socket, player_input_flags: flags)}
  end

  def handle_packet(%PlayerLoaded{}, socket) do
    %{username: username} = socket.assigns
    Logger.info("#{username} entered the world")
    {:cont, assign(socket, client_loaded: true)}
  end
end
