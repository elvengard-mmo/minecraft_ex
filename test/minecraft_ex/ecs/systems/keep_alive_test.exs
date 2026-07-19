defmodule MinecraftEx.ECS.Systems.KeepAliveTest do
  use ExUnit.Case, async: true

  alias ElvenGard.ECS
  alias ElvenGard.ECS.{Command, Query}
  alias MinecraftEx.ECS.Bundles.Player
  alias MinecraftEx.ECS.Components.Session
  alias MinecraftEx.ECS.Events.KeepAliveReceived
  alias MinecraftEx.ECS.Systems.KeepAlive, as: KeepAliveSystem

  ## Setup

  setup do
    uuid = "20010203-0405-0607-0809-#{System.unique_integer([:positive])}"
    partition = {__MODULE__, self()}
    spec = Player.new(uuid: uuid, connection_pid: self(), partition: partition)
    {:ok, {entity, _components}} = Command.spawn_entity(spec)

    on_exit(fn -> Command.despawn_entity(entity) end)

    %{entity: entity, partition: partition}
  end

  ## Tests

  test "sends a Keep Alive command and records it in the session", context do
    %{entity: entity, partition: partition} = context
    sent_at = ECS.now() - 15_000

    assert {:ok, _session} =
             Command.update_component(entity, Session,
               last_keep_alive_at: sent_at,
               pending_keep_alive_id: nil
             )

    assert :ok = KeepAliveSystem.run(%{partition: partition, delta: 1_000})
    assert_receive {:keep_alive, keep_alive_id}

    assert {:ok, session} = Query.fetch_component(entity, Session)
    assert session.pending_keep_alive_id == keep_alive_id
    assert session.last_keep_alive_at == keep_alive_id
  end

  test "records the latency of a matching Keep Alive response", context do
    %{entity: entity, partition: partition} = context
    sent_at = ECS.now()

    assert {:ok, _session} =
             Command.update_component(entity, Session,
               last_keep_alive_at: sent_at,
               pending_keep_alive_id: sent_at
             )

    event = %KeepAliveReceived{
      entity: entity,
      id: sent_at,
      inserted_at: sent_at + 42,
      partition: partition
    }

    assert :ok = KeepAliveSystem.run(event, %{partition: partition, delta: 1_000})

    assert {:ok, session} = Query.fetch_component(entity, Session)
    assert session.pending_keep_alive_id == nil
    assert session.latency_ms == 42
  end

  test "disconnects a session whose Keep Alive timed out", context do
    %{entity: entity, partition: partition} = context
    sent_at = ECS.now() - 15_000

    assert {:ok, _session} =
             Command.update_component(entity, Session,
               last_keep_alive_at: sent_at,
               pending_keep_alive_id: sent_at
             )

    assert :ok = KeepAliveSystem.run(%{partition: partition, delta: 1_000})
    assert_receive {:disconnect, :keep_alive_timeout}
  end
end
