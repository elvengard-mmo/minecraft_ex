defmodule MinecraftEx.ECS.Systems.KeepAlive do
  @moduledoc """
  Sends, validates, and times out Minecraft Keep Alive exchanges.
  """

  use ElvenGard.ECS.System,
    lock_components: [MinecraftEx.ECS.Components.Session],
    event_subscriptions: [MinecraftEx.ECS.Events.KeepAliveReceived]

  require Logger

  alias ElvenGard.ECS
  alias ElvenGard.ECS.{Command, Entity, Query}
  alias MinecraftEx.ECS.Components.Session
  alias MinecraftEx.ECS.Events.KeepAliveReceived
  alias MinecraftEx.Endpoint

  @keep_alive_interval 15_000

  ## ElvenGard.ECS.System callbacks

  @impl true
  def run(_context) do
    now = ECS.now()

    {Entity, Session}
    |> Query.select(with: [Session])
    |> Query.all()
    |> Enum.each(&process_session(&1, now))

    :ok
  end

  @impl true
  def run(%KeepAliveReceived{} = event, _context) do
    %KeepAliveReceived{entity: entity, id: id, inserted_at: received_at} = event
    {:ok, session} = Query.fetch_component(entity, Session)

    case session do
      %Session{pending_keep_alive_id: ^id, last_keep_alive_at: sent_at} ->
        {:ok, _session} =
          Command.update_component(entity, Session,
            pending_keep_alive_id: nil,
            latency_ms: received_at - sent_at
          )

      %Session{pending_keep_alive_id: pending_id} ->
        Logger.warning("Unexpected Keep Alive response #{id}, expected #{inspect(pending_id)}")
        Endpoint.send_to({:disconnect, :unexpected_keep_alive}, session)
    end

    :ok
  end

  ## Private functions

  defp process_session({%Entity{} = entity, %Session{} = session}, now) do
    %Session{
      last_keep_alive_at: last_keep_alive_at,
      pending_keep_alive_id: pending_keep_alive_id
    } = session

    case pending_keep_alive_id do
      nil when now - last_keep_alive_at >= @keep_alive_interval ->
        Endpoint.send_to({:keep_alive, now}, session)

        {:ok, _session} =
          Command.update_component(entity, Session,
            last_keep_alive_at: now,
            pending_keep_alive_id: now
          )

        :ok

      keep_alive_id when now - last_keep_alive_at >= @keep_alive_interval ->
        Logger.warning("Keep Alive #{keep_alive_id} timed out")
        Endpoint.send_to({:disconnect, :keep_alive_timeout}, session)
        :ok

      _pending_keep_alive_id ->
        :ok
    end
  end
end
