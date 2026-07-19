defmodule MinecraftEx.Mojang.ServicesKeySet do
  @moduledoc """
  Fetches and refreshes Mojang Services keys used for player chat certificates.
  """

  use GenServer

  require Logger

  alias MinecraftEx.ChatSecurity
  alias MinecraftEx.Mojang

  @refresh_interval :timer.hours(24)
  @retry_interval :timer.minutes(1)

  @type server :: GenServer.server()
  @type fetch_error ::
          :invalid_services_public_key
          | :no_services_public_keys
          | Mojang.services_keys_error()

  ## Public API

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec profile_public_keys(server()) ::
          {:ok, [ChatSecurity.rsa_public_key()]} | {:error, fetch_error()}
  def profile_public_keys(server \\ __MODULE__) do
    GenServer.call(server, :profile_public_keys, :infinity)
  end

  ## GenServer callbacks

  @impl true
  def init(opts) do
    fetcher = Keyword.get(opts, :fetcher, &Mojang.fetch_profile_public_keys/0)
    {:ok, %{fetcher: fetcher, keys: []}, {:continue, :fetch_initial_keys}}
  end

  @impl true
  def handle_continue(:fetch_initial_keys, state) do
    case fetch_keys(state.fetcher) do
      {:ok, keys} ->
        schedule_refresh(@refresh_interval)
        {:noreply, %{state | keys: keys}}

      {:error, reason} ->
        Logger.warning("Unable to fetch Mojang Services keys: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:profile_public_keys, _from, state) do
    case state.keys do
      [] ->
        case fetch_keys(state.fetcher) do
          {:ok, keys} ->
            schedule_refresh(@refresh_interval)
            {:reply, {:ok, keys}, %{state | keys: keys}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      keys ->
        {:reply, {:ok, keys}, state}
    end
  end

  @impl true
  def handle_info(:refresh, state) do
    case fetch_keys(state.fetcher) do
      {:ok, keys} ->
        schedule_refresh(@refresh_interval)
        {:noreply, %{state | keys: keys}}

      {:error, reason} ->
        Logger.warning("Unable to refresh Mojang Services keys: #{inspect(reason)}")
        schedule_refresh(@retry_interval)
        {:noreply, state}
    end
  end

  ## Private functions

  defp fetch_keys(fetcher) do
    with {:ok, encoded_keys} <- fetcher.(),
         {:ok, keys} <- decode_keys(encoded_keys),
         false <- keys == [] do
      {:ok, keys}
    else
      true -> {:error, :no_services_public_keys}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_keys(encoded_keys) do
    Enum.reduce_while(encoded_keys, {:ok, []}, fn encoded_key, {:ok, keys} ->
      case decode_key(encoded_key) do
        {:ok, key} -> {:cont, {:ok, [key | keys]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, keys} -> {:ok, Enum.reverse(keys)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_key(encoded_key) do
    {:ok, :public_key.pem_entry_decode({:SubjectPublicKeyInfo, encoded_key, :not_encrypted})}
  rescue
    _error -> {:error, :invalid_services_public_key}
  end

  defp schedule_refresh(interval) do
    _timer = Process.send_after(self(), :refresh, interval)
    :ok
  end
end
