defmodule ParkingTweets.GarageMapTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.GarageMap
  alias ParkingTweets.{Garage, SampleEvents}
  alias ServerSentEventStage.Event

  setup do
    map = new()

    new_map = update(map, SampleEvents.reset())
    {:ok, %{map: new_map}}
  end

  describe "update/2" do
    test "when receiving a reset event with previous data, returns all the garages as updates", %{
      map: map
    } do
      json_api = [
        %{"id" => "place-woodl", "type" => "stop", "attributes" => %{"name" => "Woodland"}},
        %{
          "id" => "park-woodl-garage",
          "type" => "facility",
          "relationships" => %{"stop" => %{"data" => %{"id" => "place-woodl"}}},
          "attributes" => %{"properties" => []}
        },
        %{
          "id" => "park-woodl-garage",
          "attributes" => %{"updated_at" => "1970-01-01T00:00:00Z", "properties" => []}
        }
      ]

      new_map = update(map, %Event{event: "reset", data: Jason.encode!(json_api)})
      refute new_map == map
      assert [garage] = Enum.to_list(difference(new_map, map))
      assert %Garage{name: "Woodland"} = garage
    end

    test "when receiving an update event, returns the garage as an update", %{map: map} do
      json_api = %{
        "id" => "park-alfcl-garage",
        "attributes" => %{
          "updated_at" => "1970-01-01T00:00:00Z",
          "properties" => [
            %{name: "utilization", value: 1},
            %{name: "capacity", value: 2}
          ]
        }
      }

      new_map = update(map, %Event{event: "update", data: Jason.encode!(json_api)})
      refute new_map == map
      assert [garage] = Enum.to_list(difference(new_map, map))
      assert %Garage{name: "Alewife", utilization: 1, capacity: 2} = garage
    end

    test "when receiving an update event, does not return it as an update if the data is the same",
         %{map: map} do
      json_api = %{
        id: "park-alfcl-garage",
        attributes: %{
          updated_at: "1970-01-01T00:00:00Z",
          properties: [
            %{name: "utilization", value: 0},
            %{name: "capacity", value: 2}
          ]
        }
      }

      new_map = update(map, %Event{event: "update", data: Jason.encode!(json_api)})
      refute new_map == map
      assert Enum.empty?(difference(new_map, map))
    end
  end

  describe "update_multiple/2" do
    test "combines updates from multiple events", %{map: map} do
      updates = [
        %Event{
          event: "update",
          data:
            Jason.encode!(%{
              id: "park-alfcl-garage",
              attributes: %{
                updated_at: "1970-01-01T00:00:00Z",
                properties: [
                  %{name: "utilization", value: 1},
                  %{name: "capacity", value: 2}
                ]
              }
            })
        },
        %Event{
          event: "update",
          data:
            Jason.encode!(%{
              id: "park-brntn-garage",
              attributes: %{
                updated_at: "1970-01-01T00:00:00Z",
                properties: [
                  %{name: "utilization", value: 1},
                  %{name: "capacity", value: 2}
                ]
              }
            })
        },
        %Event{
          event: "update",
          data:
            Jason.encode!(%{
              id: "park-alfcl-garage",
              attributes: %{
                updated_at: "1970-01-01T00:00:00Z",
                properties: [
                  %{name: "utilization", value: 1},
                  %{name: "capacity", value: 2}
                ]
              }
            })
        }
      ]

      new_map = update_multiple(map, updates)
      refute new_map == map
      # alfcl should be de-duplicated
      assert [_, _] = updates = Enum.to_list(difference(new_map, map))
      # uses the last update
      assert Enum.find(updates, &(&1.id == "park-alfcl-garage")).capacity == 2
    end
  end

  describe "with_alternates/2" do
    setup do
      alternates = [
        ["a", "b"]
      ]

      map =
        [alternates: alternates]
        |> new()
        |> put(Garage.new(id: "a"))

      {:ok, %{map: map}}
    end

    test "does nothing if there's no matching alternate", %{map: map} do
      [garage] = Enum.to_list(with_alternates(map))
      assert garage.alternates == []
    end

    test "includes alternate garages if present", %{map: map} do
      alternate_garage = Garage.new(id: "b")
      map = put(map, alternate_garage)
      garage = Enum.find(with_alternates(map), &(&1.id == "a"))
      assert [_] = garage.alternates
    end

    test "does not include full alternate garages", %{map: map} do
      alternate_garage = Garage.new(id: "b", status: "FULL", utilization: 1, capacity: 1)
      map = put(map, alternate_garage)
      garage = Enum.find(with_alternates(map), &(&1.id == "a"))
      assert garage.alternates == []
    end

    test "does not include alternate garages that are more than 90% full", %{map: map} do
      alternate_garage = Garage.new(id: "b", utilization: 91, capacity: 100)
      map = put(map, alternate_garage)
      garage = Enum.find(with_alternates(map), &(&1.id == "a"))
      assert garage.alternates == []
    end
  end
end
