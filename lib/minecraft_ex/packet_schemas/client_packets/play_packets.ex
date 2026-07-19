defmodule MinecraftEx.Client.PlayPackets do
  @moduledoc """
  Packets sent by the client during the Play state.
  """

  use ElvenGard.Network.PacketSerializer

  import MinecraftEx, only: [has_state: 2]

  alias MinecraftEx.Types.ChatSession

  ## Play packets

  # 0x0A Chat Session Update - state=play
  @deserializable true
  defpacket 0x0A when has_state(socket, :play), as: ChatSessionUpdate do
    field :chat_session, ChatSession
  end

  # 0x0D Client Tick End - state=play
  @deserializable true
  defpacket 0x0D when has_state(socket, :play), as: ClientTickEnd
end
