defmodule MinecraftEx.Server.ConfigurationPackets do
  @moduledoc """
  Documentation for MinecraftEx.Server.ConfigurationPackets
  """

  use ElvenGard.Network.PacketSerializer

  alias MinecraftEx.Types.{Array, KnownPack}

  ## Configuration packets

  # 0x03 Finish Configuration
  @serializable true
  defpacket 0x03, as: FinishConfiguration

  # 0x0E Known Packs
  @serializable true
  defpacket 0x0E, as: KnownPacks do
    field :known_packs, Array, type: KnownPack
  end
end
