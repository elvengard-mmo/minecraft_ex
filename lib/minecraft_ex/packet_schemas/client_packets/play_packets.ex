defmodule MinecraftEx.Client.PlayPackets do
  @moduledoc """
  Packets sent by the client during the Play state.
  """

  use ElvenGard.Network.PacketSerializer

  import MinecraftEx, only: [has_state: 2]

  alias MinecraftEx.Types.{
    Boolean,
    ChatSession,
    LastSeenMessagesUpdate,
    Long,
    MCString,
    MessageSignature
  }

  ## Play packets

  # 0x09 Chat Message - state=play
  @deserializable true
  defpacket 0x09 when has_state(socket, :play), as: ChatMessage do
    field :message, MCString
    field :timestamp, Long
    field :salt, Long
    field :has_signature, Boolean
    field :signature, MessageSignature, if: packet.has_signature
    field :last_seen_messages, LastSeenMessagesUpdate
  end

  # 0x0A Chat Session Update - state=play
  @deserializable true
  defpacket 0x0A when has_state(socket, :play), as: ChatSessionUpdate do
    field :chat_session, ChatSession
  end

  # 0x0D Client Tick End - state=play
  @deserializable true
  defpacket 0x0D when has_state(socket, :play), as: ClientTickEnd
end
