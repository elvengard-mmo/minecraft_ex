defmodule MinecraftEx.World.Flat do
  @moduledoc """
  Deterministic flat test world used for the first playable 26.2 state.
  """

  import Bitwise, only: [{:|||, 2}, {:<<<, 2}]

  alias MinecraftEx.MinecraftData
  alias MinecraftEx.Types.{ChunkData, ChunkSection, PalettedContainer}

  @min_y -64
  @ground_y 63
  @section_count 24
  @light_section_count @section_count + 2
  @surface_section_index Integer.floor_div(@ground_y - @min_y, 16)
  @teleport_id 1

  @type chunk :: %{x: integer(), z: integer(), data: ChunkData.t()}

  ## Public API

  @spec teleport_id() :: pos_integer()
  def teleport_id(), do: @teleport_id

  @spec spawn_position() :: %{
          x: float(),
          y: float(),
          z: float(),
          delta_x: float(),
          delta_y: float(),
          delta_z: float(),
          yaw: float(),
          pitch: float()
        }
  def spawn_position() do
    %{
      x: 0.5,
      y: 64.0,
      z: 0.5,
      delta_x: 0.0,
      delta_y: 0.0,
      delta_z: 0.0,
      yaw: 0.0,
      pitch: 0.0
    }
  end

  @spec spawn_block_position() :: {0, 64, 0}
  def spawn_block_position(), do: {0, 64, 0}

  @spec spawn_chunk_position() :: {0, 0}
  def spawn_chunk_position(), do: {0, 0}

  @spec chunks_around_spawn(non_neg_integer()) :: [chunk()]
  def chunks_around_spawn(radius) do
    {spawn_chunk_x, spawn_chunk_z} = spawn_chunk_position()
    data = chunk_data()

    for x <- (spawn_chunk_x - radius)..(spawn_chunk_x + radius),
        z <- (spawn_chunk_z - radius)..(spawn_chunk_z + radius) do
      %{x: x, z: z, data: data}
    end
    |> Enum.sort_by(fn %{x: x, z: z} ->
      {abs(x - spawn_chunk_x) + abs(z - spawn_chunk_z), x, z}
    end)
  end

  ## Private function

  defp chunk_data() do
    %ChunkData{
      heightmaps: heightmaps(),
      sections: sections(),
      block_entities: [],
      sky_light_mask: [bit_mask((@surface_section_index + 2)..(@light_section_count - 1))],
      block_light_mask: [],
      empty_sky_light_mask: [bit_mask(0..(@surface_section_index + 1))],
      empty_block_light_mask: [bit_mask(0..(@light_section_count - 1))],
      sky_light_updates:
        List.duplicate(
          :binary.copy(<<0xFF>>, 2_048),
          @light_section_count - @surface_section_index - 2
        ),
      block_light_updates: []
    }
  end

  defp sections() do
    stone_id = MinecraftData.block_state_id!("minecraft:stone")
    grass_id = MinecraftData.block_state_id!("minecraft:grass_block")
    air_id = MinecraftData.block_state_id!("minecraft:air")

    biome_id =
      MinecraftData.registry_entry_id!("minecraft:worldgen/biome", "minecraft:plains")

    for section_index <- 0..(@section_count - 1) do
      block_states =
        case section_index do
          index when index < @surface_section_index -> single_value_container(stone_id)
          @surface_section_index -> surface_container(stone_id, grass_id)
          _index -> single_value_container(air_id)
        end

      %ChunkSection{
        non_air_blocks: if(section_index <= @surface_section_index, do: 4_096, else: 0),
        fluid_count: 0,
        block_states: block_states,
        biomes: single_value_container(biome_id)
      }
    end
  end

  defp single_value_container(value) do
    %PalettedContainer{bits_per_entry: 0, palette: [value], data: []}
  end

  defp surface_container(stone_id, grass_id) do
    values = List.duplicate(0, 15 * 16 * 16) ++ List.duplicate(1, 16 * 16)

    %PalettedContainer{
      bits_per_entry: 4,
      palette: [stone_id, grass_id],
      data: pack_values(values, 4)
    }
  end

  defp heightmaps() do
    stored_height = @ground_y + 1 - @min_y
    values = List.duplicate(stored_height, 16 * 16)
    packed_values = pack_values(values, 9)

    Enum.map([1, 4, 5], &{&1, packed_values})
  end

  defp pack_values(values, bits_per_entry) do
    values_per_long = Integer.floor_div(64, bits_per_entry)

    values
    |> Enum.chunk_every(values_per_long)
    |> Enum.map(fn values ->
      values
      |> Enum.with_index()
      |> Enum.reduce(0, fn {value, index}, packed ->
        packed ||| value <<< (index * bits_per_entry)
      end)
    end)
  end

  defp bit_mask(range) do
    Enum.reduce(range, 0, fn bit, mask -> mask ||| 1 <<< bit end)
  end
end
