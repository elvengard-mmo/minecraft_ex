defmodule MinecraftEx.Enums do
  @moduledoc """
  Enumerations used by the Minecraft Java Edition protocol.
  """

  import SimpleEnum, only: [defenum: 2]

  ## Protocol enums

  defenum :handshake_intent, status: 1, login: 2, transfer: 3
  defenum :chat_mode, enabled: 0, commands_only: 1, hidden: 2
  defenum :main_hand, left: 0, right: 1
  defenum :particle_status, all: 0, decreased: 1, minimal: 2
  defenum :game_mode, survival: 0, creative: 1, adventure: 2, spectator: 3

  defenum :previous_game_mode,
    undefined: -1,
    survival: 0,
    creative: 1,
    adventure: 2,
    spectator: 3
end
