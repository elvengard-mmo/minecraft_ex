defmodule MinecraftEx.Mojang.ServicesKeySetTest do
  use ExUnit.Case, async: true

  alias MinecraftEx.Mojang.ServicesKeySet

  ## Tests

  test "fetches the rotating player certificate keys at startup and caches them" do
    test_process = self()
    {_private_key, public_key, public_der} = generate_key_pair(1_024)
    name = Module.concat(__MODULE__, Cached)

    fetcher = fn ->
      send(test_process, :fetched_services_keys)
      {:ok, [public_der]}
    end

    start_supervised!({ServicesKeySet, name: name, fetcher: fetcher})

    assert_receive :fetched_services_keys
    assert {:ok, [^public_key]} = ServicesKeySet.profile_public_keys(name)

    assert {:ok, [^public_key]} = ServicesKeySet.profile_public_keys(name)
    refute_receive :fetched_services_keys
  end

  ## Private functions

  defp generate_key_pair(bits) do
    private_key = :public_key.generate_key({:rsa, bits, 65_537})

    {:RSAPrivateKey, _, modulus, public_exponent, _, _, _, _, _, _, _} = private_key
    public_key = {:RSAPublicKey, modulus, public_exponent}

    {:SubjectPublicKeyInfo, public_der, :not_encrypted} =
      :public_key.pem_entry_encode(:SubjectPublicKeyInfo, public_key)

    {private_key, public_key, public_der}
  end
end
