defmodule MinecraftEx.Types.MessageSignature do
  @moduledoc """
  A fixed 256-byte player chat message signature.
  """

  use ElvenGard.Network.Type

  @signature_size 256

  @type t :: <<_::2048>>

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    <<signature::binary-size(@signature_size), rest::bitstring>> = data
    {signature, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: bitstring()
  def encode(signature, _opts) when byte_size(signature) == @signature_size do
    signature
  end
end
