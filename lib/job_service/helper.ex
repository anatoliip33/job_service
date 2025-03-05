defmodule JobService.Helper do
  @moduledoc """
  A module to process job tasks
  """

  @doc """
  Sorts tasks based on requires.
  """
  def sort_tasks(tasks) do
    tasks
    |> Enum.sort_by(fn task ->
      case task["requires"] do
        requires when is_list(requires) and requires !== [] ->
          requires
          |> Enum.sort(:desc)

        _ ->
          task
      end
    end)
    |> Enum.map(&(&1 |> Map.drop(["requires"])))
  end
end
