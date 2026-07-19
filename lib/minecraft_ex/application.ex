defmodule MinecraftEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ElvenGard.ECS.Topology.EventSource
  alias MinecraftEx.{Crypto, Protocol}
  alias MinecraftEx.ECS.{SystemPartition, WorldPartition}
  alias MinecraftEx.Mojang.ServicesKeySet
  alias MinecraftEx.World.Flat

  ## Application behaviour

  @impl true
  def start(_type, _args) do
    children = [
      EventSource,
      SystemPartition,
      {WorldPartition, id: WorldPartition.id(Flat)},
      ServicesKeySet,
      MinecraftEx.Endpoint
    ]

    # Setup protocol-wide state
    _ = Crypto.setup!()
    :ok = Protocol.setup!()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MinecraftEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
