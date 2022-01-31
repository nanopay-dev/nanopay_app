defmodule Nanopay.Coinbox.UnlockerTest do
  use Nanopay.DataCase
  alias Nanopay.Coinbox.Unlocker
  alias Nanopay.Coinbox.{Coin, Key}
  alias BSV.{Tx, TxOut, TxBuilder, UTXO, VM}

  def simulate(coin) do
    txout = %TxOut{satoshis: 1000, script: Key.derive_script(coin)}
    lock_tx = %Tx{outputs: [txout]}
    utxo = UTXO.from_tx(lock_tx, 0)

    %Tx{inputs: [txin]} = tx = TxBuilder.to_tx(%TxBuilder{
      inputs: [Unlocker.unlock(utxo, %{coin: coin})]
    })

    VM.eval(%VM{ctx: {tx, 0, txout}}, txin.script.chunks ++ txout.script.chunks)
  end

  test "unlocking_script/2 unlocks P2PKH output" do
    assert {:ok, vm} = simulate(%Coin{channel: 0, path: "/test"})
    assert VM.valid?(vm)
  end

  test "unlocking_script/2 unlocks P2RPH output" do
    assert {:ok, vm} = simulate(%Coin{channel: 1, path: "/test"})
    assert VM.valid?(vm)
  end

end
