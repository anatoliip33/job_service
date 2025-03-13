defmodule JobServiceTest do
  use ExUnit.Case
  use Plug.Test
  doctest JobService.Helper

  alias JobService.Router

  @opts Router.init([])

  @sample_payload %{
    "tasks" =>
      Enum.shuffle([
        %{"name" => "task-5", "command" => "touch /tmp/file1"},
        %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
        %{"name" => "task-3", "command" => "echo 'Hello World!' > /tmp/file1", "requires" => ["task-5"]},
        %{"name" => "task-4", "command" => "rm /tmp/file1", "requires" => ["task-2", "task-3"]}
      ])
  }
  |> Jason.encode!()

  @etalon_example ["task-5", "task-3", "task-2", "task-4"]

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

  test "POST /jobs returns sorted tasks in JSON (revisited)" do
    conn =
      conn(
        :post,
        "/jobs",
        Jason.encode!(%{
          "tasks" => [
            %{"name" => "task-5", "command" => "touch /tmp/file1"},
            %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
            %{
              "name" => "task-3",
              "command" => "echo 'Hello World!' > /tmp/file1",
              "requires" => ["task-5"]
            },
            %{
              "name" => "task-4",
              "command" => "rm /tmp/file1",
              "requires" => ["task-2", "task-3"]
            }
          ]
        })
      )
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["tasks"] |> Enum.map(& &1["name"]) == ["task-5", "task-3", "task-2", "task-4"]
  end

  test "POST /jobs returns sorted tasks in JSON (infinite loop)" do
    conn =
      conn(
        :post,
        "/jobs",
        Jason.encode!(%{
          "tasks" => [
            %{"name" => "task-5", "command" => "touch /tmp/file1"},
            %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
            %{
              "name" => "task-3",
              "command" => "echo 'Hello World!' > /tmp/file1",
              "requires" => ["task-5", "task-2"]
            },
            %{
              "name" => "task-4",
              "command" => "rm /tmp/file1",
              "requires" => ["task-2", "task-3"]
            }
          ]
        })
      )
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["tasks"] |> List.first() |> Map.get("command") == "Bad arguments (infinite loop)"
  end

  test "POST /jobs returns sorted tasks in JSON (depend on non-existent task)" do
    conn =
      conn(
        :post,
        "/jobs",
        Jason.encode!(%{
          "tasks" => [
            %{"name" => "task-5", "command" => "touch /tmp/file1"},
            %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-11"]},
            %{
              "name" => "task-3",
              "command" => "echo 'Hello World!' > /tmp/file1",
              "requires" => ["task-5", "task-2"]
            },
            %{
              "name" => "task-4",
              "command" => "rm /tmp/file1",
              "requires" => ["task-2", "task-3"]
            }
          ]
        })
      )
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["tasks"] |> Enum.map(& &1["name"]) == ["task-5", "task-2", "task-3", "task-4"]
  end

  test "POST /jobs returns sorted tasks in JSON (separete task)" do
    conn =
      conn(
        :post,
        "/jobs",
        Jason.encode!(%{
          "tasks" => [
            %{"name" => "task-11", "command" => "touch /tmp/file1"},
            %{"name" => "task-5", "command" => "touch /tmp/file1"},
            %{"name" => "task-2", "command" => "cat /tmp/file1", "requires" => ["task-3"]},
            %{
              "name" => "task-3",
              "command" => "echo 'Hello World!' > /tmp/file1",
              "requires" => ["task-5"]
            },
            %{
              "name" => "task-4",
              "command" => "rm /tmp/file1",
              "requires" => ["task-2", "task-3"]
            }
          ]
        })
      )
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["tasks"] |> Enum.map(& &1["name"]) == ["task-5", "task-11", "task-3", "task-2", "task-4"]
  end
end
