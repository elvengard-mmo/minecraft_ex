defmodule MinecraftEx.EnumsTest do
  use ExUnit.Case, async: true

  require MinecraftEx.Enums, as: Enums

  ## Tests

  test "maps protocol enum keys and wire values in both directions" do
    assert Enums.handshake_intent(:transfer) == 3
    assert Enums.handshake_intent(3) == :transfer
    assert Enums.chat_mode(:commands_only) == 1
    assert Enums.main_hand(0) == :left
    assert Enums.particle_status(:minimal) == 2
    assert Enums.game_mode(3) == :spectator
    assert Enums.previous_game_mode(:undefined) == -1
  end
end
