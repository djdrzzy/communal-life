defmodule Gol.UpdateChannel do
	use Phoenix.Channel

#	intercept ["new_update"]

	def join("update:grid", _message, socket) do
		{:ok, socket}
	end

	# def handle_out("new_update", payload, socket) do
	# 	push socket, "new_update", payload
	# 	{:noreply, socket}
	# end

	def handle_in("user_update", payload, socket) do
		GenServer.cast(:game_of_life, {:user_update, payload})
		{:noreply, socket}
	end
end
