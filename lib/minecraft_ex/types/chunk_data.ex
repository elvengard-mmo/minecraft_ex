defmodule MinecraftEx.Types.ChunkData do
  @moduledoc """
  Chunk sections, heightmaps, block entities, and lighting sent by Level Chunk With Light.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.{Byte, ByteArray, ChunkSection, Long, PalettedContainer, Short, VarInt}

  @enforce_keys [
    :heightmaps,
    :sections,
    :block_entities,
    :sky_light_mask,
    :block_light_mask,
    :empty_sky_light_mask,
    :empty_block_light_mask,
    :sky_light_updates,
    :block_light_updates
  ]

  defstruct @enforce_keys

  @type heightmap :: {0..5, [non_neg_integer()]}
  @type light_mask :: [non_neg_integer()]
  @type light_update :: binary()

  @type t :: %__MODULE__{
          heightmaps: [heightmap()],
          sections: [ChunkSection.t()],
          block_entities: [],
          sky_light_mask: light_mask(),
          block_light_mask: light_mask(),
          empty_sky_light_mask: light_mask(),
          empty_block_light_mask: light_mask(),
          sky_light_updates: [light_update()],
          block_light_updates: [light_update()]
        }

  ## Behaviour implementations

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: no_return()
  def decode(_data, _opts), do: raise(ArgumentError, "ChunkData is clientbound-only")

  @impl true
  @spec encode(t(), Keyword.t()) :: bitstring()
  def encode(%__MODULE__{} = chunk, _opts) do
    %__MODULE__{
      heightmaps: heightmaps,
      sections: sections,
      block_entities: [],
      sky_light_mask: sky_light_mask,
      block_light_mask: block_light_mask,
      empty_sky_light_mask: empty_sky_light_mask,
      empty_block_light_mask: empty_block_light_mask,
      sky_light_updates: sky_light_updates,
      block_light_updates: block_light_updates
    } = chunk

    section_data = sections |> Enum.map(&encode_section/1) |> IO.iodata_to_binary()

    IO.iodata_to_binary([
      encode_heightmaps(heightmaps),
      ByteArray.encode(section_data),
      VarInt.encode(0),
      encode_long_array(sky_light_mask),
      encode_long_array(block_light_mask),
      encode_long_array(empty_sky_light_mask),
      encode_long_array(empty_block_light_mask),
      encode_light_updates(sky_light_updates),
      encode_light_updates(block_light_updates)
    ])
  end

  ## Private function

  defp encode_heightmaps(heightmaps) do
    entries =
      Enum.map(heightmaps, fn {heightmap_id, values} ->
        [VarInt.encode(heightmap_id), encode_long_array(values)]
      end)

    [VarInt.encode(length(heightmaps)), entries]
  end

  defp encode_section(%ChunkSection{} = section) do
    %ChunkSection{
      non_air_blocks: non_air_blocks,
      fluid_count: fluid_count,
      block_states: block_states,
      biomes: biomes
    } = section

    [
      Short.encode(non_air_blocks, sign: :signed),
      Short.encode(fluid_count, sign: :signed),
      encode_paletted_container(block_states),
      encode_paletted_container(biomes)
    ]
  end

  defp encode_paletted_container(%PalettedContainer{bits_per_entry: 0} = container) do
    %PalettedContainer{palette: [value], data: []} = container
    [Byte.encode(0, sign: :unsigned), VarInt.encode(value)]
  end

  defp encode_paletted_container(%PalettedContainer{} = container) do
    %PalettedContainer{bits_per_entry: bits, palette: palette, data: data} = container

    [
      Byte.encode(bits, sign: :unsigned),
      VarInt.encode(length(palette)),
      Enum.map(palette, &VarInt.encode/1),
      Enum.map(data, &Long.encode/1)
    ]
  end

  defp encode_long_array(values) do
    [VarInt.encode(length(values)), Enum.map(values, &Long.encode/1)]
  end

  defp encode_light_updates(updates) do
    [VarInt.encode(length(updates)), Enum.map(updates, &ByteArray.encode/1)]
  end
end
