defmodule ParkingTweets.GarageMapTest do
  use ExUnit.Case, async: true
  import ParkingTweets.GarageMap
  alias ServerSentEventStage.Event

  setup do
    map = new()

    json_api = [
      %{"id" => "park-alfcl-garage", "attributes" => %{"properties" => []}},
      %{"id" => "park-brntn-garage", "attributes" => %{"properties" => []}}
    ]

    {new_map, _updates} = update(map, %Event{event: "reset", data: Jason.encode!(json_api)})
    {:ok, %{map: new_map}}
  end

  describe "update/2" do
    test "when receiving a reset event with no previous data, returns nothing as updates" do
      map = new()

      json_api = [
        %{"id" => "park-alfcl-garage", "attributes" => %{"properties" => []}},
        %{"id" => "park-brntn-garage", "attributes" => %{"properties" => []}}
      ]

      {new_map, updates} = update(map, %Event{event: "reset", data: Jason.encode!(json_api)})
      refute new_map == map
      assert updates == []
    end

    test "when receiving a reset event with previous data, returns all the garages as updates", %{
      map: map
    } do
      json_api = [
        %{"id" => "park-alfcl-garage", "attributes" => %{"properties" => []}}
      ]

      {new_map, updates} = update(map, %Event{event: "reset", data: Jason.encode!(json_api)})
      refute new_map == map
      assert [_] = updates
    end

    test "when receiving an update event, returns the garage as an update", %{map: map} do
      json_api = %{
        "id" => "park-alfcl-garage",
        "attributes" => %{
          "properties" => [
            %{name: "utilization", value: 1, updated_at: "1970-01-01T00:00:00Z"},
            %{name: "capacity", value: 2, updated_at: "1970-01-01T00:00:00Z"}
          ]
        }
      }

      {new_map, updates} = update(map, %Event{event: "update", data: Jason.encode!(json_api)})
      refute new_map == map
      assert [_] = updates
    end

    test "when receiving an update event, does not return it as an update if the utilization is the same", %{map: map} do
      json_api = %{
        id: "park-alfcl-garage",
        attributes: %{
          properties: [
            %{name: "utilization", value: 0, updated_at: "1970-01-01T00:00:00Z"},
            %{name: "capacity", value: 2, updated_at: "1970-01-01T00:00:00Z"}
          ]
        }
      }

      {new_map, updates} = update(map, %Event{event: "update", data: Jason.encode!(json_api)})
      refute new_map == map
      assert updates == []
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
                properties: [
                  %{name: "utilization", value: 1, updated_at: "1970-01-01T00:00:00Z"},
                  %{name: "capacity", value: 2, updated_at: "1970-01-01T00:00:00Z"}
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
                properties: [
                  %{name: "utilization", value: 1, updated_at: "1970-01-01T00:00:00Z"},
                  %{name: "capacity", value: 2, updated_at: "1970-01-01T00:00:00Z"}
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
                properties: [
                  %{name: "utilization", value: 1, updated_at: "1970-01-01T00:00:00Z"},
                  %{name: "capacity", value: 2, updated_at: "1970-01-01T00:00:00Z"}
                ]
              }
            })
        }
      ]

      {new_map, updates} = update_multiple(map, updates)
      refute new_map == map
      # alfcl should be de-duplicated
      assert [_, _] = updates
      # uses the last update
      assert Enum.find(updates, &(&1.id == "park-alfcl-garage")).capacity == 2
    end
  end
end
