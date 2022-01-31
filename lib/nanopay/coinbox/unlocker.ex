defmodule Nanopay.Coinbox.Unlocker do
  @moduledoc """
  Unlocker Contract is repsonsible for unlocking (and signing) Coins internally
  using the `Nanopay.Coinbox.Key` module.
  """
  use BSV.Contract
  alias Nanopay.Coinbox.{Coin, Key}
  alias BSV.{PubKey, Sig, UTXO}

  @impl true
  def locking_script(ctx, _params), do: ctx

  @impl true
  def unlocking_script(ctx, %{coin: %Coin{} = coin}) do
    ctx
    |> derive_sig(coin)
    |> derive_pubkey(coin)
  end

  # Derives a pubkey for the given coin and pushes onto script
  defp derive_pubkey(ctx, coin) do
    pubkey = Key.derive_pubkey(coin)
    push(ctx, PubKey.to_binary(pubkey))
  end

  # Derives a signature for the given coin and pushes onto script
  defp derive_sig(
    %Contract{ctx: {tx, vin}, opts: opts, subject: %UTXO{txout: txout}} = ctx,
    %Coin{} = coin
  ) do
    signature = case Keyword.has_key?(opts, :outhash) do
      true ->
        Key.derive_sig_advanced(coin, tx, vin, txout, opts)

      false ->
        sighash_type = Keyword.get(opts, :sighash_type, Sig.sighash_flag(:default))
        Key.derive_sig(coin, tx, vin, txout, sighash_type)
    end

    push(ctx, signature)
  end

  defp derive_sig(ctx, _coin), do: push(ctx, <<0::568>>)

end
