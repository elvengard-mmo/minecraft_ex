defmodule MinecraftEx.Types.ChatSession do
  @moduledoc """
  The signed chat session data sent by a player.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{ByteArray, Long, UUID}

  @enforce_keys [:session_id, :expires_at, :public_key, :key_signature]
  defstruct [:session_id, :expires_at, :public_key, :key_signature]

  @type t :: %__MODULE__{
          session_id: String.t(),
          expires_at: Long.t(),
          public_key: binary(),
          key_signature: binary()
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {session_id, rest} = UUID.decode(data)
    {expires_at, rest} = Long.decode(rest)
    {public_key, rest} = ByteArray.decode(rest, prefix: true, as: :binary)
    {key_signature, rest} = ByteArray.decode(rest, prefix: true, as: :binary)

    chat_session = %__MODULE__{
      session_id: session_id,
      expires_at: expires_at,
      public_key: public_key,
      key_signature: key_signature
    }

    {chat_session, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: bitstring()
  def encode(%__MODULE__{} = chat_session, _opts) do
    %__MODULE__{
      session_id: session_id,
      expires_at: expires_at,
      public_key: public_key,
      key_signature: key_signature
    } = chat_session

    [
      UUID.encode(session_id),
      Long.encode(expires_at),
      ByteArray.encode(public_key, prefix: true),
      ByteArray.encode(key_signature, prefix: true)
    ]
    |> IO.iodata_to_binary()
  end
end
