defmodule MinecraftEx.PacketHandlers.Configuration do
  @moduledoc """
  TODO: Documentation for MinecraftEx.PacketHandlers.Configuration
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.Network.Socket

  alias MinecraftEx.Client.ConfigurationPackets.{
    AcknowledgeFinishConfiguration,
    ClientInformation,
    KnownPacks,
    PluginMessage
  }

  alias MinecraftEx.PacketViews
  alias MinecraftEx.Protocol
  alias MinecraftEx.Resources
  alias MinecraftEx.Types.{KnownPack, MCString}
  alias MinecraftEx.World.Flat

  @view_distance 10
  @simulation_distance 10

  ## Public API

  def handle_packet(%PluginMessage{channel: {"minecraft", "brand"}} = packet, socket) do
    %PluginMessage{data: data} = packet
    {client_brand, <<>>} = MCString.decode(data)

    case client_brand do
      "vanilla" -> :ok
      brand -> Logger.warning("Non-vanilla client brand: #{inspect(brand)}")
    end

    {:cont, assign(socket, client_brand: client_brand)}
  end

  def handle_packet(%ClientInformation{} = info, socket) do
    Logger.info("Got info: #{inspect(info)}")
    {:cont, socket}
  end

  def handle_packet(%KnownPacks{} = packet, socket) do
    %KnownPacks{known_packs: known_packs} = packet

    core_pack = %KnownPack{
      namespace: "minecraft",
      id: "core",
      version: Protocol.minecraft_version()
    }

    [^core_pack] = known_packs
    new_socket = assign(socket, known_packs: known_packs)
    registries = Resources.vanilla_registries()

    Enum.each(registries, fn registry ->
      render = PacketViews.render(:registry_data, registry)
      :ok = Socket.send(new_socket, render)
    end)

    Logger.info("Sent #{length(registries)} vanilla registries")

    tags = Resources.vanilla_tags()
    render = PacketViews.render(:update_tags, %{registries: tags})
    :ok = Socket.send(new_socket, render)

    tag_count = Enum.sum(Enum.map(tags, &length(&1.tags)))
    Logger.info("Sent #{tag_count} vanilla tags across #{length(tags)} registries")

    render = PacketViews.render(:finish_configuration, %{})
    :ok = Socket.send(new_socket, render)

    {:cont, new_socket}
  end

  def handle_packet(%AcknowledgeFinishConfiguration{}, socket) do
    spawn_position = Flat.spawn_position()

    new_socket =
      assign(socket,
        state: :play,
        pending_teleport_id: Flat.teleport_id(),
        player_position: {spawn_position.x, spawn_position.y, spawn_position.z},
        player_rotation: {spawn_position.yaw, spawn_position.pitch},
        client_loaded: false,
        last_keep_alive_at: System.monotonic_time(:millisecond),
        pending_keep_alive_id: nil
      )

    render = PacketViews.render(:play_login, initial_play_state())
    :ok = Socket.send(new_socket, render)

    send_initial_world(new_socket, spawn_position)

    {:cont, new_socket}
  end

  ## Private functions

  defp initial_play_state() do
    %{
      entity_id: 1,
      is_hardcore: false,
      dimensions: [{"minecraft", "overworld"}],
      max_players: 100,
      view_distance: @view_distance,
      simulation_distance: @simulation_distance,
      reduced_debug_info: false,
      enable_respawn_screen: true,
      limited_crafting: false,
      dimension_type: 0,
      dimension_name: {"minecraft", "overworld"},
      hashed_seed: 0,
      game_mode: :creative,
      previous_game_mode: :undefined,
      is_debug: false,
      is_flat: true,
      has_death_location: false,
      death_dimension_name: nil,
      death_location: nil,
      portal_cooldown: 0,
      sea_level: 63,
      online_mode: true,
      enforces_secure_chat: true
    }
  end

  defp send_initial_world(socket, spawn_position) do
    player_position =
      spawn_position
      |> Map.put(:teleport_id, Flat.teleport_id())
      |> Map.put(:relative_flags, 0)

    {chunk_x, chunk_z} = Flat.spawn_chunk_position()

    initial_packets = [
      PacketViews.render(:player_position, player_position),
      PacketViews.render(:default_spawn_position, %{
        dimension: {"minecraft", "overworld"},
        position: Flat.spawn_block_position(),
        yaw: spawn_position.yaw,
        pitch: spawn_position.pitch
      }),
      PacketViews.render(:level_chunks_load_start, %{}),
      PacketViews.render(:set_chunk_cache_center, %{x: chunk_x, z: chunk_z}),
      PacketViews.render(:set_chunk_cache_radius, %{radius: @view_distance}),
      PacketViews.render(:set_simulation_distance, %{distance: @simulation_distance}),
      PacketViews.render(:chunk_batch_start, %{})
    ]

    Enum.each(initial_packets, fn packet -> :ok = Socket.send(socket, packet) end)

    chunks = Flat.chunks_around_spawn(@view_distance)

    Enum.each(chunks, fn chunk ->
      packet = PacketViews.render(:level_chunk_with_light, chunk)
      :ok = Socket.send(socket, packet)
    end)

    batch_finished = PacketViews.render(:chunk_batch_finished, %{batch_size: length(chunks)})
    :ok = Socket.send(socket, batch_finished)
  end
end
