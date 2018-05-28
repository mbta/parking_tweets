defmodule ParkingTweets.ApplicationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.Application

  describe "children_to_start/1" do
    test "empty list when start? is false" do
      assert children_to_start(false) == []
    end

    @tag :capture_log
    test "non-empty list of children when start? is true" do
      children = children_to_start(true)
      assert [_ | _] = children

      for child <- children do
        assert Supervisor.child_spec(child, [])
      end
    end
  end
end
