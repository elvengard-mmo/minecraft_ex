defmodule MinecraftEx.Types.PalettedContainer do
  @moduledoc """
  Palette and packed values used by chunk block states and biomes.
  """

  @enforce_keys [:bits_per_entry, :palette, :data]
  defstruct [:bits_per_entry, :palette, :data]

  @type t :: %__MODULE__{
          bits_per_entry: 0..8,
          palette: [non_neg_integer()],
          data: [non_neg_integer()]
        }
end
