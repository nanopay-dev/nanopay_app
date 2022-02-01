defmodule NanopayWeb.API.Base.StatsController do
  @moduledoc """
  TODO
  """
  use NanopayWeb, :controller
  alias Nanopay.Coinbox

  action_fallback NanopayWeb.API.FallbackController

  @doc """
  GET /stats

  Responds with service stats.
  """
  def index(conn, _params) do
    channels = [:inbox, :pool, :used]
    stats = Enum.reduce(channels, %{}, & Map.put(&2, &1, Coinbox.get_stats(&1)))
    render(conn, "index.json", stats: stats)
  end

end
