defmodule MinecraftEx.Endpoint do
  @moduledoc """
  TODO: Documentation for MinecraftEx.Endpoint
  """

  use ElvenGard.Network.Endpoint, otp_app: :minecraft_ex

  require Logger

  alias MinecraftEx.ECS.Components.Session

  @type command ::
          {:keep_alive, integer()}
          | {:disconnect, :keep_alive_timeout | :unexpected_keep_alive}

  ## Public API

  @spec send_to(command(), Session.t()) :: command()
  def send_to(command, %Session{connection_pid: connection_pid}) do
    Kernel.send(connection_pid, command)
  end

  ## ElvenGard.Network.Endpoint callbacks

  @impl ElvenGard.Network.Endpoint
  def handle_start(config) do
    host = Keyword.fetch!(config, :ip)
    port = Keyword.fetch!(config, :port)

    Logger.info("MinecraftEx started on #{host}:#{port}")
  end
end
