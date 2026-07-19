defmodule MinecraftEx.Types.RegistryTag do
  @moduledoc """
  A named registry tag containing numeric registry entry IDs.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{Array, Identifier, VarInt}

  @enforce_keys [:id, :entries]
  defstruct [:id, :entries]

  @type t :: %__MODULE__{
          id: Identifier.t(),
          entries: [non_neg_integer()]
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {id, rest} = Identifier.decode(data)
    {entries, rest} = Array.decode(rest, type: VarInt)

    {%__MODULE__{id: id, entries: entries}, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: iodata()
  def encode(%__MODULE__{} = tag, _opts) do
    %__MODULE__{id: id, entries: entries} = tag
    [Identifier.encode(id), Array.encode(entries, type: VarInt)]
  end
end
