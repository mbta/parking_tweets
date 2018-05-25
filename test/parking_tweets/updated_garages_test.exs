defmodule ParkingTweets.UpdatedGaragesTest do
  use ExUnit.Case, async: true
  import ParkingTweets.UpdatedGarages
  alias ServerSentEventStage.Event
  alias ParkingTweets.{Garage, Tweet}

  setup do
    {:consumer, state, []} = init([])
    {:ok, %{state: state}}
  end

  describe "update_garages/2" do
    test "combines updates from events with the queued events", %{state: state} do
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

      state = %{state | queued: [%Garage{id: "park-alfcl-garage", capacity: 1}]}
      new_state = update_garages(state, events)
      assert [new_garage] = new_state.queued
      assert %Garage{name: "Alewife", utilization: 1, capacity: 2} = new_garage
    end
  end

  describe "send_tweet/2" do
    test "sends the tweet with higher-utilization garages first", %{state: state} do
      queued = [
        low = %Garage{name: "Low", utilization: 100, capacity: 200},
        high = %Garage{name: "High", utilization: 100, capacity: 100}
      ]

      state = %{state | queued: queued}
      new_state = send_tweet(state, 100)
      assert new_state.queued == []
      assert new_state.last_tweet_at == 100
      assert_receive {:tweet, text}
      assert text == IO.iodata_to_binary(Tweet.from_garages([high, low]))
    end
  end

  describe "should_tweet?/2" do
    test "does not send tweet if there are no queued updates", %{state: state} do
      future_time = state.last_tweet_at + state.frequency + 1
      refute should_tweet?(state, future_time)
    end

    test "does not send tweet if it's too soon", %{state: state} do
      queued = [%Garage{}]
      state = %{state | queued: queued}
      refute should_tweet?(state, state.last_tweet_at)
    end

    test "does send tweet if there are tweets to send", %{state: state} do
      future_time = state.last_tweet_at + state.frequency + 1
      queued = [%Garage{}]
      state = %{state | queued: queued}
      assert should_tweet?(state, future_time)
    end

    test "does send tweet if one of the queued garages has a status", %{state: state} do
      queued = [%Garage{status: "FULL"}]
      state = %{state | queued: queued}
      assert should_tweet?(state, state.last_tweet_at)
    end
  end
end
