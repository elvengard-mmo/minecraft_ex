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

  alias MinecraftEx.Server.ConfigurationPackets.FinishConfiguration

  alias MinecraftEx.Server.PlayPackets.{Login}

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

  ## Play views

  @impl true
  def render(:play_login, %{entity_id: entity_id}) do
    %Login{
      entity_id: entity_id,
      is_hardcore: false,
      dimensions: [],
      max_players: 255,
      view_distance: 16,
      simulation_distance: 20,
      reduced_debug_info: false,
      enable_respawn_screen: true,
      limited_crafting: false,
      dimension_type: "dimension_type",
      dimension_name: "dimension_name",
      hashed_seed: 4567,
      game_mode: :creative,
      previous_game_mode: :creative,
      is_debug: false,
      is_flat: false,
      has_death_location: false,
      portal_cooldown: 0,
      death_dimension_name: nil,
      death_location: nil
    }
  end
end
