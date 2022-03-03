defmodule NanopayWeb.App.PaginationComponent do
  use NanopayWeb, :component

  def pagination(assigns) do
    ~H"""
    <nav class="flex items-center justify-center space-x-0.5 text-xs font-medium">
      <.pagination_link to={build_url(@path, page: @page_number-1)} type={if @page_number == 1, do: "disabled"}>
        <.icon name="caret-left" class="fa w-4 h-4" />
      </.pagination_link>
      <%= for i <- 1..@total_pages do %>
        <.pagination_link to={build_url(@path, page: i)} type={if @page_number == i, do: "active"}>
          <span><%= i %></span>
        </.pagination_link>
      <% end %>
      <.pagination_link to={build_url(@path, page: @page_number+1)} type={if @page_number == @total_pages, do: "disabled"}>
        <.icon name="caret-right" class="fa w-4 h-4" />
      </.pagination_link>
    </nav>
    """
  end

  def pagination_link(assigns) do
    colors = case assigns[:type] do
      "active" ->
        "text-gray-100 bg-opacity-20 font-medium"
      #type when type in ["prev", "next"] ->
      #  "text-gray-300 bg-opacity-10 hover:text-gray-100 hover:bg-opacity-20"
      _ ->
        "text-gray-400 bg-opacity-5 hover:text-gray-100 hover:bg-opacity-20"
    end

    if assigns[:type] == "disabled" do
      ~H"""
      <span class="flex items-center justify-center w-10 h-10 text-gray-600 bg-white bg-opacity-5 rounded-sm">
        <%= render_slot(@inner_block) %>
      </span>
    """
    else
      ~H"""
      <%= live_patch to: @to, class: "flex items-center justify-center w-10 h-10 bg-white rounded-sm #{colors} transition-colors" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
      """
    end
  end

  defp build_url(path, query) do
    URI.to_string(%URI{
      path: path,
      query: URI.encode_query(query)
    })
  end

end
