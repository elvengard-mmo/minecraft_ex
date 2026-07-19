defmodule MinecraftEx.Protocol do
  @moduledoc """
  Version and session metadata for the supported Minecraft protocol.
  """

  alias ElvenGard.Network.UUID
  alias MinecraftEx.MinecraftData

  ## Public API

  @spec setup!() :: :ok
  def setup!() do
    :persistent_term.put(server_session_id_key(), UUID.uuid4())
  end

  @spec minecraft_version() :: String.t()
  def minecraft_version(), do: MinecraftData.minecraft_version()

  @spec protocol_version() :: pos_integer()
  def protocol_version(), do: MinecraftData.protocol_version()

  @spec server_session_id() :: String.t()
  def server_session_id(), do: :persistent_term.get(server_session_id_key())

  ## Private function

  defp server_session_id_key(), do: {__MODULE__, :server_session_id}
end
