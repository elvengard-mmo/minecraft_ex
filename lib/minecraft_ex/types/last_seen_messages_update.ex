defmodule MinecraftEx.Types.LastSeenMessagesUpdate do
  @moduledoc """
  The client's acknowledgement window for previously received signed messages.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{Byte, VarInt}

  @enforce_keys [:offset, :acknowledged, :checksum]
  defstruct [:offset, :acknowledged, :checksum]

  @type t :: %__MODULE__{
          offset: non_neg_integer(),
          acknowledged: 0..16_777_215,
          checksum: -128..127
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {offset, rest} = VarInt.decode(data)
    <<acknowledged::unsigned-little-24, rest::bitstring>> = rest
    {checksum, rest} = Byte.decode(rest)

    update = %__MODULE__{
      offset: offset,
      acknowledged: acknowledged,
      checksum: checksum
    }

    {update, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: bitstring()
  def encode(%__MODULE__{} = update, _opts) do
    %__MODULE__{offset: offset, acknowledged: acknowledged, checksum: checksum} = update

    [
      VarInt.encode(offset),
      <<acknowledged::unsigned-little-24>>,
      Byte.encode(checksum)
    ]
    |> IO.iodata_to_binary()
  end
end
