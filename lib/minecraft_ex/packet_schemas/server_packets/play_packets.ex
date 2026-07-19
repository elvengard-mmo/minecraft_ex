defmodule MinecraftEx.Server.PlayPackets do
  @moduledoc """
  Documentation for MinecraftEx.Server.PlayPackets
  """

  use ElvenGard.Network.PacketSerializer

  require MinecraftEx.Enums, as: Enums

  alias MinecraftEx.Types.{
    Array,
    Boolean,
    Byte,
    ChunkData,
    Double,
    Enum,
    Float,
    Identifier,
    Int,
    Long,
    Position,
    VarInt
  }

  ## Play packets

  # 0x0B Chunk Batch Finished
  @serializable true
  defpacket 0x0B, as: ChunkBatchFinished do
    field :batch_size, VarInt
  end

  # 0x0C Chunk Batch Start
  @serializable true
  defpacket 0x0C, as: ChunkBatchStart

  # 0x26 Game Event
  @serializable true
  defpacket 0x26, as: GameEvent do
    field :event, Byte, sign: :unsigned
    field :value, Float
  end

  # 0x2C Keep Alive
  @serializable true
  defpacket 0x2C, as: KeepAlive do
    field :id, Long
  end

  # 0x2D Level Chunk With Light
  @serializable true
  defpacket 0x2D, as: LevelChunkWithLight do
    field :x, Int
    field :z, Int
    field :data, ChunkData
  end

  # 0x31 Login
  @serializable true
  defpacket 0x31, as: Login do
    field :entity_id, Int
    field :is_hardcore, Boolean
    field :dimensions, Array, type: Identifier
    field :max_players, VarInt
    field :view_distance, VarInt
    field :simulation_distance, VarInt
    field :reduced_debug_info, Boolean
    field :enable_respawn_screen, Boolean
    field :limited_crafting, Boolean
    field :dimension_type, VarInt
    field :dimension_name, Identifier
    field :hashed_seed, Long

    field :game_mode, Enum,
      from: {Byte, [sign: :unsigned]},
      enumerators: Enums.game_mode_enumerators()

    field :previous_game_mode, Enum,
      from: Byte,
      enumerators: Enums.previous_game_mode_enumerators()

    field :is_debug, Boolean
    field :is_flat, Boolean
    field :has_death_location, Boolean
    field :death_dimension_name, Identifier, if: packet.has_death_location
    field :death_location, Position, if: packet.has_death_location
    field :portal_cooldown, VarInt
    field :sea_level, VarInt
    field :online_mode, Boolean
    field :enforces_secure_chat, Boolean
  end

  # 0x48 Player Position
  @serializable true
  defpacket 0x48, as: PlayerPosition do
    field :teleport_id, VarInt
    field :x, Double
    field :y, Double
    field :z, Double
    field :delta_x, Double
    field :delta_y, Double
    field :delta_z, Double
    field :yaw, Float
    field :pitch, Float
    field :relative_flags, Int
  end

  # 0x5E Set Chunk Cache Center
  @serializable true
  defpacket 0x5E, as: SetChunkCacheCenter do
    field :x, VarInt
    field :z, VarInt
  end

  # 0x5F Set Chunk Cache Radius
  @serializable true
  defpacket 0x5F, as: SetChunkCacheRadius do
    field :radius, VarInt
  end

  # 0x61 Set Default Spawn Position
  @serializable true
  defpacket 0x61, as: SetDefaultSpawnPosition do
    field :dimension, Identifier
    field :position, Position
    field :yaw, Float
    field :pitch, Float
  end

  # 0x6F Set Simulation Distance
  @serializable true
  defpacket 0x6F, as: SetSimulationDistance do
    field :distance, VarInt
  end
end
