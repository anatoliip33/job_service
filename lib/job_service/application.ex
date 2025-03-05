defmodule JobService.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: JobService.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: JobService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
