defmodule MinecraftEx.ECS.Components.Session do
  @moduledoc """
  Holds the network session state attached to a Player entity.
  """

  use ElvenGard.ECS.Component,
    state: [
      connection_pid: nil,
      last_keep_alive_at: nil,
      pending_keep_alive_id: nil,
      latency_ms: nil
    ]

  @type t :: %__MODULE__{
          connection_pid: pid() | nil,
          last_keep_alive_at: integer() | nil,
          pending_keep_alive_id: integer() | nil,
          latency_ms: non_neg_integer() | nil
        }
end
