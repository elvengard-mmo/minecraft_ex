defmodule MinecraftEx.ProtocolTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Protocol

  ## Tests

  test "targets Minecraft 26.2 protocol 776" do
    assert Protocol.minecraft_version() == "26.2"
    assert Protocol.protocol_version() == 776
  end

  test "exposes one server session id for the application lifetime" do
    session_id = Protocol.server_session_id()

    assert session_id == Protocol.server_session_id()

    assert session_id =~
             ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
  end
end
