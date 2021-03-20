defmodule KanbanSim.CLI do
  def main(_args) do
    IO.puts("Input \"start\" to begin")
    receive_command()
  end

  defp receive_command do
    IO.gets("\n> ")
    |> String.trim
    |> String.downcase
    |> execute_command
  end

  defp execute_command("start") do
    KanbanSim.Supervisor.start_link([])
    IO.puts("\n\nInput \"next\" to go to the next step")
    receive_command()
  end

  defp execute_command("next") do
    KanbanSim.KanbanBoard.next()
    receive_command()
  end

  defp execute_command(_unknown) do
    IO.puts("\nInvalid command.")
    receive_command()
  end
end
