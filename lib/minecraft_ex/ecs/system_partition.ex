defmodule MinecraftEx.ECS.SystemPartition do
  @moduledoc """
  Runs systems that are global to the server rather than tied to a world.
  """

  use ElvenGard.ECS.Topology.Partition

  alias MinecraftEx.ECS.Systems.{KeepAlive, SessionDisconnection}

  @id :system

  ## Public API

  @spec id() :: :system
  def id(), do: @id

  ## ElvenGard.ECS.Topology.Partition callbacks

  @impl true
  def setup(_opts) do
    {@id, systems: [SessionDisconnection, KeepAlive], interval: 1_000, concurrency: 1}
  end
end
