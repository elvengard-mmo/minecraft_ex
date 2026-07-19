defmodule MinecraftEx.ECS.Bundles.Player do
  @moduledoc """
  Builds the ECS specification for a connected Minecraft player.
  """

  @behaviour ElvenGard.ECS.Bundle

  alias ElvenGard.ECS
  alias ElvenGard.ECS.Entity
  alias MinecraftEx.ECS.Components.Session

  ## ElvenGard.ECS.Bundle callbacks

  @impl true
  @spec new(Enumerable.t()) :: Entity.spec()
  def new(attrs) do
    uuid = Keyword.fetch!(attrs, :uuid)
    connection_pid = Keyword.fetch!(attrs, :connection_pid)
    partition = Keyword.fetch!(attrs, :partition)

    Entity.entity_spec(
      id: uuid,
      partition: partition,
      components: [
        {Session,
         connection_pid: connection_pid,
         last_keep_alive_at: ECS.now(),
         pending_keep_alive_id: nil,
         latency_ms: nil}
      ]
    )
  end
end
