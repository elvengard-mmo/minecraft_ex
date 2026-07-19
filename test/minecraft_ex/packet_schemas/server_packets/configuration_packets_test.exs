defmodule MinecraftEx.Server.ConfigurationPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Server.ConfigurationPackets.FinishConfiguration

  ## Tests

  test "serializes Finish Configuration on its 26.2 packet id" do
    assert {0x03, []} = FinishConfiguration.serialize(%FinishConfiguration{}, %Socket{})
  end
end
