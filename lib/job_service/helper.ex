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
    required_task_names =
      tasks
      |> Enum.map(& &1["requires"])
      |> List.flatten()
      |> Enum.frequencies()

    {start_tasks, rest_tasks} =
      tasks
      |> Enum.split_with(& is_nil(&1["requires"]) || length(&1["requires"]) == 0)

    start_tasks =
      start_tasks
      |> Enum.sort_by(fn task -> required_task_names[task["name"]] end, :desc)

    rest_tasks =
      rest_tasks
      |> Enum.map(fn task ->
        %{
          task | "requires" =>
            task["requires"]
            |> Enum.reject(fn task ->
              start_tasks
              |> Enum.find(& &1["name"] == task)
            end)
        }
      end)

    {rest_tasks, start_tasks} =
      if length(start_tasks) == 0 do
        {[], nil}
      else
        {rest_tasks, start_tasks}
      end

    sort_tasks(rest_tasks, [start_tasks | sorted_tasks] |> List.flatten())
  end
end
