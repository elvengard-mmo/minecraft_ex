defmodule MinecraftEx.ChatSecurity do
  @moduledoc """
  Validates player chat certificates and signed message chains.
  """

  alias MinecraftEx.Client.PlayPackets.ChatMessage
  alias MinecraftEx.Types.{ChatSession, LastSeenMessagesUpdate, Long, UUID}

  @type rsa_public_key :: {:RSAPublicKey, non_neg_integer(), non_neg_integer()}

  @type chain :: %{
          next_index: non_neg_integer(),
          last_timestamp: Long.t()
        }

  @type session_error ::
          :expired_public_key | :invalid_public_key | :invalid_public_key_signature

  @type message_error ::
          :chain_exhausted
          | :expired_public_key
          | :invalid_last_seen_messages
          | :invalid_message_signature
          | :message_too_long
          | :missing_message_signature
          | :out_of_order_chat

  ## Public API

  @spec new_chain() :: chain()
  def new_chain() do
    %{next_index: 0, last_timestamp: 0}
  end

  @spec validate_chat_session(ChatSession.t(), String.t(), [rsa_public_key()], Long.t()) ::
          {:ok, rsa_public_key()} | {:error, session_error()}
  def validate_chat_session(%ChatSession{} = chat_session, player_uuid, service_keys, now) do
    %ChatSession{
      expires_at: expires_at,
      public_key: public_key_der,
      key_signature: key_signature
    } = chat_session

    payload = UUID.encode(player_uuid) <> <<expires_at::signed-64>> <> public_key_der

    with :ok <- validate_expiration(expires_at, now),
         {:ok, public_key} <- decode_public_key(public_key_der),
         true <- valid_signature?(payload, key_signature, service_keys) do
      {:ok, public_key}
    else
      false -> {:error, :invalid_public_key_signature}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate_signed_chat_message(
          ChatMessage.t(),
          String.t(),
          ChatSession.t(),
          rsa_public_key(),
          chain(),
          Long.t()
        ) :: {:ok, chain()} | {:error, message_error()}
  def validate_signed_chat_message(
        %ChatMessage{} = packet,
        player_uuid,
        %ChatSession{} = chat_session,
        public_key,
        chain,
        now
      ) do
    %ChatMessage{
      message: message,
      timestamp: timestamp,
      salt: salt,
      signature: signature,
      last_seen_messages: last_seen_messages
    } = packet

    %ChatSession{session_id: session_id, expires_at: expires_at} = chat_session
    %{next_index: next_index, last_timestamp: last_timestamp} = chain

    with :ok <- validate_expiration(expires_at, now),
         :ok <- validate_message_length(message),
         :ok <- validate_signature_presence(signature),
         :ok <- validate_last_seen_messages(last_seen_messages),
         :ok <- validate_timestamp(timestamp, last_timestamp),
         :ok <- validate_chain_index(next_index),
         payload <-
           signed_message_payload(
             message,
             timestamp,
             salt,
             player_uuid,
             session_id,
             next_index
           ),
         true <- :public_key.verify(payload, :sha256, signature, public_key) do
      {:ok, %{next_index: next_index + 1, last_timestamp: timestamp}}
    else
      false -> {:error, :invalid_message_signature}
      {:error, reason} -> {:error, reason}
    end
  end

  ## Private functions

  defp validate_expiration(expires_at, now) do
    if expires_at >= now do
      :ok
    else
      {:error, :expired_public_key}
    end
  end

  defp validate_message_length(message) do
    if String.length(message) <= 256 do
      :ok
    else
      {:error, :message_too_long}
    end
  end

  defp validate_signature_presence(signature) do
    if is_binary(signature) do
      :ok
    else
      {:error, :missing_message_signature}
    end
  end

  defp validate_last_seen_messages(%LastSeenMessagesUpdate{} = update) do
    %LastSeenMessagesUpdate{
      offset: offset,
      acknowledged: acknowledged,
      checksum: checksum
    } = update

    if offset == 0 and acknowledged == 0 and checksum in [0, 1] do
      :ok
    else
      {:error, :invalid_last_seen_messages}
    end
  end

  defp validate_timestamp(timestamp, last_timestamp) do
    if timestamp >= last_timestamp do
      :ok
    else
      {:error, :out_of_order_chat}
    end
  end

  defp validate_chain_index(next_index) do
    if next_index <= 2_147_483_647 do
      :ok
    else
      {:error, :chain_exhausted}
    end
  end

  defp signed_message_payload(message, timestamp, salt, player_uuid, session_id, index) do
    <<1::signed-32>> <>
      UUID.encode(player_uuid) <>
      UUID.encode(session_id) <>
      <<index::signed-32, salt::signed-64, Integer.floor_div(timestamp, 1_000)::signed-64,
        byte_size(message)::signed-32>> <>
      message <>
      <<0::signed-32>>
  end

  defp decode_public_key(public_key_der) do
    {:ok, :public_key.pem_entry_decode({:SubjectPublicKeyInfo, public_key_der, :not_encrypted})}
  rescue
    _error -> {:error, :invalid_public_key}
  end

  defp valid_signature?(payload, signature, service_keys) do
    Enum.any?(service_keys, &:public_key.verify(payload, :sha, signature, &1))
  end
end
