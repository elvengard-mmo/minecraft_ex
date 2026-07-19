defmodule MinecraftEx.Types.NumericTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Types.{Double, Float, Short}

  ## Tests

  test "encodes and decodes protocol floating-point values" do
    assert Float.encode(1.5) == <<1.5::float-32>>
    assert Float.decode(<<1.5::float-32, 0xFF>>) == {1.5, <<0xFF>>}

    assert Double.encode(64.0) == <<64.0::float-64>>
    assert Double.decode(<<64.0::float-64, 0xFF>>) == {64.0, <<0xFF>>}
  end

  test "encodes signed and unsigned protocol shorts" do
    assert Short.encode(-1, sign: :signed) == <<-1::signed-16>>
    assert Short.encode(65_535, sign: :unsigned) == <<65_535::unsigned-16>>
  end
end
