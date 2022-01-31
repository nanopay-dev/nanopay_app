defmodule Nanopay.MAPI.Queue do
  @moduledoc """
  Mapi Queue process. Transactions that need to be pushed or queried must be
  placed in the queue using `push/1`.
  """
  use GenStage
  alias Nanopay.Coinbox
  alias Nanopay.Coinbox.Txn

  defstruct queue: :queue.new, demand: 0, opts: []

  @doc """
  Starts the Queue process, linked to the current process.
  """
  @spec start_link(keyword) :: GenServer.on_start
  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Pushes the given transaction to the end of queue.
  """
  @spec push(Txn.t) :: :ok
  def push(%Txn{txid: txid}), do: GenStage.cast(__MODULE__, {:push, txid})

  @doc """
  Refreshes the queue.
  """
  @spec refresh() :: :ok
  def refresh(), do: GenStage.cast(__MODULE__, :refresh)

  @impl true
  def init(opts) do
    opts = Keyword.take(opts, [
      :max_push_attempts,
      :max_status_attempts,
      :retry_push_after,
      :retry_status_after
    ])

    {:producer, struct(__MODULE__, opts: opts)}
  end

  @impl true
  def handle_cast({:push, txid}, state) do
    {events, state} =
      update_in(state.queue, & :queue.in(txid, &1))
      |> take_demanded_events()

    {:noreply, events, state}
  end

  @impl true
  def handle_cast(:refresh, state) do
    queue = Coinbox.list_txns_for_mapi(state.opts)
    |> :queue.from_list()

    {events, state} =
      update_in(state.queue, & :queue.join(&1, queue))
      |> take_demanded_events()

    {:noreply, events, state}
  end

  @impl true
  def handle_demand(demand, state) when demand > 0 do
    {events, state} =
      update_in(state.demand, & &1 + demand)
      |> take_demanded_events()

    {:noreply, events, state}
  end

  # Takes demanded events from the queue, returning a list of events and the
  # updated state
  defp take_demanded_events(state) do
    demand = :queue.len(state.queue) |> min(state.demand)
    {demanded, remaining} = :queue.split(demand, state.queue)

    state =
      update_in(state.demand, & &1 - :queue.len(demanded))
      |> Map.put(:queue, remaining)

    {:queue.to_list(demanded), state}
  end

end
