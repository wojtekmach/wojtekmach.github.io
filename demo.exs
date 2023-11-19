Mix.install([
  {:phoenix_now, github: "wojtekmach/phoenix_now"}
])

defmodule HomeLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(PhoenixNow.PubSub, "count")
    end

    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <p><code><%= :erlang.system_info(:system_architecture) %></code></p>
    <%= @count %>
    <button phx-click="inc">+</button>
    """
  end

  def handle_event("inc", _params, socket) do
    new_count = socket.assigns.count + 1
    PhoenixNow.Endpoint.broadcast_from!(self(), "count", "count", {:count, new_count})
    {:noreply, assign(socket, count: new_count)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{topic: "count", event: "count", payload: {:count, new_count}},
        socket
      ) do
    {:noreply, assign(socket, count: new_count)}
  end
end

{:ok, _} = PhoenixNow.start_link(live: HomeLive)
Process.sleep(:infinity)
