defmodule MinecraftEx.PacketViews do
  @moduledoc """
  Documentation for MinecraftEx.PacketViews
  """

  use ElvenGard.Network.View

  alias MinecraftEx.Crypto
  alias MinecraftEx.Protocol
  alias MinecraftEx.Server.HandshakePackets.{PongResponse, StatusResponse}

  alias MinecraftEx.Server.LoginPackets.{
    EncryptionRequest,
    LoginSuccess,
    SetCompression
  }

  alias MinecraftEx.Server.ConfigurationPackets.{
    FinishConfiguration,
    KnownPacks,
    RegistryData,
    UpdateTags
  }

  alias MinecraftEx.Server.PlayPackets.{
    ChunkBatchFinished,
    ChunkBatchStart,
    GameEvent,
    KeepAlive,
    LevelChunkWithLight,
    Login,
    PlayerPosition,
    SetChunkCacheCenter,
    SetChunkCacheRadius,
    SetSimulationDistance,
    SetDefaultSpawnPosition
  }

  alias MinecraftEx.Types.{KnownPack, RegistryEntry, RegistryTag, RegistryTags}

  ## Handshake views

  @impl true
  def render(:status_response, %{status: status}) do
    %StatusResponse{json: JSON.encode!(status)}
  end

  @impl true
  def render(:pong_response, %{payload: payload}) do
    %PongResponse{payload: payload}
  end

  ## Login views

  @impl true
  def render(:encryption_request, %{token: token}) do
    %EncryptionRequest{
      # Not required - default to ""
      server_id: "",
      public_key: Crypto.get_public_der(),
      verify_token: token,
      should_authenticate: true
    }
  end

  @impl true
  def render(:login_success, %{uuid: uuid, username: username}) do
    %LoginSuccess{
      uuid: uuid,
      username: username,
      properties: [],
      session_id: Protocol.server_session_id()
    }
  end

  @impl true
  def render(:set_compression, %{threshold: threshold}) do
    %SetCompression{threshold: threshold}
  end

  ## Configuration views

  @impl true
  def render(:finish_configuration, _) do
    %FinishConfiguration{}
  end

  @impl true
  def render(:known_packs, _) do
    %KnownPacks{
      known_packs: [
        %KnownPack{
          namespace: "minecraft",
          id: "core",
          version: Protocol.minecraft_version()
        }
      ]
    }
  end

  @impl true
  def render(:registry_data, %{} = data) do
    %{registry_id: registry_id, entries: entries} = data

    %RegistryData{
      registry_id: registry_id,
      entries: Enum.map(entries, &%RegistryEntry{id: &1})
    }
  end

  @impl true
  def render(:update_tags, %{} = data) do
    %{registries: registries} = data

    registries =
      Enum.map(registries, fn registry ->
        %{registry_id: registry_id, tags: tags} = registry

        tags =
          Enum.map(tags, fn tag ->
            %{tag_id: tag_id, entries: entries} = tag
            %RegistryTag{id: tag_id, entries: entries}
          end)

        %RegistryTags{registry_id: registry_id, tags: tags}
      end)

    %UpdateTags{registries: registries}
  end

  ## Play views

  @impl true
  def render(:play_login, %{} = info) do
    struct!(Login, info)
  end

  @impl true
  def render(:player_position, %{} = position) do
    struct!(PlayerPosition, position)
  end

  @impl true
  def render(:default_spawn_position, %{} = spawn) do
    struct!(SetDefaultSpawnPosition, spawn)
  end

  @impl true
  def render(:level_chunks_load_start, _) do
    %GameEvent{event: 13, value: 0.0}
  end

  @impl true
  def render(:keep_alive, %{id: id}) do
    %KeepAlive{id: id}
  end

  @impl true
  def render(:set_chunk_cache_center, %{x: x, z: z}) do
    %SetChunkCacheCenter{x: x, z: z}
  end

  @impl true
  def render(:set_chunk_cache_radius, %{radius: radius}) do
    %SetChunkCacheRadius{radius: radius}
  end

  @impl true
  def render(:set_simulation_distance, %{distance: distance}) do
    %SetSimulationDistance{distance: distance}
  end

  @impl true
  def render(:chunk_batch_start, _) do
    %ChunkBatchStart{}
  end

  @impl true
  def render(:level_chunk_with_light, %{} = chunk) do
    struct!(LevelChunkWithLight, chunk)
  end

  @impl true
  def render(:chunk_batch_finished, %{batch_size: batch_size}) do
    %ChunkBatchFinished{batch_size: batch_size}
  end
end
