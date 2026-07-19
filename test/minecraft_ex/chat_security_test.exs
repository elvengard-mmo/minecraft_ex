defmodule MinecraftEx.ChatSecurityTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.ChatSecurity
  alias MinecraftEx.Client.PlayPackets.ChatMessage
  alias MinecraftEx.Types.{ChatSession, LastSeenMessagesUpdate, UUID}

  @player_uuid "00010203-0405-0607-0809-0a0b0c0d0e0f"
  @now 1_800_000_000_000

  ## Tests

  test "validates a player certificate signed by a Mojang Services key" do
    {service_private_key, service_public_key, _service_public_der} = generate_key_pair(1_024)
    {_player_private_key, player_public_key, player_public_der} = generate_key_pair(1_024)

    chat_session =
      signed_chat_session(player_public_der, service_private_key, @now + 60_000)

    assert {:ok, ^player_public_key} =
             ChatSecurity.validate_chat_session(
               chat_session,
               @player_uuid,
               [service_public_key],
               @now
             )
  end

  test "rejects an invalid player certificate signature" do
    {service_private_key, _service_public_key, _service_public_der} = generate_key_pair(1_024)
    {_other_private_key, other_public_key, _other_public_der} = generate_key_pair(1_024)
    {_player_private_key, _player_public_key, player_public_der} = generate_key_pair(1_024)

    chat_session =
      signed_chat_session(player_public_der, service_private_key, @now + 60_000)

    assert {:error, :invalid_public_key_signature} =
             ChatSecurity.validate_chat_session(
               chat_session,
               @player_uuid,
               [other_public_key],
               @now
             )
  end

  test "rejects an expired player certificate" do
    {service_private_key, service_public_key, _service_public_der} = generate_key_pair(1_024)
    {_player_private_key, _player_public_key, player_public_der} = generate_key_pair(1_024)

    chat_session =
      signed_chat_session(player_public_der, service_private_key, @now - 1)

    assert {:error, :expired_public_key} =
             ChatSecurity.validate_chat_session(
               chat_session,
               @player_uuid,
               [service_public_key],
               @now
             )
  end

  test "validates and advances a signed chat message chain" do
    {player_private_key, player_public_key, player_public_der} = generate_key_pair(2_048)

    chat_session = %ChatSession{
      session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f",
      expires_at: @now + 60_000,
      public_key: player_public_der,
      key_signature: <<>>
    }

    packet = signed_chat_message("hello", @now, 42, player_private_key, chat_session, 0)

    assert {:ok, %{next_index: 1, last_timestamp: @now}} =
             ChatSecurity.validate_signed_chat_message(
               packet,
               @player_uuid,
               chat_session,
               player_public_key,
               ChatSecurity.new_chain(),
               @now
             )
  end

  test "rejects a chat message with an invalid chain signature" do
    {_player_private_key, player_public_key, player_public_der} = generate_key_pair(2_048)

    chat_session = %ChatSession{
      session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f",
      expires_at: @now + 60_000,
      public_key: player_public_der,
      key_signature: <<>>
    }

    packet = %ChatMessage{
      message: "tampered",
      timestamp: @now,
      salt: 42,
      has_signature: true,
      signature: :binary.copy(<<0>>, 256),
      last_seen_messages: empty_last_seen_messages()
    }

    assert {:error, :invalid_message_signature} =
             ChatSecurity.validate_signed_chat_message(
               packet,
               @player_uuid,
               chat_session,
               player_public_key,
               ChatSecurity.new_chain(),
               @now
             )
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
    key_signature = :public_key.sign(payload, :sha, service_private_key)

    %ChatSession{
      session_id: "10111213-1415-1617-1819-1a1b1c1d1e1f",
      expires_at: expires_at,
      public_key: player_public_der,
      key_signature: key_signature
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
      last_seen_messages: empty_last_seen_messages()
    }
  end

  defp empty_last_seen_messages() do
    %LastSeenMessagesUpdate{offset: 0, acknowledged: 0, checksum: 1}
  end
end
