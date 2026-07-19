defmodule MinecraftEx.Types.EnumTest do
  use ExUnit.Case, async: true

  require MinecraftEx.Enums, as: Enums

  alias MinecraftEx.Types.{Byte, Enum, VarInt}

  ## Tests

  test "decodes a SimpleEnum enumerator from its wire type" do
    opts = [
      from: VarInt,
      enumerators: Enums.handshake_intent_enumerators()
    ]

    assert Enum.decode(<<3, 0xAA>>, opts) == {:transfer, <<0xAA>>}
  end

  test "encodes a SimpleEnum enumerator with wire type options" do
    opts = [
      from: {Byte, [sign: :unsigned]},
      enumerators: Enums.game_mode_enumerators()
    ]

    assert Enum.encode(:spectator, opts) == <<3>>
  end

  test "encodes negative SimpleEnum values with a signed wire type" do
    opts = [
      from: Byte,
      enumerators: Enums.previous_game_mode_enumerators()
    ]

    assert Enum.encode(:undefined, opts) == <<0xFF>>
  end
end
