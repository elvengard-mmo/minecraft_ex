defmodule MinecraftEx.PacketHandlers.Login do
  @moduledoc """
  TODO: Documentation for MinecraftEx.PacketHandlers.Login
  """

  require Logger

  import ElvenGard.Network.Socket, only: [assign: 2]

  alias ElvenGard.Network.Socket
  alias MinecraftEx.Crypto

  alias MinecraftEx.Client.LoginPackets.{
    EncryptionResponse,
    LoginStart,
    LoginAcknowledged
  }

  alias MinecraftEx.PacketViews
  alias MinecraftEx.Mojang

  ## Public API

  def handle_packet(%LoginStart{name: name, player_uuid: player_uuid}, socket) do
    Logger.info("#{name} is trying to login (uuid: #{player_uuid})")

    token = :crypto.strong_rand_bytes(4)
    render = PacketViews.render(:encryption_request, %{token: token})
    :ok = Socket.send(socket, render)

    {:cont, assign(socket, username: name, token: token, uuid: player_uuid)}
  end

  def handle_packet(
        %EncryptionResponse{shared_secret: shared_secret, verify_token: verify_token},
        socket
      ) do
    %{
      token: token,
      username: username,
      uuid: uuid
    } = socket.assigns

    with ^token <- Crypto.decrypt(verify_token),
         secret <- Crypto.decrypt(shared_secret),
         {:ok, %{"name" => ^username} = data} <- Mojang.verify_session(username, secret),
         ^uuid <- normalize_uuid(data["id"]) do
      new_socket = assign(socket, enc_key: secret)

      render = PacketViews.render(:login_success, %{uuid: uuid, username: username})
      :ok = Socket.send(new_socket, render)

      {:cont, new_socket}
    else
      _ -> {:halt, :invalid_token, socket}
    end
  end

  def handle_packet(%LoginAcknowledged{}, socket) do
    {:cont, assign(socket, state: :configuration)}
  end

  def handle_packet(packet, socket) do
    Logger.warning("no handler for #{inspect(packet)} in #{inspect(__MODULE__)}")
    {:halt, socket}
  end

  ## Private functions

  defp normalize_uuid(<<a::binary-8, b::binary-4, c::binary-4, d::binary-4, e::binary-12>>) do
    <<a::binary, "-", b::binary, "-", c::binary, "-", d::binary, "-", e::binary>>
  end
end
