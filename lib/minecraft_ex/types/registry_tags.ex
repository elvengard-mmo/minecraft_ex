defmodule MinecraftEx.Types.RegistryTags do
  @moduledoc """
  The network tags associated with one registry.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{Array, Identifier, RegistryTag}

  @enforce_keys [:registry_id, :tags]
  defstruct [:registry_id, :tags]

  @type t :: %__MODULE__{
          registry_id: Identifier.t(),
          tags: [RegistryTag.t()]
        }

  ## ElvenGard.Network.Type callbacks

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    {registry_id, rest} = Identifier.decode(data)
    {tags, rest} = Array.decode(rest, type: RegistryTag)

    {%__MODULE__{registry_id: registry_id, tags: tags}, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: iodata()
  def encode(%__MODULE__{} = registry_tags, _opts) do
    %__MODULE__{registry_id: registry_id, tags: tags} = registry_tags
    [Identifier.encode(registry_id), Array.encode(tags, type: RegistryTag)]
  end
end
