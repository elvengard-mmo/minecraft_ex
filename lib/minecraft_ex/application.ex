defmodule MinecraftEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MinecraftEx.{Crypto, Protocol}

  ## Application behaviour

  @impl true
  def start(_type, _args) do
    children = [MinecraftEx.Endpoint]

    # Setup protocol-wide state
    _ = Crypto.setup!()
    :ok = Protocol.setup!()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MinecraftEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
