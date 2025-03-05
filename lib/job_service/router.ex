defmodule JobService.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  post "/jobs" do
    {:ok, body, _} = Plug.Conn.read_body(conn)
    {:ok, %{"tasks" => tasks}} = Jason.decode(body)

    sorted_tasks = JobService.Helper.sort_tasks(tasks)

    send_resp(conn, 200, Jason.encode!(%{"tasks" => sorted_tasks}))
  end

  post "/jobs/script" do
    {:ok, body, _} = Plug.Conn.read_body(conn)
    {:ok, %{"tasks" => tasks}} = Jason.decode(body)

    sorted_tasks = JobService.Helper.sort_tasks(tasks)
    script = generate_bash_script(sorted_tasks)

    send_resp(conn, 200, script)
  end

  defp generate_bash_script(tasks) do
    commands =
      tasks
      |> Enum.map(fn %{"command" => command} -> command end)

    "#!/usr/bin/env bash\n" <> Enum.join(commands, "\n")
  end

  def start_link do
    Plug.Cowboy.http(JobService, [], port: 4000)
  end
end
