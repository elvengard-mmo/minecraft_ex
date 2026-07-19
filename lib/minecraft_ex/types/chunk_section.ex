defmodule MinecraftEx.Types.ChunkSection do
  @moduledoc """
  One 16×16×16 chunk section and its 4×4×4 biome palette.
  """

  alias MinecraftEx.Types.PalettedContainer

  @enforce_keys [:non_air_blocks, :fluid_count, :block_states, :biomes]
  defstruct [:non_air_blocks, :fluid_count, :block_states, :biomes]

  @type t :: %__MODULE__{
          non_air_blocks: 0..4096,
          fluid_count: 0..4096,
          block_states: PalettedContainer.t(),
          biomes: PalettedContainer.t()
        }
end
