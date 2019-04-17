defmodule ParkingTweets.UpdatedGaragesTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.UpdatedGarages
  alias ParkingTweets.{Garage, GarageMap, SampleEvents}
  alias ServerSentEventStage.Event

  @now DateTime.utc_now()
  @now_iso8601 DateTime.to_iso8601(@now)

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
        # initial event to set up the name
        %Event{
          event: "reset",
          data:
            Jason.encode!([
              %{"type" => "stop", "id" => "Alewife", "attributes" => %{"name" => "Alewife"}},
              %{
                "type" => "facility",
                "id" => "park-alfcl-garage",
                "relationships" => %{"stop" => %{"data" => %{"id" => "Alewife"}}}
              }
            ])
        },
        %Event{
          event: "update",
          data:
            Jason.encode!(%{
              id: "park-alfcl-garage",
              attributes: %{
                updated_at: @now_iso8601,
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
          [Garage.new(name: "Garage", status: "FULL", utilization: 1, capacity: 1)],
          state.current,
          &GarageMap.put(&2, &1)
        )

      state = %{state | current: current}
      _ = maybe_send_tweet(state, @now)
      assert_receive {:tweet, _}
    end

    test "uses the scheduled time for the tweet, rather than the current time", %{state: state} do
      current =
        Enum.reduce(
          [Garage.new(name: "Garage", status: "FULL", utilization: 1, capacity: 1)],
          state.current,
          &GarageMap.put(&2, &1)
        )

      last_tweet_at = %{@now | hour: 13, minute: 2}
      now = %{@now | hour: 13, minute: 31}
      state = %{state | current: current, last_tweet_at: last_tweet_at}
      new_state = maybe_send_tweet(state, now)
      assert_receive {:tweet, tweet}
      assert tweet =~ "1:30 PM"
      assert next_scheduled_time(state) != next_scheduled_time(new_state)
    end
  end

  describe "send_tweet/2" do
    test "sends the tweet with alphabetized names", %{state: state} do
      current =
        Enum.reduce(
          [
            Garage.new(id: "B", name: "B", utilization: 100, capacity: 100),
            Garage.new(id: "A", name: "A", utilization: 50, capacity: 100)
          ],
          state.current,
          fn garage, map -> GarageMap.put(map, garage) end
        )

      state = %{state | current: current}
      new_state = send_tweet(state, @now, @now)
      assert new_state.previous == state.current
      assert new_state.last_tweet_at == @now
      assert_receive {:tweet, text}
      assert text =~ "A: 50 free spaces"
    end

    test "after receiving an update, sends a tweet with all the garages", %{state: state} do
      update = %{
        "id" => "park-alfcl-garage",
        "attributes" => %{
          "updated_at" => @now_iso8601,
          "properties" => [
            %{"name" => "utilization", "value" => 1},
            %{"name" => "capacity", "value" => 1}
          ]
        }
      }

      state = update_garages(state, [SampleEvents.reset()])
      state = send_tweet(state, @now, @now)
      assert_receive {:tweet, _}
      state = update_garages(state, [%Event{event: "update", data: Jason.encode!(update)}])
      _state = send_tweet(state, @now, @now)
      assert_receive {:tweet, text}
      assert text =~ "Alewife"
      assert text =~ "Braintree"
    end

    test "does not send a tweet if all the garages are stale", %{state: state} do
      current =
        GarageMap.put(
          state.current,
          Garage.new(
            id: "A",
            name: "A",
            utilization: 1,
            capacity: 1,
            updated_at: DateTime.from_unix!(0)
          )
        )

      state = %{state | current: current}
      new_state = send_tweet(state, @now, @now)
      refute_receive {:tweet, _}
      assert new_state.previous == state.current
      assert new_state.current == state.current
      assert new_state.last_tweet_at == @now
    end

    test "uses the scheduled time for the contents of the tweet", %{state: state} do
      current =
        GarageMap.put(
          state.current,
          Garage.new(
            id: "A",
            name: "A",
            utilization: 1,
            capacity: 1,
            updated_at: @now
          )
        )

      state = %{state | current: current}

      scheduled_time = %{@now | hour: 13, minute: 30}
      new_state = send_tweet(state, scheduled_time, @now)
      assert_receive {:tweet, tweet}
      assert tweet =~ "1:30 PM"
      assert new_state.last_tweet_at == @now
    end
  end

  describe "should_tweet?/2" do
    test "does not send tweet if there are no updates", %{state: state} do
      future_time = next_scheduled_time(state)
      refute should_tweet?(state, future_time)
    end

    test "does not send tweet if it's too soon", %{state: state} do
      current = Enum.reduce([Garage.new([])], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      refute should_tweet?(state, state.last_tweet_at)
    end

    test "does not send tweet if there are no current garages", %{state: state} do
      previous = GarageMap.put(state.current, Garage.new([]))
      state = %{state | current: GarageMap.new(), previous: previous}
      future_time = next_scheduled_time(state)
      refute should_tweet?(state, future_time)
    end

    test "does send tweet if there are tweets to send", %{state: state} do
      future_time = next_scheduled_time(state)
      more_future_time = DateTime.from_unix!(DateTime.to_unix(future_time) + 1)
      current = Enum.reduce([Garage.new([])], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      assert should_tweet?(state, future_time)
      assert should_tweet?(state, more_future_time)
    end

    test "does send tweet if one of the queued garages has a status", %{state: state} do
      current = Enum.reduce([Garage.new(status: "FULL")], state.current, &GarageMap.put(&2, &1))
      state = %{state | current: current}
      assert should_tweet?(state, state.last_tweet_at)
    end
  end
end
