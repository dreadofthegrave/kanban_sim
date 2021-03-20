defmodule KanbanSim.KanbanCard do
  def create_cards(quantity) do
    tasks = [
      "Resurrect dead memes",
      "Enter cheat codes",
      "Scale bananas",
      "Free Hong Kong",
      "Load simulation",
      "Generate buttons procedurally",
      "Finish the sente",
      "Initiate launch sequence",
      "Decrypt Engrams",
      "Extract more minerals",
      "Recombobulate discombobulators",
      "Start the engines",
      "Dehumanize animals",
      "Find the power button",
      "Initialize socialisation",
      "Generate terrain",
      "Travel to China",
      "Achieve Nirvana",
      "Spawn processes"
    ]

    cards =
      for n <- 1..quantity do
        task = Enum.at(tasks, n)
        [Enum.random(["Backlog", "To Do"]), task, Enum.random(4..10), 0, false]
      end

    cards
  end

  def cards_refresh(card, cards_updated) do
    updated =
      Enum.find(cards_updated, card, fn updated_card ->
        updated_card != nil && Enum.at(updated_card, 1) == Enum.at(card, 1)
      end)

    if Enum.at(updated, 3) == 0 do
      List.replace_at(updated, 4, false)
    else
      updated
    end

  end

  def map_row(card) do
    [stage, assignment, _, _, _] = card
    row = ["", "", "", "", ""]

    idx =
      case stage do
        "Backlog" ->
          0

        "To Do" ->
          1

        "In Progress" ->
          2

        "Testing" ->
          3

        "Done" ->
          4
      end

    row = List.replace_at(row, idx, assignment)
    row
  end

  def next_stage(card) do
    [stage_curr, _, _, _progress, _] = card

    {stage, progress} =
      case stage_curr do
        "Backlog" ->
          {"To Do", 0}

        "To Do" ->
          {"In Progress", 0}

        "In Progress" ->
          {"Testing", 0}

        "Testing" ->
          {"Done", -1}
      end

    temp = List.replace_at(card, 0, stage)
    card = List.replace_at(temp, 3, progress)
    card = List.replace_at(card, 2, Enum.random(4..10))
    card
  end

  def back_to_development(card) do
    temp = List.replace_at(card, 0, "In Progress")
    card = List.replace_at(temp, 3, 0)
    card = List.replace_at(card, 2, Enum.random(4..10))
    card
  end
end
