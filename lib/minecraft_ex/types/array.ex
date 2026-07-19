defmodule MinecraftEx.Types.Array do
  @moduledoc """
  Zero or more fields of type X

  ===

  The count must be known from the context.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.VarInt

  @type t :: [any()]

  ## Behaviour impls

  @impl true
  @spec decode(bitstring, keyword) :: {t(), bitstring}
  def decode(data, opts) when is_binary(data) do
    {type, type_opts} =
      case Keyword.fetch!(opts, :type) do
        {type, opts} -> {type, opts}
        type when is_atom(type) -> {type, []}
      end

    {size, rest} = VarInt.decode(data)

    case size do
      0 ->
        {[], rest}

      size ->
        1..size
        |> Enum.reduce({[], rest}, fn _, {acc, bin} ->
          {value, rest} = type.decode(bin, type_opts)
          {[value | acc], rest}
        end)
        |> then(fn {acc, rest} -> {Enum.reverse(acc), rest} end)
    end
  end

  @impl true
  @spec encode(t(), keyword) :: bitstring
  def encode(data, opts) when is_list(data) do
    {type, type_opts} =
      case Keyword.fetch!(opts, :type) do
        {type, opts} -> {type, opts}
        type when is_atom(type) -> {type, []}
      end

    prefix = data |> length() |> VarInt.encode()
    list = Enum.map(data, &type.encode(&1, type_opts))
    :erlang.iolist_to_binary([prefix | list])
  end
end
