defmodule NanopayWeb.API.Base.StatsView do
  use NanopayWeb, :view

  def render("index.json", %{stats: stats}) do
    %{
      ok: true,
      data: Enum.reduce(Map.keys(stats), %{}, fn key, data ->
        Map.put(data, key, render_one(Map.get(stats, key), __MODULE__, to_string(key)))
      end)
    }
  end

  def render(key, %{stats: stats}) when key in ["inbox", "used"] do
    Enum.reduce ["c", "u"], %{}, fn grp, res ->
      put_in(res, [grp], extract_stats(stats, grp == "c"))
    end
  end

  def render("pool", %{stats: stats}) do
    %{
      c: pool_stats(stats, true),
      u: pool_stats(stats, false)
    }
  end

  # TODO
  defp extract_stats(stats, confirmed) do
    case Enum.find(stats, & &1.c == confirmed) do
      %{} = stats ->
        Map.take(stats, [:num, :sum])
      nil ->
        %{num: 0, sum: 0}
    end
  end

  # TODO
  defp pool_stats(stats, confirmed) do
    stats
    |> Enum.filter(& &1.c == confirmed)
    |> Enum.map(& Map.take(&1, [:size, :num, :sum]))
    |> Enum.sort_by(& &1.size)
  end

end
