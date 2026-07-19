defmodule MinecraftEx.Resources do
  @moduledoc """
  Handles app resources
  """

  alias MinecraftEx.MinecraftData
  alias MinecraftEx.Types.Identifier

  @priv_dir :code.priv_dir(:minecraft_ex)

  @favicon_path Path.join(@priv_dir, "favicon.png")
  @external_resource @favicon_path
  @favicon_base64 @favicon_path |> File.read!() |> Base.encode64()

  @type vanilla_registry :: %{
          registry_id: Identifier.t(),
          entries: [Identifier.t()]
        }

  ## Public API

  def favicon(), do: "data:image/png;base64," <> @favicon_base64

  @spec vanilla_registries() :: [vanilla_registry()]
  def vanilla_registries() do
    Enum.map(MinecraftData.registries(), fn registry ->
      %{registry_id: registry_id, entries: entries} = registry

      %{
        registry_id: parse_identifier(registry_id),
        entries: Enum.map(entries, &parse_identifier/1)
      }
    end)
  end

  ## Private function

  defp parse_identifier(identifier) do
    [namespace, value] = String.split(identifier, ":", parts: 2)
    {namespace, value}
  end
end
