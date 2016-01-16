defmodule Gol.GameOfLife.DisplayInfo do
	defstruct counter: 0, width: 0, height: 0, game_state: HashDict.new
end

defmodule Gol.GameOfLife do
	use GenServer

	def init({:display_server, display_server, :width, width, :height, height, :time_interval, time_interval}) do
		initial_game_state = gol_iteration(new, width, height, fn acc, x, y ->
			set_x_y acc, x, y, :random.uniform(2) -1
		end)

		initial_state = new |> 
			set_counter(0) |>
			set_width(width) |>
			set_height(height) |>
			set_game_state(initial_game_state) |>
			set_display_server(display_server)

		:timer.send_interval(time_interval, :step)

		{:ok, initial_state}
	end

	def start_link(args) do
		IO.puts "Starting Gol.GameOfLife"

		GenServer.start_link(__MODULE__, args, name: :game_of_life)
	end

	def handle_cast({:user_update, coord_change}, state) do
		game_state = game_state state
	  new_game_state = set_x_y game_state, coord_change["x"], coord_change["y"], 1
		new_state = set_game_state state, new_game_state
		{:noreply, new_state}
	end

	def handle_info(:step, state) do
		new_state = step state

		display_info = %Gol.GameOfLife.DisplayInfo{counter: counter(new_state),
																							 width: width(new_state),
																							 height: height(new_state),
																							 game_state: game_state(new_state)}
		
		GenServer.cast(display_server(new_state), {:display, display_info})

		{:noreply, new_state}
	end

	def handle_info(_, state), do: {:noreply, state}

	def step(game_of_life) do
		step_counter(game_of_life) |> step_game
	end

	def step_counter(game_of_life) do
		set_counter(game_of_life, counter(game_of_life) + 1)
	end

	def step_game(game_of_life) do
		current_game_state = game_state(game_of_life)

		width = width(game_of_life)
		height = height(game_of_life)

		new_game_state = gol_iteration(current_game_state, width, height, fn acc, x, y ->
			current_val = x_y current_game_state, x, y

			top_val = x_y current_game_state, x, y + 1
			top_right_val = x_y current_game_state, x + 1, y + 1
			right_val = x_y current_game_state, x + 1, y
			bottom_right_val = x_y current_game_state, x + 1, y - 1
			bottom_val = x_y current_game_state, x, y - 1
			bottom_left_val = x_y current_game_state, x - 1, y - 1
			left_val = x_y current_game_state, x - 1, y
			left_top_val = x_y current_game_state, x - 1, y + 1

	    # Any live cell with fewer than two live neighbours dies, as if caused by under-population.
			# Any live cell with two or three live neighbours lives on to the next generation.
			# Any live cell with more than three live neighbours dies, as if by overcrowding.
			# Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

			live_neighbours = top_val + top_right_val + right_val + bottom_right_val + bottom_val + bottom_left_val + left_val + left_top_val
			
			new_val = case {current_val, live_neighbours} do
									{1, x} when x < 2 -> 0
									{1, 2} -> 1
									{1, 3} -> 1
									{1, x} when x > 3 -> 0
									{0, 3} -> 1
									_ -> current_val
								end
			

			set_x_y acc, x, y, new_val
		end)

		set_game_state game_of_life, new_game_state
	end

	def gol_iteration(original, width, height, cell_step) do
		Enum.reduce(0..width-1, original, 
																fn (x, acc) ->
																	Enum.reduce(0..height-1, acc,
																		fn (y, acc) ->
																			cell_step.(acc, x, y)
																		end)
																end)

	end

	# Creation

	def new do
		HashDict.new
	end

	# Getters

	def display_server(game_of_life) do
		HashDict.get(game_of_life, :display_server)
	end

	def counter(game_of_life) do
		HashDict.get(game_of_life, :counter)
	end

	def width(game_of_life) do
		HashDict.get(game_of_life, :width)
	end

	def height(game_of_life) do
		HashDict.get(game_of_life, :height)
	end

	def game_state(game_of_life) do
		HashDict.get(game_of_life, :game_state)
	end

	def x_y(game_of_life, x, y) do
		HashDict.get(game_of_life, {x, y}, 0)
	end

	# Setters

	def set_display_server(game_of_life, val) do
		HashDict.put(game_of_life, :display_server, val)
	end

	def set_counter(game_of_life, val) do
		HashDict.put(game_of_life, :counter, val)
	end

	def set_width(game_of_life, val) do
		HashDict.put(game_of_life, :width, val)
	end

	def set_height(game_of_life, val) do
		HashDict.put(game_of_life, :height, val)
	end

	def set_game_state(game_of_life, val) do
		HashDict.put(game_of_life, :game_state, val)
	end

	def set_x_y(game_of_life, x, y, val) do
		HashDict.put(game_of_life, {x, y}, val)
	end

end


defmodule Gol.GameOfLife.Display do
	use GenServer
	use Bitwise

	def init(initial_state) do
		{:ok, initial_state}
	end

	def start_link do
		IO.puts "Starting Gol.GameOfLife.Display"

		GenServer.start_link(__MODULE__, %{highwater: 0}, name: :game_of_life_display)
	end
	
	def handle_cast({:display, gol_state}, state) do
		people_connected = length(Phoenix.PubSub.Local.subscribers(Gol.PubSub, "update:grid", 0))

		new_highwater = if people_connected > state.highwater, do: people_connected, else: state.highwater

		new_state = %{state | highwater: new_highwater}
		
		display_gol gol_state.game_state, gol_state.width, gol_state.height, gol_state.counter, people_connected, new_highwater
		
		{:noreply, new_state}
	end

	def display_gol(current_game_state, width, height, counter, people_connected, highwater) do		
		game_state = Enum.reduce(0..height-1, 0, 
														 fn (y, acc) ->
															 line = Enum.reduce(0..width-1, acc,
																 fn (x, acc) ->
																	 current_val = HashDict.get(current_game_state, {x, y})
																	 bit_val = if current_val == 0, do: 0, else: 1
																	 new_val = acc + bit_val
																	 new_val <<< 1
																 end)
															 line
														 end)



		
		game_state = game_state >>> 1

		converted_game_state = Base.encode64(:binary.encode_unsigned(game_state))
		

		Gol.Endpoint.broadcast! "update:grid", "new_update", %{step: counter, 
		 																											 width: width,
		 																											 height: height,
																													 people_connected: people_connected,
																													 highwater: highwater,
		 																											 game_state: converted_game_state}



		IO.puts "step: #{counter} byte_size: #{byte_size converted_game_state}"
	end
	
end

