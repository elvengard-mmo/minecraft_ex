defmodule MinecraftEx.ECS.Systems.SessionDisconnection do
  @moduledoc """
  Removes a Player entity after its network session disconnects.
  """

  use ElvenGard.ECS.System,
    lock_components: :sync,
    event_subscriptions: [MinecraftEx.ECS.Events.SessionDisconnected]

  alias ElvenGard.ECS.Command
  alias MinecraftEx.ECS.Events.SessionDisconnected

  ## ElvenGard.ECS.System callbacks

  @impl true
  def run(%SessionDisconnected{} = event, _context) do
    %SessionDisconnected{entity: entity} = event
    {:ok, {_entity, _components}} = Command.despawn_entity(entity)
    :ok
  end
end
