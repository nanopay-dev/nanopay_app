defmodule Nanopay.Coinbox.Key do
  @moduledoc """
  The Key module of the secure element of the Coinbox, it is used to derive
  Public Keys, locking Scripts and Signatures based on the Coinbox master key
  and derivation mechanisms.

  Functions within this module must never returns private keys or sensitive data.
  """
  alias Nanopay.Coinbox.{Coin}
  alias BSV.{Address, Contract, ExtKey, Hash, KeyPair, PrivKey, PubKey, Script, Sig, Tx, TxIn, TxOut}

  @coinbox_seed Application.fetch_env!(:nanopay, :coinbox_seed)
  @crv Curvy.Curve.secp256k1()

  @doc """
  Returns a Public Key for the given Coin.
  """
  @spec derive_pubkey(Coin.t()) :: PubKey.t()
  def derive_pubkey(%Coin{channel: channel, path: path}) do
    keypair = derive_keypair(channel_key(channel), path)
    keypair.pubkey
  end

  @doc """
  Returns a locking Script for the given Coin.
  """
  @spec derive_script(Coin.t()) :: Script.t()
  def derive_script(%Coin{channel: channel, path: path}) do
    keypair = derive_keypair(channel_key(channel), path)
    address = Address.from_pubkey(keypair.pubkey)
    contract = Contract.P2PKH.lock(0, %{address: address})

    Contract.to_script(contract)
  end

  @doc """
  Returns a signature for the given coin, using the specified transaction
  context parameters.
  """
  @spec derive_sig(Coin.t(), Tx.t(), TxIn.vin(), TxOut.t(), Sig.sighash_flag()) :: Sig.signature()
  def derive_sig(%Coin{channel: channel, path: path}, tx, vin, txout, sighash_type) do
    keypair = derive_keypair(channel_key(channel), path)
    Sig.sign(tx, vin, txout, keypair.privkey, sighash_type: sighash_type)
  end

  @doc """
  Returns a signature for the given coin, using the specified transaction
  context parameters.

  This function's final argument is a keyword list of `Nanopay.Payments.PayCtx`
  parameters which are used to control the signature preimage.
  """
  @spec derive_sig_advanced(Coin.t(), Tx.t(), TxIn.vin(), TxOut.t(), keyword) :: Sig.signature()
  def derive_sig_advanced(%Coin{channel: channel, path: path}, tx, vin, txout, opts) do
    keypair = derive_keypair(channel_key(channel), path)
    sighash_type = Keyword.get(opts, :sighash_type, Sig.sighash_flag(:default))

    tx
    |> Sig.preimage(vin, txout, sighash_type)
    |> put_preimage_parts(opts)
    |> Hash.sha256_sha256()
    |> Curvy.sign(keypair.privkey.d, hash: false)
    |> Kernel.<>(<<sighash_type>>)
  end

  # Iterates over the given options and manipulates the signature preimage
  defp put_preimage_parts(preimage, opts) do
    opts
    |> Keyword.take([:version, :outhash, :locktime, :sighash_type])
    |> Enum.reduce(preimage, &put_preimage_part/2)
  end

  # Replaces part of the preimage binary with the given data part
  defp put_preimage_part({:version, v2}, <<v1::little-32, rest::binary>>)
    when is_integer(v2) and v2 != v1,
    do: <<v2::little-32, rest::binary>>

  defp put_preimage_part({:outhash, v2}, preimage)
    when is_binary(v2) and byte_size(v2) == 32
  do
    pos = byte_size(preimage) - 40
    <<prefix::binary-size(pos), _v1::binary-32, rest::binary>> = preimage
    prefix <> v2 <> rest
  end

  defp put_preimage_part({:locktime, v2}, preimage) when is_integer(v2) do
    pos = byte_size(preimage) - 8
    <<prefix::binary-size(pos), v1::little-32, rest::binary>> = preimage
    if v2 != v1, do: prefix <> <<v2::little-32>> <> rest, else: preimage
  end

  defp put_preimage_part({:sighash_type, v2}, preimage) when is_integer(v2) do
    pos = byte_size(preimage) - 4
    <<prefix::binary-size(pos), v1::little-32>> = preimage
    if v2 != v1, do: prefix <> <<v2::little-32>>, else: preimage
  end

  defp put_preimage_part(_any, preimage), do: preimage

  # Returns the wallet master key
  defp master_key(), do: ExtKey.from_seed!(@coinbox_seed, encoding: :base64)

  # Returns the key for the given channel
  defp channel_key(channel) when is_atom(channel) do
    Coin
    |> Ecto.Enum.mappings(:channel)
    |> Keyword.fetch!(channel)
    |> channel_key()
  end

  defp channel_key(channel) when is_integer(channel),
    do: ExtKey.derive(master_key(), "m/#{channel}")

  # Derives a keypair for the given path
  defp derive_keypair(%{privkey: privkey}, path) do
    privkey.d
    |> Hash.sha256_sha256()
    |> Hash.sha256_hmac(path)
    |> modulu()
    |> PrivKey.from_binary!()
    |> KeyPair.from_privkey()
  end

  # Modulu helper
  defp modulu(<<x::big-256>>, n \\ @crv.n) do
    d = Curvy.Util.mod(x, n)
    <<d::big-256>>
  end

end
