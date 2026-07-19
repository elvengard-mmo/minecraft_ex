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
    render = PacketViews.render(:play_login, initial_play_state())
    :ok = Socket.send(socket, render)

    {:cont, assign(socket, state: :play)}
  end

  ## Private functions

  defp initial_play_state() do
    %{
      entity_id: 1,
      is_hardcore: false,
      dimensions: [{"minecraft", "overworld"}],
      max_players: 100,
      view_distance: 10,
      simulation_distance: 10,
      reduced_debug_info: false,
      enable_respawn_screen: true,
      limited_crafting: false,
      dimension_type: 0,
      dimension_name: {"minecraft", "overworld"},
      hashed_seed: 0,
      game_mode: :creative,
      previous_game_mode: :undefined,
      is_debug: false,
      is_flat: false,
      has_death_location: false,
      death_dimension_name: nil,
      death_location: nil,
      portal_cooldown: 0,
      sea_level: 63,
      online_mode: true,
      enforces_secure_chat: true
    }
  end
end
