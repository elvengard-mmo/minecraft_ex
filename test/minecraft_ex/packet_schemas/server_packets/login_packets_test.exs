defmodule MinecraftEx.Server.LoginPacketsTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Server.LoginPackets.{EncryptionRequest, LoginSuccess}

  ## Tests

  test "serializes the should authenticate flag in Encryption Request" do
    packet =
      struct!(EncryptionRequest, %{
        server_id: "",
        public_key: <<1, 2, 3>>,
        verify_token: <<4, 5, 6, 7>>,
        should_authenticate: true
      })

    assert {0x01, encoded} = EncryptionRequest.serialize(packet, %Socket{})
    assert IO.iodata_to_binary(encoded) == <<0, 3, 1, 2, 3, 4, 4, 5, 6, 7, 1>>
  end

  test "serializes the server session id after the game profile in Login Success" do
    packet =
      struct!(LoginSuccess, %{
        uuid: "00010203-0405-0607-0809-0a0b0c0d0e0f",
        username: "A",
        properties: [],
        session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f"
      })

    assert {0x02, encoded} = LoginSuccess.serialize(packet, %Socket{})

    assert IO.iodata_to_binary(encoded) ==
             <<
               0x00,
               0x01,
               0x02,
               0x03,
               0x04,
               0x05,
               0x06,
               0x07,
               0x08,
               0x09,
               0x0A,
               0x0B,
               0x0C,
               0x0D,
               0x0E,
               0x0F,
               0x01,
               "A",
               0x00,
               0x10,
               0x11,
               0x12,
               0x13,
               0x14,
               0x15,
               0x16,
               0x17,
               0x18,
               0x19,
               0x1A,
               0x1B,
               0x1C,
               0x1D,
               0x1E,
               0x1F
             >>
  end
end
