defmodule JobServiceTest do
  use ExUnit.Case
  use Plug.Test
  doctest JobService.Helper

  alias JobService.Router

  @opts Router.init([])

  @sample_payload %{
    "tasks" =>
      Enum.shuffle([
        %{"name" => "task-1", "command" => "touch /tmp/file1"},
        %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
        %{"name" => "task-3", "command" => "echo 'Hello World!' > /tmp/file1", "requires" => ["task-1"]},
        %{"name" => "task-4", "command" => "rm /tmp/file1", "requires" => ["task-2", "task-3"]}
      ])
  }
  |> Jason.encode!()

  @etalon_example ["task-1", "task-3", "task-2", "task-4"]

  test "POST /jobs returns sorted tasks in JSON" do
    conn =
      conn(:post, "/jobs", @sample_payload)
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["tasks"] |> Enum.map(& &1["name"]) == @etalon_example
  end

  test "POST /jobs/script returns valid bash script" do
    conn =
      conn(:post, "/jobs/script", @sample_payload)
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.starts_with?(conn.resp_body, "#!/usr/bin/env bash")
  end
end
