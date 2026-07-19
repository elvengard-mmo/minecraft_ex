defmodule MinecraftEx.ECS.Events.KeepAliveReceived do
  @moduledoc """
  Reports a Keep Alive response received from a player connection.
  """

  use ElvenGard.ECS.Event,
    fields: [entity: nil, id: nil]

  alias ElvenGard.ECS.Entity

  @type t :: %__MODULE__{
          entity: Entity.t() | nil,
          id: integer() | nil,
          partition: Entity.partition(),
          inserted_at: integer() | nil
        }
end
