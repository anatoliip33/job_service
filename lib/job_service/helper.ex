defmodule JobService.Helper do
  @moduledoc """
  A module to process job tasks
  """

  @doc """
  Sorts tasks based on requires.
  """
  def sort_tasks(tasks, sorted_tasks \\ [])

  def sort_tasks([], [nil | _]), do: [%{"command" => "Bad arguments (infinite loop)"}]
  def sort_tasks([], sorted_tasks), do: sorted_tasks |> Enum.reverse() |> Enum.map(& &1 |> Map.drop(["requires"]))

  def sort_tasks(tasks, sorted_tasks) do
    {start_tasks, rest_tasks} =
      tasks
      |> Enum.split_with(& is_nil(&1["requires"]) || length(&1["requires"]) == 0)

    required_task_names =
      tasks
      |> Enum.map(& &1["requires"])
      |> List.flatten()
      |> Enum.frequencies()

    start_task =
      start_tasks
      |> Enum.sort_by(fn task -> required_task_names[task["name"]] end, :desc)
      |> List.first()

    rest_tasks =
      rest_tasks
      |> Enum.map(fn task ->
        %{
          task | "requires" => task["requires"] |> List.delete(start_task["name"])}
      end)

    rest_tasks = start_task && rest_tasks || []

    sort_tasks(rest_tasks, [start_task | sorted_tasks])
  end
end
