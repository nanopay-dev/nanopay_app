defmodule NanopayWeb.App.PaginationComponent do
  use NanopayWeb, :component

  def pagination(assigns) do
    ~H"""
    <nav class="flex items-center justify-center space-x-0.5 text-xs font-medium">
      <.pagination_link to="/" type="prev">
        <.icon name="caret-left" class="fa w-4 h-4" />
      </.pagination_link>
      <.pagination_link to="/" type="active">
        <span>1</span>
      </.pagination_link>
      <.pagination_link to="/">
        <span>2</span>
      </.pagination_link>
      <.pagination_link to="/">
        <span>3</span>
      </.pagination_link>
      <.pagination_link to="/">
        <span>4</span>
      </.pagination_link>
      <.pagination_link to="/">
        <span>5</span>
      </.pagination_link>
      <.pagination_link to="/">
        <span>6</span>
      </.pagination_link>
      <.pagination_link to="/" type="next">
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

    ~H"""
    <%= live_redirect to: @to, class: "flex items-center justify-center w-10 h-10 bg-white rounded-sm #{colors} transition-colors" do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

end
