defmodule Nanopay.MAPI.Processor do
  @moduledoc """
  Mapi Processor process. Takes Txn events from the queue and either pushes or
  queries status of the tx with the configured MAPI endpoint.
  """
  require Logger
  use GenStage
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.Txn

  defstruct miner: nil

  @default_miner :taal

  @doc """
  Starts the Queue Processor, linked to the current process.
  """
  @spec start_link(keyword) :: GenServer.on_start
  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    miner = case Keyword.get(opts, :miner, @default_miner) do
      {url, opts} -> Manic.miner(url, opts)
      url -> Manic.miner(url)
    end

    {:consumer, struct(__MODULE__, miner: miner),
      subscribe_to: [{Nanopay.MAPI.Queue, max_demand: 1}]}
  end

  @impl true
  def handle_events(events, _, state) do
    Enum.each(events, & handle_txn(Coinbox.get_txn(&1), state))
    {:noreply, [], state}
  end

  # Handles the Txn - either pushing or querying with the miner
  defp handle_txn(%Txn{status: :queued} = txn, %{miner: miner}) do
    case Manic.TX.push(miner, Base.encode16(txn.rawtx)) do
      {:ok, payload} ->
        Coinbox.update_txn_with_mapi_payload(txn, payload)

      {:error, error} ->
        Logger.error "MAPI push error: #{txn.txid} : #{inspect error}"
    end
  end

  defp handle_txn(%Txn{status: :pushed, block: nil} = txn, %{miner: miner}) do
    case Manic.TX.status(miner, txn.txid) do
      {:ok, payload} ->
        Coinbox.update_txn_with_mapi_payload(txn, payload)

      {:error, error} ->
        Logger.error "MAPI status error: #{txn.txid} : #{inspect error}"
    end
  end

  defp handle_txn(_, _), do: nil

end
