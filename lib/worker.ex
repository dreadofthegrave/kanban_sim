defmodule KanbanSim.Worker do
  def create_worker() do
    card = nil
    [Faker.Person.name(), 3..Enum.random(3..8), card]
  end

  def create_workers(quantity) do
    workers = for _n <- 1..quantity, do: KanbanSim.Worker.create_worker()
    workers
  end

  def work(worker) do
    [name, _, card] = worker

    [card, worker] =
      if card != nil do
        if Enum.at(card, 0) != "Backlog" && Enum.at(card, 0) != "Testing" do
          task_name = Enum.at(card, 1)

            eff = Enum.random(Enum.at(worker, 1))
            card = List.replace_at(card, 3, Enum.at(card, 3) + eff)
            IO.puts("#{name} worked on task \"#{task_name}\" and progressed it #{eff} pts.")

            [card, worker] =
              if Enum.at(card, 3) >= Enum.at(card, 2) do
                IO.puts("#{name} finished working on task \"#{task_name}\"")
                [KanbanSim.KanbanCard.next_stage(card), List.replace_at(worker, 2, nil)]
              else
                [card, worker]
              end

            [card, worker]
        else
          if Enum.at(card, 0) == "Backlog" do
            task_name = Enum.at(card, 1)

            if :rand.uniform(2) > 1 do
              IO.puts(
                "#{name} googled the task \"#{task_name}\" and decided the team is capable of completing it."
              )

              [KanbanSim.KanbanCard.next_stage(card), List.replace_at(worker, 2, nil)]
            else
              IO.puts(
                "#{name} googled the task \"#{task_name}\" and decided to pretend it doesn't exist."
              )

              [card, List.replace_at(worker, 2, nil)]
            end
          else
            task_name = Enum.at(card, 1)
            if :rand.uniform(100) > 55 do
              IO.puts(
                "Task \"#{task_name}\" passed tests successfully!")
                [KanbanSim.KanbanCard.next_stage(card), List.replace_at(worker, 2, nil)]
            else
              IO.puts("Task \"#{task_name}\" didn't pass the tests and must go back to development phase again.")
              [KanbanSim.KanbanCard.back_to_development(card), List.replace_at(worker, 2, nil)]
            end
          end
        end
      else
        [card, worker] = [nil, worker]
          IO.puts("#{name} had no task assigned thus didn't work")
          [card, worker]
      end

    {card, worker}
  end

  def find_idle(workers) do
    workers_available =
      Enum.reject(workers, fn worker ->
        Enum.at(worker, 2) != nil
      end)

    Enum.at(workers_available, 0)
  end

  def workers_refresh(worker, cards_updated) do
    worker_card = Enum.at(worker, 2)

    updated =
      if worker_card != nil do
        Enum.find(cards_updated, worker_card, fn updated_card ->
          updated_card != nil && Enum.at(updated_card, 1) == Enum.at(worker_card, 1)
        end)
      else
        nil
      end

    List.replace_at(worker, 2, updated)
  end
end
