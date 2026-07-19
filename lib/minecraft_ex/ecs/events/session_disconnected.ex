defmodule MinecraftEx.ECS.Events.SessionDisconnected do
  @moduledoc """
  Reports that the network connection attached to a Player entity halted.
  """

  use ElvenGard.ECS.Event,
    fields: [entity: nil, reason: nil]

  alias ElvenGard.ECS.Entity

  @type t :: %__MODULE__{
          entity: Entity.t() | nil,
          reason: any(),
          partition: :default | :system,
          inserted_at: integer() | nil
        }
end
