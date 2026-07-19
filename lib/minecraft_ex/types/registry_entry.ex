defmodule MinecraftEx.Types.RegistryEntry do
  @moduledoc """
  A registry entry whose data is sourced from a negotiated known pack.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{Boolean, Identifier}

  @enforce_keys [:id]
  defstruct [:id, data: nil]

  @type t :: %__MODULE__{
          id: Identifier.t() | String.t(),
          data: nil
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {id, rest} = Identifier.decode(data)
    {false, rest} = Boolean.decode(rest)

    {%__MODULE__{id: id}, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: iodata()
  def encode(%__MODULE__{data: nil} = registry_entry, _opts) do
    %__MODULE__{id: id} = registry_entry
    [Identifier.encode(id), Boolean.encode(false)]
  end
end
