defmodule MinecraftEx.Server.ConfigurationPackets do
  @moduledoc """
  Documentation for MinecraftEx.Server.ConfigurationPackets
  """

  use ElvenGard.Network.PacketSerializer

  ## Configuration packets

  # 0x03 Finish Configuration
  @serializable true
  defpacket 0x03, as: FinishConfiguration
end
