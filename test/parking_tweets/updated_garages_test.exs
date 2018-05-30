defmodule ParkingTweets.UpdatedGaragesTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.UpdatedGarages
  alias ServerSentEventStage.Event
  alias ParkingTweets.{GarageMap, Garage, Tweet}

  setup do
    {:consumer, state, []} = init([])
    {:ok, %{state: state}}
  end

  describe "start_link/1" do
    test "can set a name" do
      assert {:ok, pid} = start_link(name: :test_updated_garage)
      assert pid == Process.whereis(:test_updated_garage)
    end
  end

  describe "handle_events/3" do
    test "does not crash", %{state: state} do
      assert {:noreply, [], state} == handle_events([], :from, state)
    end
  end

  describe "update_garages/2" do
    test "updates the current garage state", %{state: state} do
      events = [
        %Event{
          event: "update",
          data:
            Jason.encode!(%{
              id: "park-alfcl-garage",
              attributes: %{
                properties: [
                  %{name: "utilization", value: 1},
                  %{name: "capacity", value: 2}
                ]
              }
            })
        }
      ]

      new_state = update_garages(state, events)
      refute new_state.current == state.current
      assert new_state.previous == state.previous
    end
  end

  describe "maybe_send_tweet/2" do
    test "sends a tweet if should_tweet?/2 is true", %{state: state} do
      current =
        Enum.reduce(
          [%Garage{name: "Garage", status: "FULL", utilization: 1, capacity: 1}],
          state.current,
          &GarageMap.put(&2, &1)
        )

      state = %{state | current: current}
      _ = maybe_send_tweet(state, 100)
      assert_receive {:tweet, _}
    end
  end

  describe "send_tweet/2" do
    test "sends the tweet with higher-utilization garages first", %{state: state} do
      current =
        Enum.reduce(
          [
            low = %Garage{id: "low", name: "Low", utilization: 100, capacity: 200},
            high = %Garage{id: "high", name: "High", utilization: 100, capacity: 100}
          ],
          state.current,
          fn garage, map -> GarageMap.put(map, garage) end
        )

      state = %{state | current: current}
      new_state = send_tweet(state, 100)
      assert new_state.previous == state.current
      assert new_state.last_tweet_at == 100
      assert_receive {:tweet, text}
      assert text == IO.iodata_to_binary(Tweet.from_garages([high, low]))
    end

    test "after receiving an update, sends a tweet with the updated garage", %{state: state} do
      json_api = [
        %{"id" => "place-alfcl", "type" => "stop", "attributes" => %{"name" => "Alewife"}},
        %{
          "id" => "park-alfcl-garage",
          "type" => "facility",
          "relationships" => %{"stop" => %{"data" => %{"id" => "place-alfcl"}}},
          "attributes" => %{"properties" => []}
        },
        %{"id" => "park-alfcl-garage", "attributes" => %{"properties" => []}}
      ]

      update = %{
        "id" => "park-alfcl-garage",
        "attributes" => %{
          "properties" => [
            %{"name" => "utilization", "value" => 1},
            %{"name" => "capacity", "value" => 1}
          ]
        }
      }

      state = update_garages(state, [%Event{event: "reset", data: Jason.encode!(json_api)}])
      state = send_tweet(state, 100)
      assert_receive {:tweet, _}
      state = update_garages(state, [%Event{event: "update", data: Jason.encode!(update)}])
      _state = send_tweet(state, 200)
      assert_receive {:tweet, _}
    end
  end

  describe "should_tweet?/2" do
    test "does not send tweet if there are no updates", %{state: state} do
      future_time = state.last_tweet_at + state.frequency + 1
      refute should_tweet?(state, future_time)
    end

    test "does not send tweet if it's too soon", %{state: state} do
      current = Enum.reduce([%Garage{}], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      refute should_tweet?(state, state.last_tweet_at)
    end

    test "does send tweet if there are tweets to send", %{state: state} do
      future_time = state.last_tweet_at + state.frequency + 1
      current = Enum.reduce([%Garage{}], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      assert should_tweet?(state, future_time)
    end

    test "does send tweet if one of the queued garages has a status", %{state: state} do
      current = Enum.reduce([%Garage{status: "FULL"}], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      assert should_tweet?(state, state.last_tweet_at)
    end
  end
end
