# MinecraftEx

**TODO: Add description**

## Updating Minecraft data

With a compatible Java runtime installed, generate every version-specific registry asset from
the official Minecraft distribution:

```bash
mix minecraft.registry_data.generate VERSION
```

The task reuses a matching local Minecraft installation when available. Missing JARs and
libraries are downloaded from Mojang, verified by SHA-1, and cached under the Mix build path.
It extracts the Minecraft version, protocol version, synchronized registries, entry identifiers,
and their wire order directly from that distribution.

Verify the committed manifest without rewriting it:

```bash
mix minecraft.registry_data.generate VERSION --check
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `minecraft_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:minecraft_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/minecraft_ex>.
