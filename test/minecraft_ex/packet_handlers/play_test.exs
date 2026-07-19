defmodule MinecraftEx.PacketHandlers.PlayTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Client.PlayPackets.{ChatMessage, ChatSessionUpdate, ClientTickEnd}
  alias MinecraftEx.Mojang.ServicesKeySet
  alias MinecraftEx.PacketHandlers.Play
  alias MinecraftEx.Types.{ChatSession, LastSeenMessagesUpdate, UUID}

  @player_uuid "00010203-0405-0607-0809-0a0b0c0d0e0f"

  ## Tests

  test "validates and stores the client chat session" do
    {service_private_key, _service_public_key, service_public_der} = generate_key_pair(1_024)
    {_player_private_key, player_public_key, player_public_der} = generate_key_pair(1_024)
    expires_at = System.system_time(:millisecond) + 60_000

    chat_session = signed_chat_session(player_public_der, service_private_key, expires_at)

    services_key_set =
      start_supervised!({
        ServicesKeySet,
        name: nil, fetcher: fn -> {:ok, [service_public_der]} end
      })

    packet = %ChatSessionUpdate{chat_session: chat_session}

    socket = %Socket{
      assigns: %{
        state: :play,
        uuid: @player_uuid,
        services_key_set: services_key_set
      }
    }

    assert {:cont, new_socket} = Play.handle_packet(packet, socket)
    assert new_socket.assigns.chat_session == chat_session
    assert new_socket.assigns.chat_public_key == player_public_key
    assert new_socket.assigns.chat_chain == %{next_index: 0, last_timestamp: 0}
  end

  test "accepts Client Tick End without changing the socket" do
    socket = %Socket{assigns: %{state: :play}}

    assert {:cont, ^socket} = Play.handle_packet(%ClientTickEnd{}, socket)
  end

  test "accepts a valid signed chat message and advances its chain" do
    {player_private_key, player_public_key, player_public_der} = generate_key_pair(2_048)
    timestamp = System.system_time(:millisecond)

    chat_session = %ChatSession{
      session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f",
      expires_at: timestamp + 60_000,
      public_key: player_public_der,
      key_signature: <<>>
    }

    packet = signed_chat_message("hello", timestamp, 42, player_private_key, chat_session, 0)

    socket = %Socket{
      assigns: %{
        state: :play,
        uuid: @player_uuid,
        username: "Player",
        chat_session: chat_session,
        chat_public_key: player_public_key,
        chat_chain: %{next_index: 0, last_timestamp: 0}
      }
    }

    assert {:cont, new_socket} = Play.handle_packet(packet, socket)
    assert new_socket.assigns.chat_chain == %{next_index: 1, last_timestamp: timestamp}
  end

  ## Private functions

  defp generate_key_pair(bits) do
    private_key = :public_key.generate_key({:rsa, bits, 65_537})

    {:RSAPrivateKey, _, modulus, public_exponent, _, _, _, _, _, _, _} = private_key
    public_key = {:RSAPublicKey, modulus, public_exponent}

    {:SubjectPublicKeyInfo, public_der, :not_encrypted} =
      :public_key.pem_entry_encode(:SubjectPublicKeyInfo, public_key)

    {private_key, public_key, public_der}
  end

  defp signed_chat_session(player_public_der, service_private_key, expires_at) do
    payload = UUID.encode(@player_uuid) <> <<expires_at::signed-64>> <> player_public_der

    %ChatSession{
      session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f",
      expires_at: expires_at,
      public_key: player_public_der,
      key_signature: :public_key.sign(payload, :sha, service_private_key)
    }
  end

  defp signed_chat_message(
         message,
         timestamp,
         salt,
         player_private_key,
         chat_session,
         index
       ) do
    payload =
      <<1::signed-32>> <>
        UUID.encode(@player_uuid) <>
        UUID.encode(chat_session.session_id) <>
        <<index::signed-32, salt::signed-64, Integer.floor_div(timestamp, 1_000)::signed-64,
          byte_size(message)::signed-32>> <>
        message <>
        <<0::signed-32>>

    %ChatMessage{
      message: message,
      timestamp: timestamp,
      salt: salt,
      has_signature: true,
      signature: :public_key.sign(payload, :sha256, player_private_key),
      last_seen_messages: %LastSeenMessagesUpdate{
        offset: 0,
        acknowledged: 0,
        checksum: 1
      }
    }
  end
end
