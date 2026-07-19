defmodule MinecraftEx.Types.KnownPack do
  @moduledoc """
  A data pack advertised during known packs negotiation.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.MCString

  @enforce_keys [:namespace, :id, :version]
  defstruct [:namespace, :id, :version]

  @type t :: %__MODULE__{
          namespace: String.t(),
          id: String.t(),
          version: String.t()
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {namespace, rest} = MCString.decode(data)
    {id, rest} = MCString.decode(rest)
    {version, rest} = MCString.decode(rest)

    {%__MODULE__{namespace: namespace, id: id, version: version}, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: iodata()
  def encode(%__MODULE__{} = known_pack, _opts) do
    %__MODULE__{namespace: namespace, id: id, version: version} = known_pack

    [
      MCString.encode(namespace),
      MCString.encode(id),
      MCString.encode(version)
    ]
  end
end
