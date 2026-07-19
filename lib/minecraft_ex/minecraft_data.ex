defmodule MinecraftEx.MinecraftData do
  @moduledoc """
  Compile-time access to the generated Minecraft version and vanilla registry data.
  """

  @data_path Path.join(:code.priv_dir(:minecraft_ex), "minecraft_data.json")
  @external_resource @data_path
  @data @data_path |> File.read!() |> JSON.decode!()

  @minecraft_version Map.fetch!(@data, "minecraft_version")
  @protocol_version Map.fetch!(@data, "protocol_version")
  @registry_data Map.fetch!(@data, "registries")

  @type registry :: %{
          registry_id: String.t(),
          entries: [String.t()]
        }

  ## Public API

  @spec minecraft_version() :: String.t()
  def minecraft_version(), do: @minecraft_version

  @spec protocol_version() :: pos_integer()
  def protocol_version(), do: @protocol_version

  @spec registries() :: [registry()]
  def registries() do
    Enum.map(@registry_data, fn registry ->
      %{"registry_id" => registry_id, "entries" => entries} = registry
      %{registry_id: registry_id, entries: entries}
    end)
  end
end
