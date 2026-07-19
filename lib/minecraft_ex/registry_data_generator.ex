defmodule MinecraftEx.RegistryDataGenerator do
  @moduledoc """
  Generates synchronized vanilla registries and network tags from an official Minecraft JAR.
  """

  @version_manifest_url "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

  @type registry :: %{String.t() => String.t() | [String.t()]}
  @type block_states :: %{String.t() => non_neg_integer()}
  @type registry_tag :: %{String.t() => String.t() | [non_neg_integer()]}
  @type registry_tags :: %{String.t() => String.t() | [registry_tag()]}

  @type manifest :: %{
          String.t() =>
            String.t() | pos_integer() | block_states() | [registry()] | [registry_tags()]
        }

  ## Public API

  @spec generate(String.t(), Keyword.t()) :: manifest()
  def generate(minecraft_version, opts \\ []) do
    cache_path = Keyword.fetch!(opts, :cache_path)
    output_path = Keyword.fetch!(opts, :output_path)
    probe_path = Keyword.fetch!(opts, :probe_path)
    minecraft_path = Keyword.get(opts, :minecraft_path, default_minecraft_path())
    java_path = Keyword.get_lazy(opts, :java_path, fn -> java_path!() end)

    version_metadata = version_metadata!(minecraft_version, minecraft_path, cache_path)
    verify_java_version!(java_path, version_metadata)

    classpath = classpath!(version_metadata, minecraft_version, minecraft_path, cache_path)
    generated_path = temporary_generated_path(minecraft_version)

    try do
      run_data_generator!(java_path, classpath, generated_path)

      %{
        minecraft_version: detected_version,
        protocol_version: protocol_version,
        registries: registries,
        tags: tags
      } = probe!(java_path, classpath, probe_path, generated_path)

      if detected_version != minecraft_version do
        raise("Requested Minecraft #{minecraft_version}, but the JAR reports #{detected_version}")
      end

      block_states = default_block_states!(generated_path)

      manifest =
        build_manifest(minecraft_version, protocol_version, registries, tags, block_states)

      write_manifest!(manifest, output_path, Keyword.get(opts, :check, false))
      manifest
    after
      File.rm_rf!(generated_path)
    end
  end

  @spec build_manifest(
          String.t(),
          pos_integer(),
          [registry()],
          [registry_tags()],
          block_states()
        ) :: manifest()
  def build_manifest(minecraft_version, protocol_version, registries, tags, block_states) do
    %{
      "minecraft_version" => minecraft_version,
      "protocol_version" => protocol_version,
      "block_states" => block_states,
      "registries" => registries,
      "tags" => tags
    }
  end

  @spec encode(manifest()) :: binary()
  def encode(manifest) do
    %{
      "minecraft_version" => minecraft_version,
      "protocol_version" => protocol_version,
      "block_states" => block_states,
      "registries" => registries,
      "tags" => tags
    } = manifest

    block_state_rows =
      block_states
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {block_id, state_id} ->
        ["    ", JSON.encode!(block_id), ":", Integer.to_string(state_id)]
      end)

    registry_rows =
      Enum.map(registries, fn registry ->
        %{"registry_id" => registry_id, "entries" => entries} = registry

        [
          "    {\"registry_id\":",
          JSON.encode!(registry_id),
          ",\"entries\":",
          JSON.encode!(entries),
          "}"
        ]
      end)

    tag_rows =
      Enum.map(tags, fn registry_tags ->
        %{"registry_id" => registry_id, "tags" => tags} = registry_tags

        [
          "    {\"registry_id\":",
          JSON.encode!(registry_id),
          ",\"tags\":",
          JSON.encode!(tags),
          "}"
        ]
      end)

    IO.iodata_to_binary([
      "{\n",
      "  \"minecraft_version\": ",
      JSON.encode!(minecraft_version),
      ",\n",
      "  \"protocol_version\": ",
      Integer.to_string(protocol_version),
      ",\n",
      "  \"block_states\": {\n",
      Enum.intersperse(block_state_rows, ",\n"),
      "\n  },\n",
      "  \"registries\": [\n",
      Enum.intersperse(registry_rows, ",\n"),
      "\n  ],\n",
      "  \"tags\": [\n",
      Enum.intersperse(tag_rows, ",\n"),
      "\n  ]\n",
      "}\n"
    ])
  end

  ## Private functions

  defp default_block_states!(generated_path) do
    generated_path
    |> Path.join("reports/blocks.json")
    |> File.read!()
    |> JSON.decode!()
    |> Map.new(fn {block_id, block} ->
      %{"states" => states} = block

      %{"id" => state_id} =
        Enum.find(states, &Map.get(&1, "default", false)) ||
          raise("Block #{block_id} has no default state")

      {block_id, state_id}
    end)
  end

  defp version_metadata!(minecraft_version, minecraft_path, cache_path) do
    local_path =
      Path.join([minecraft_path, "versions", minecraft_version, minecraft_version <> ".json"])

    cached_path = Path.join([cache_path, minecraft_version, "version.json"])

    case existing_version_metadata([local_path, cached_path], minecraft_version) do
      {:ok, metadata} ->
        metadata

      :error ->
        manifest = download_json!(@version_manifest_url)
        %{"versions" => versions} = manifest

        %{"url" => metadata_url, "sha1" => metadata_sha1} =
          Enum.find(versions, &(&1["id"] == minecraft_version)) ||
            raise("Unknown Minecraft version #{inspect(minecraft_version)}")

        metadata = download_json!(metadata_url, metadata_sha1)
        %{"id" => ^minecraft_version} = metadata
        write_file!(cached_path, JSON.encode!(metadata))
        metadata
    end
  end

  defp existing_version_metadata(paths, minecraft_version) do
    Enum.find_value(paths, :error, fn path ->
      if File.regular?(path) do
        case path |> File.read!() |> JSON.decode!() do
          %{"id" => ^minecraft_version} = metadata -> {:ok, metadata}
          %{} -> false
        end
      end
    end)
  end

  defp classpath!(version_metadata, minecraft_version, minecraft_path, cache_path) do
    %{"downloads" => %{"client" => client}, "libraries" => libraries} = version_metadata

    client_path =
      artifact_path!(
        client,
        [Path.join([minecraft_path, "versions", minecraft_version, minecraft_version <> ".jar"])],
        Path.join([cache_path, minecraft_version, "client.jar"])
      )

    library_paths =
      libraries
      |> Enum.filter(&library_enabled?/1)
      |> Enum.map(fn %{"downloads" => %{"artifact" => artifact}} ->
        %{"path" => relative_path} = artifact

        artifact_path!(
          artifact,
          [Path.join([minecraft_path, "libraries", relative_path])],
          Path.join([cache_path, minecraft_version, "libraries", relative_path])
        )
      end)

    Enum.join([client_path | library_paths], classpath_separator())
  end

  defp library_enabled?(%{"downloads" => %{"artifact" => _artifact}} = library) do
    case Map.get(library, "rules") do
      nil -> true
      rules -> evaluate_rules(rules)
    end
  end

  defp library_enabled?(%{}), do: false

  defp evaluate_rules(rules) do
    Enum.reduce(rules, false, fn rule, enabled ->
      if rule_matches?(rule) do
        rule["action"] == "allow"
      else
        enabled
      end
    end)
  end

  defp rule_matches?(rule) do
    os_matches?(Map.get(rule, "os")) and not Map.has_key?(rule, "features")
  end

  defp os_matches?(nil), do: true

  defp os_matches?(os) do
    Enum.all?(os, fn
      {"name", name} -> name == os_name()
      {"arch", arch} -> Regex.match?(Regex.compile!(arch), os_architecture())
      {"version", version} -> Regex.match?(Regex.compile!(version), os_version())
    end)
  end

  defp os_name() do
    case :os.type() do
      {:unix, :darwin} -> "osx"
      {:unix, _name} -> "linux"
      {:win32, _name} -> "windows"
    end
  end

  defp os_architecture() do
    :system_architecture |> :erlang.system_info() |> List.to_string()
  end

  defp os_version() do
    :os.version() |> Tuple.to_list() |> Enum.join(".")
  end

  defp artifact_path!(artifact, local_paths, cached_path) do
    case Enum.find(local_paths ++ [cached_path], &valid_artifact?(&1, artifact)) do
      nil -> download_artifact!(artifact, cached_path)
      path -> path
    end
  end

  defp valid_artifact?(path, artifact) do
    File.regular?(path) and file_size_matches?(path, artifact) and
      file_sha1(path) == artifact["sha1"]
  end

  defp file_size_matches?(path, %{"size" => expected_size}) do
    File.stat!(path).size == expected_size
  end

  defp file_size_matches?(_path, %{}), do: true

  defp download_artifact!(artifact, path) do
    %{"url" => url, "sha1" => expected_sha1} = artifact
    body = http_get!(url)

    ^expected_sha1 = binary_sha1(body)

    case artifact do
      %{"size" => expected_size} -> ^expected_size = byte_size(body)
      %{} -> :ok
    end

    write_file!(path, body)
    path
  end

  defp download_json!(url, expected_sha1 \\ nil) do
    body = http_get!(url)

    case expected_sha1 do
      nil -> :ok
      expected_sha1 -> ^expected_sha1 = binary_sha1(body)
    end

    JSON.decode!(body)
  end

  defp http_get!(url) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    request_options = [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    case :httpc.request(:get, {String.to_charlist(url), []}, request_options,
           body_format: :binary
         ) do
      {:ok, {{_http_version, 200, _reason}, _headers, body}} ->
        body

      {:ok, {{_http_version, status, reason}, _headers, _body}} ->
        raise("HTTP #{status} while downloading #{url}: #{reason}")

      {:error, reason} ->
        raise("Unable to download #{url}: #{inspect(reason)}")
    end
  end

  defp file_sha1(path) do
    path
    |> File.stream!(64 * 1024, [])
    |> Enum.reduce(:crypto.hash_init(:sha), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  defp binary_sha1(data) do
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end

  defp verify_java_version!(java_path, version_metadata) do
    %{"javaVersion" => %{"majorVersion" => required_version}} = version_metadata
    output = command!(java_path, ["-version"], "Java version detection")
    [_, detected_version] = Regex.run(~r/version "(?:1\.)?(\d+)/, output)
    detected_version = String.to_integer(detected_version)

    if detected_version < required_version do
      raise(
        "Minecraft requires Java #{required_version} or newer, found Java #{detected_version}"
      )
    end
  end

  defp run_data_generator!(java_path, classpath, output_path) do
    args = [
      "--class-path",
      classpath,
      "net.minecraft.data.Main",
      "--server",
      "--reports",
      "--output",
      output_path
    ]

    command!(java_path, args, "Minecraft data generator")
    :ok
  end

  defp probe!(java_path, classpath, probe_path, generated_path) do
    args = ["--class-path", classpath, probe_path, generated_path]
    output = command!(java_path, args, "Minecraft registry probe")

    probe =
      output
      |> String.split("\n")
      |> Enum.reduce(%{registries: [], tags: []}, fn line, probe ->
        case String.split(line, "\t", parts: 4) do
          ["__MINECRAFT_EX_VERSION__", version] ->
            Map.put(probe, :minecraft_version, version)

          ["__MINECRAFT_EX_PROTOCOL__", protocol] ->
            Map.put(probe, :protocol_version, String.to_integer(protocol))

          ["__MINECRAFT_EX_REGISTRY__", registry] ->
            registry = %{"registry_id" => registry, "entries" => []}
            Map.update!(probe, :registries, &[registry | &1])

          ["__MINECRAFT_EX_ENTRY__", entry] ->
            [registry | registries] = probe.registries
            %{"entries" => entries} = registry
            registry = %{registry | "entries" => [entry | entries]}
            %{probe | registries: [registry | registries]}

          ["__MINECRAFT_EX_TAG__", registry_id, tag_id, entries] ->
            tag = %{
              "tag_id" => tag_id,
              "entries" => parse_tag_entries(entries)
            }

            add_registry_tag(probe, registry_id, tag)

          _fields ->
            probe
        end
      end)

    registries =
      probe.registries
      |> Enum.reverse()
      |> Enum.map(fn registry ->
        %{"entries" => entries} = registry
        %{registry | "entries" => Enum.reverse(entries)}
      end)

    tags =
      probe.tags
      |> Enum.reverse()
      |> Enum.map(fn registry_tags ->
        %{"tags" => tags} = registry_tags
        %{registry_tags | "tags" => Enum.reverse(tags)}
      end)

    if registries == [] do
      raise("Minecraft registry probe returned no synchronized registries")
    end

    if tags == [] do
      raise("Minecraft registry probe returned no network tags")
    end

    %{
      minecraft_version: Map.fetch!(probe, :minecraft_version),
      protocol_version: Map.fetch!(probe, :protocol_version),
      registries: registries,
      tags: tags
    }
  end

  defp parse_tag_entries(entries) do
    case entries do
      "" -> []
      entries -> entries |> String.split(",") |> Enum.map(&String.to_integer/1)
    end
  end

  defp add_registry_tag(%{} = probe, registry_id, tag) do
    %{tags: registry_tags} = probe

    case registry_tags do
      [%{"registry_id" => ^registry_id, "tags" => tags} = registry | registries] ->
        registry = %{registry | "tags" => [tag | tags]}
        %{probe | tags: [registry | registries]}

      _registry_tags ->
        registry = %{"registry_id" => registry_id, "tags" => [tag]}
        %{probe | tags: [registry | registry_tags]}
    end
  end

  defp command!(executable, args, operation) do
    case System.cmd(executable, args, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> raise("#{operation} failed with exit code #{status}:\n#{output}")
    end
  end

  defp write_manifest!(manifest, output_path, true) do
    expected = encode(manifest)

    if File.read!(output_path) != expected do
      raise("Generated Minecraft data is not up to date: #{output_path}")
    end
  end

  defp write_manifest!(manifest, output_path, false) do
    write_file!(output_path, encode(manifest))
  end

  defp write_file!(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    temporary_path = path <> ".tmp-#{System.unique_integer([:positive])}"
    File.write!(temporary_path, contents)
    File.rename!(temporary_path, path)
  end

  defp java_path!() do
    System.find_executable("java") || raise("Java executable not found")
  end

  defp default_minecraft_path() do
    case :os.type() do
      {:unix, :darwin} ->
        Path.join([System.user_home!(), "Library", "Application Support", "minecraft"])

      {:unix, _name} ->
        Path.join(System.user_home!(), ".minecraft")

      {:win32, _name} ->
        Path.join(System.fetch_env!("APPDATA"), ".minecraft")
    end
  end

  defp temporary_generated_path(minecraft_version) do
    unique_id = System.unique_integer([:positive])
    Path.join(System.tmp_dir!(), "minecraft-ex-registry-#{minecraft_version}-#{unique_id}")
  end

  defp classpath_separator() do
    case :os.type() do
      {:win32, _name} -> ";"
      {:unix, _name} -> ":"
    end
  end
end
