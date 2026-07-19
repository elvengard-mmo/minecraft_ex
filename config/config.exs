import Config

config :logger, :console,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:application, :socket_id],
  colors: [info: :green]

config :minecraft_ex, MinecraftEx.Endpoint,
  adapter: ElvenGard.Network.Endpoint.Adapters.Ranch,
  adapter_options: [],
  ip: "127.0.0.1",
  listener_name: :minecraft_ex,
  port: 25565,
  socket_handler: MinecraftEx.Endpoint.SocketHandler,
  transport: :tcp,
  transport_options: []

config :minecraft_ex, MinecraftEx.Endpoint.SocketHandler,
  packet_handler: MinecraftEx.Endpoint.PacketHandler,
  network_codec: MinecraftEx.Endpoint.NetworkCodec

if config_env() == :test do
  import_config "test.exs"
end
