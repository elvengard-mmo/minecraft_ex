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
  @tag_data Map.fetch!(@data, "tags")

  @type registry :: %{
          registry_id: String.t(),
          entries: [String.t()]
        }

  @type registry_tag :: %{
          tag_id: String.t(),
          entries: [non_neg_integer()]
        }

  @type registry_tags :: %{
          registry_id: String.t(),
          tags: [registry_tag()]
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

  @spec tags() :: [registry_tags()]
  def tags() do
    Enum.map(@tag_data, fn registry_tags ->
      %{"registry_id" => registry_id, "tags" => tags} = registry_tags

      tags =
        Enum.map(tags, fn tag ->
          %{"tag_id" => tag_id, "entries" => entries} = tag
          %{tag_id: tag_id, entries: entries}
        end)

      %{registry_id: registry_id, tags: tags}
    end)
  end
end
