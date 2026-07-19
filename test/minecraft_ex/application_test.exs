defmodule MinecraftEx.ApplicationTest do
  use ExUnit.Case, async: true

  alias ElvenGard.ECS.Topology.Partition
  alias MinecraftEx.ECS.WorldPartition
  alias MinecraftEx.World.Flat

  ## Tests

  test "supervises a live partition for the Flat world" do
    world_partition_id = WorldPartition.id(Flat)

    partition_pid =
      MinecraftEx.Supervisor
      |> Supervisor.which_children()
      |> Enum.find_value(fn
        {_id, pid, :worker, [Partition]} ->
          case :sys.get_state(pid) do
            %{id: ^world_partition_id} -> pid
            _state -> nil
          end

        _child ->
          nil
      end)

    assert is_pid(partition_pid)
    assert Partition.started?(partition_pid)
  end
end
