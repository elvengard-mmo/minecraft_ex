defmodule MinecraftEx.ECS.WorldPartition do
  @moduledoc """
  Runs systems scoped to one Minecraft world instance.
  """

  use ElvenGard.ECS.Topology.Partition

  @type id :: {__MODULE__, module()}

  ## Public API

  @spec id(module()) :: id()
  def id(world), do: {__MODULE__, world}

  ## ElvenGard.ECS.Topology.Partition callbacks

  @impl true
  def setup(opts) do
    id = Keyword.fetch!(opts, :id)
    {id, systems: []}
  end
end
