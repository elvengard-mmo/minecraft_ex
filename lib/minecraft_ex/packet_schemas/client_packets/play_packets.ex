defmodule MinecraftEx.Client.PlayPackets do
  @moduledoc """
  Packets sent by the client during the Play state.
  """

  use ElvenGard.Network.PacketSerializer

  import MinecraftEx, only: [has_state: 2]

  alias MinecraftEx.Types.{
    Boolean,
    Byte,
    ChatSession,
    Double,
    Float,
    LastSeenMessagesUpdate,
    Long,
    MCString,
    MessageSignature,
    VarInt
  }

  ## Play packets

  # 0x00 Accept Teleportation - state=play
  @deserializable true
  defpacket 0x00 when has_state(socket, :play), as: AcceptTeleportation do
    field :teleport_id, VarInt
  end

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

  # 0x0B Chunk Batch Received - state=play
  @deserializable true
  defpacket 0x0B when has_state(socket, :play), as: ChunkBatchReceived do
    field :desired_chunks_per_tick, Float
  end

  # 0x0D Client Tick End - state=play
  @deserializable true
  defpacket 0x0D when has_state(socket, :play), as: ClientTickEnd

  # 0x1E Move Player Position - state=play
  @deserializable true
  defpacket 0x1E when has_state(socket, :play), as: MovePlayerPosition do
    field :x, Double
    field :y, Double
    field :z, Double
    field :flags, Byte, sign: :unsigned
  end

  # 0x1F Move Player Position And Rotation - state=play
  @deserializable true
  defpacket 0x1F when has_state(socket, :play), as: MovePlayerPositionAndRotation do
    field :x, Double
    field :y, Double
    field :z, Double
    field :yaw, Float
    field :pitch, Float
    field :flags, Byte, sign: :unsigned
  end

  # 0x20 Move Player Rotation - state=play
  @deserializable true
  defpacket 0x20 when has_state(socket, :play), as: MovePlayerRotation do
    field :yaw, Float
    field :pitch, Float
    field :flags, Byte, sign: :unsigned
  end

  # 0x21 Move Player Status Only - state=play
  @deserializable true
  defpacket 0x21 when has_state(socket, :play), as: MovePlayerStatusOnly do
    field :flags, Byte, sign: :unsigned
  end

  # 0x28 Player Abilities - state=play
  @deserializable true
  defpacket 0x28 when has_state(socket, :play), as: PlayerAbilities do
    field :flags, Byte, sign: :unsigned
  end

  # 0x2B Player Input - state=play
  @deserializable true
  defpacket 0x2B when has_state(socket, :play), as: PlayerInput do
    field :flags, Byte, sign: :unsigned
  end

  # 0x2C Player Loaded - state=play
  @deserializable true
  defpacket 0x2C when has_state(socket, :play), as: PlayerLoaded
end
