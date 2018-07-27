defmodule ParkingTweets.GarageTest do
  use ExUnit.Case, async: true
  import ParkingTweets.Garage

  doctest ParkingTweets.Garage

  describe "new/1" do
    test "overrides the capacity for some garages" do
      garage = new(id: "fake-garage", capacity: 10, utilization: 1)
      assert garage.capacity == 5
      refute status?(garage)
    end

    test "if the utilization is at/over the overriden capacity, sets status to FULL" do
      for utilization <- [5, 6] do
        garage = new(id: "fake-garage", capacity: 10, utilization: utilization)
        assert garage.status == "FULL"
      end
    end
  end
end
