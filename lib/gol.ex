defmodule Gol do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Gol.Endpoint, []),
      # Here you could define other workers and supervisors as children
			worker(Gol.GameOfLife.Display, []),
			worker(Gol.GameOfLife, [{:display_server, :game_of_life_display, 
		 													 :width, 64, 
		 													 :height, 64, 
		 													 :time_interval, 1000}])
			]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gol.Supervisor]
    Supervisor.start_link(children, opts)

  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Gol.Endpoint.config_change(changed, removed)
    :ok
  end
end
