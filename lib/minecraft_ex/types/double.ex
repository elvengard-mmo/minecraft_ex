defmodule MinecraftEx.Types.Double do
  @moduledoc """
  IEEE 754 binary64 floating-point number.
  """

  use ElvenGard.Network.Type

  @type t :: float()

  ## Behaviour implementations

  @impl true
  @spec decode(bitstring(), Keyword.t()) :: {t(), bitstring()}
  def decode(data, _opts) when is_binary(data) do
    <<value::float-64, rest::bitstring>> = data
    {value, rest}
  end

  @impl true
  @spec encode(t(), Keyword.t()) :: bitstring()
  def encode(data, _opts) when is_float(data), do: <<data::float-64>>
end
