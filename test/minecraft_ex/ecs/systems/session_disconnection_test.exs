defmodule MinecraftEx.ECS.Systems.SessionDisconnectionTest do
  use ExUnit.Case, async: true

  alias ElvenGard.ECS.{Command, Query}
  alias MinecraftEx.ECS.Bundles.Player
  alias MinecraftEx.ECS.Events.SessionDisconnected
  alias MinecraftEx.ECS.Systems.SessionDisconnection

  ## Tests

  test "despawns the disconnected Player entity" do
    partition = {__MODULE__, self()}

    spec =
      Player.new(
        uuid: ElvenGard.ECS.UUID.uuid4(),
        connection_pid: self(),
        partition: partition
      )

    {:ok, {entity, _components}} = Command.spawn_entity(spec)

    event = %SessionDisconnected{
      entity: entity,
      reason: :closed,
      partition: :system
    }

    assert :ok = SessionDisconnection.run(event, %{partition: :system, delta: 1_000})
    assert {:error, :not_found} = Query.fetch_entity(entity.id)
  end
end
