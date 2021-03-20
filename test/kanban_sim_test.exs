defmodule KanbanSimTest do
  use ExUnit.Case
  doctest KanbanSim

  test "greets the world" do
    assert KanbanSim.hello() == :world
  end
end
