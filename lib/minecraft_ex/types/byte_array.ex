defmodule MinecraftEx.Types.ByteArray do
  @moduledoc """
  Depends on context

  ===

  This is just a sequence of zero or more bytes, its meaning should be
  explained somewhere else, e.g. in the packet description. The length
  must also be known from the context.
  """

  use ElvenGard.Network.Type

  alias MinecraftEx.Types.VarInt

  @type t :: [byte()] | binary()

  ## Behaviour impls

  @impl true
  @spec decode(bitstring, keyword) :: {t(), bitstring}
  def decode(data, opts) when is_binary(data) do
    prefix = Keyword.get(opts, :prefix, true)
    as = Keyword.get(opts, :as, :list)

    data
    |> maybe_decode_prefix(prefix)
    |> format_result(as)
  end

  @impl true
  @spec encode(t(), keyword) :: bitstring
  def encode(data, opts) when is_binary(data) or is_list(data) do
    raw = if is_list(data), do: List.to_string(data), else: data

    case Keyword.get(opts, :prefix, true) do
      false ->
        raw

      true ->
        length = raw |> byte_size() |> VarInt.encode([])
        <<length::binary, raw::binary>>
    end
  end

  ## Private function

  defp maybe_decode_prefix(data, false), do: {data, ""}

  defp maybe_decode_prefix(data, true) do
    {length, rest} = VarInt.decode(data)
    <<array::binary-size(^length), rest::bitstring>> = rest
    {array, rest}
  end

  defp format_result({data, rest}, :binary), do: {data, rest}

  defp format_result({data, rest}, :list) do
    {:erlang.binary_to_list(data), rest}
  end
end
