defmodule KanbanSim.KanbanBoard do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: Kboard)
  end

  def init(_opts) do
    cards = KanbanSim.KanbanCard.create_cards(10)
    workers = KanbanSim.Worker.create_workers(5)
    rows = set_rows()
    begin()
    print_board()
    kboard = {cards, workers, rows}
    {:ok, kboard}
  end

  def handle_cast(:print_board, kboard) do
    {_cards, _workers, rows} = kboard

    IO.puts("\n\n")
    TableRex.quick_render!(rows, [
      "Backlog",
      "To Do",
      "In Progress",
      "Testing",
      "Done"
    ])
    |> IO.puts()

    {:noreply, kboard}
  end

  def handle_cast(:set_rows, kboard) do
    {cards, workers, _rows} = kboard

    rows =
      cards
      |> Task.async_stream(&KanbanSim.KanbanCard.map_row/1)
      |> Enum.map(fn {:ok, result} -> result end)

    kboard = {cards, workers, rows}
    {:noreply, kboard}
  end

  def handle_cast(:tick, kboard) do
    {cards, workers, rows} = kboard

    updated =
      workers
      |> Task.async_stream(&KanbanSim.Worker.work/1)
      |> Enum.map(fn {:ok, result} -> result end)

    cards_updated =
      updated
      |> Task.async_stream(fn {card, _worker} -> card end)
      |> Enum.map(fn {:ok, result} -> result end)

    cards =
      if not Enum.empty?(cards_updated) do
        cards
        |> Task.async_stream(KanbanSim.KanbanCard, :cards_refresh, [cards_updated])
        |> Enum.map(fn {:ok, result} -> result end)
      else
        cards
      end

    workers_updated =
      updated
      |> Task.async_stream(fn {_card, worker} -> worker end)
      |> Enum.map(fn {:ok, result} -> result end)

    workers_updated =
      workers_updated
      |> Task.async_stream(KanbanSim.Worker, :workers_refresh, [cards_updated])
      |> Enum.map(fn {:ok, result} -> result end)

    kboard = {cards, workers_updated, rows}
    {:noreply, kboard}
  end

  def handle_cast(:assign, kboard) do
    {cards, workers, rows} = kboard
    idle = KanbanSim.Worker.find_idle(workers)
    idle_idx = Enum.find_index(workers, fn worker -> worker == idle end)
    name = Enum.at(idle, 0)

    cards_available =
      Enum.reject(cards, fn card ->
        Enum.at(card, 4) == true or Enum.at(card, 3) == -1
      end)

    available_shuffled = Enum.shuffle(cards_available)

    [workers_updated, cards_updated, msg] =
      if not Enum.empty?(available_shuffled) do
        task_name = Enum.at(Enum.at(available_shuffled, 0), 1)

        [workers_updated, cards_updated, msg] =
          if idle_idx != nil do
            card_updated = List.replace_at(Enum.at(available_shuffled, 0), 4, true)
            idle_updated = List.replace_at(idle, 2, card_updated)

            updated_card_idx =
              Enum.find_index(cards, fn card ->
                Enum.at(card, 1) == Enum.at(card_updated, 1) && Enum.at(card, 4) == false
              end)

            [
              List.replace_at(workers, idle_idx, idle_updated),
              List.replace_at(cards, updated_card_idx, card_updated),
              "Task \"#{task_name}\" is assigned to #{name}"
            ]
          else
            [workers, cards, "No available workers."]
          end

        [workers_updated, cards_updated, msg]
      else
        [workers, cards, "No available tasks - Worker stays idle"]
      end

    IO.puts(msg)
    kboard = {cards_updated, workers_updated, rows}
    {:noreply, kboard}
  end

  def handle_cast(:begin, kboard) do
    {_cards, workers, _rows} = kboard
    Enum.each(workers, fn _x -> assign() end)
    {:noreply, kboard}
  end

  def handle_cast(:next, kboard) do
    {_cards, workers, _rows} = kboard

    for worker <- workers do
      if Enum.at(worker, 2) == nil do
        assign()
      end
    end

    tick()
    set_rows()
    print_board()
    is_done()
    {:noreply, kboard}
  end

  def handle_cast(:is_done, kboard) do
    {cards, _, _} = kboard

    list =
      for card <- cards do
        if Enum.at(card, 0) != "Done" do
          1
        else
          2
        end
      end

    if Enum.find(list, fn num -> num == 1 end) == nil do
      IO.puts("All tasks are done!")
    end

    {:noreply, kboard}
  end

  def print_board() do
    GenServer.cast(Kboard, :print_board)
  end

  def set_rows() do
    GenServer.cast(Kboard, :set_rows)
  end

  def tick() do
    GenServer.cast(Kboard, :tick)
  end

  def assign() do
    GenServer.cast(Kboard, :assign)
  end

  def work() do
    GenServer.cast(Kboard, :work)
  end

  def begin() do
    GenServer.cast(Kboard, :begin)
  end

  def next() do
    GenServer.cast(Kboard, :next)
  end

  def is_done() do
    GenServer.cast(Kboard, :is_done)
  end
end
