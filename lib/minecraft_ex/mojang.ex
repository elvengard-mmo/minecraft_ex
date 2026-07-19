defmodule MinecraftEx.Mojang do
  @moduledoc """
  Mojang session and Services API integration.
  """

  alias MinecraftEx.Crypto

  @services_keys_url ~c"https://api.minecraftservices.com/publickeys"

  @type services_keys_error ::
          :invalid_services_keys_response | {:services_keys_request_failed, any()}

  ## Public API

  @spec verify_session(String.t(), String.t()) :: {:ok, map()} | {:error, :invalid_session}
  def verify_session(username, secret) do
    server_id = ""
    public_key = Crypto.get_public_der()
    login_hash = Crypto.sha1(server_id <> secret <> public_key)

    url = ~c"https://sessionserver.mojang.com/session/minecraft/hasJoined"
    qs = URI.encode_query(%{username: username, serverId: login_hash})
    full_url = ~c"#{url}?#{qs}"
    headers = [{~c"accept", ~c"application/json"}]

    case :httpc.request(:get, {full_url, headers}, http_request_opts(), []) do
      {:ok, {{_, 200, _}, _, body}} ->
        data = body |> IO.iodata_to_binary() |> JSON.decode!()
        {:ok, data}

      _ ->
        {:error, :invalid_session}
    end
  end

  @spec fetch_profile_public_keys() ::
          {:ok, [binary()]} | {:error, services_keys_error()}
  def fetch_profile_public_keys() do
    headers = [{~c"accept", ~c"application/json"}]

    case :httpc.request(:get, {@services_keys_url, headers}, http_request_opts(), []) do
      {:ok, {{_, 200, _}, _, body}} ->
        body
        |> IO.iodata_to_binary()
        |> decode_profile_public_keys()

      {:ok, {{_, status, _}, _, _body}} ->
        {:error, {:services_keys_request_failed, status}}

      {:error, reason} ->
        {:error, {:services_keys_request_failed, reason}}
    end
  end

  ## Private functions

  defp decode_profile_public_keys(body) do
    with {:ok, %{"playerCertificateKeys" => keys}} <- JSON.decode(body),
         {:ok, public_keys} <- decode_public_keys(keys),
         false <- public_keys == [] do
      {:ok, public_keys}
    else
      _error -> {:error, :invalid_services_keys_response}
    end
  end

  defp decode_public_keys(keys) when is_list(keys) do
    Enum.reduce_while(keys, {:ok, []}, fn key, {:ok, public_keys} ->
      case key do
        %{"publicKey" => public_key} when is_binary(public_key) ->
          case Base.decode64(public_key) do
            {:ok, public_key} -> {:cont, {:ok, [public_key | public_keys]}}
            :error -> {:halt, :error}
          end

        _invalid_key ->
          {:halt, :error}
      end
    end)
    |> case do
      {:ok, public_keys} -> {:ok, Enum.reverse(public_keys)}
      :error -> :error
    end
  end

  defp http_request_opts() do
    [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]
  end
end
