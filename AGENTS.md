# MinecraftEx conventions

## Reference implementations

- When the user provides a reference implementation, inspect its complete relevant flow before implementing: bundles, components, systems, partitions, events, and the network boundary. Do not infer the architecture from isolated files.

## ECS architecture

- Use `ElvenGard.ECS.Bundle` for reusable entity specifications. A bundle is a creation recipe, not an ECS entity or stored state.
- Keep one Player entity and attach its session and world components to that entity.
- An entity belongs to its world/map partition. The system partition routes global events and runs global systems; it does not require session-bearing entities to belong to `:system`.
- Every partition ID assigned to a runtime entity must have a corresponding supervised `ElvenGard.ECS.Topology.Partition` process subscribed under that ID. Verify the live topology wiring with an integration test; checking entity metadata or `setup/1` alone is insufficient.
- World data modules such as `MinecraftEx.World.Flat` must not expose or manage ECS topology concerns. Partition identifiers and supervision belong to the application/ECS wiring layer.
- Global session systems must query the relevant components across entity partitions.
- ECS systems must emit domain-level endpoint commands through the MinecraftEx endpoint boundary. They must not call `Kernel.send/2`, build protocol packets, or call `ElvenGard.Network.Socket.send/2` directly.
- Protocol packet rendering and `Socket.send/2` belong in the connection process so encryption state remains process-local.
- A connection halt must emit a session-disconnection ECS event. Entity cleanup belongs in a system subscribed to that event, not in the socket handler.
