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
    Enum,
    Identifier,
    Int,
    Long,
    Position,
    VarInt
  }

  ## Play packets

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
end
