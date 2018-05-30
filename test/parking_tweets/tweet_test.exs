defmodule ParkingTweets.TweetTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.Tweet
  alias ParkingTweets.Garage

  describe "from_garages/1" do
    test "uses status when available" do
      assert_tweet_like([garage(status: "FULL")], ": Garage is FULL.")
    end

    test "uses free spots and percentage" do
      assert_tweet_like(
        [garage(utilization: 901)],
        ": Garage has 99 free spaces (90% full)."
      )
    end

    test "with multiple garages with status, simplifies the latter ones" do
      garages = [
        garage(status: "FULL"),
        garage(name: "Other", status: "VERY FULL")
      ]

      assert_tweet_like(garages, "Garage: FULL")
      assert_tweet_like(garages, "Other: VERY FULL")
    end

    test "with a garage with status, the next garage also includes the help text" do
      garages = [
        garage(status: "FULL"),
        garage(status: "FULL"),
        garage()
      ]

      assert_tweet_like(garages, "Garage: 1000 free spaces (0% full)")
    end

    test "with multiple garages, simplifies the free space text" do
      garages = [
        garage(),
        garage(name: "Other", utilization: 500)
      ]

      assert_tweet_like(garages, "Other: 500 (50%)")
    end

    test "combines the text from multiple garages" do
      garages = [
        garage(),
        garage(),
        garage()
      ]

      tweet = IO.iodata_to_binary(from_garages(garages))

      assert tweet ==
               "#Parking Availability\n\nGarage: 1000 free spaces (0% full)\nGarage: 1000 (0%)\nGarage: 1000 (0%)"
    end
  end

  def garage(opts \\ []) do
    opts =
      Keyword.merge(
        [
          name: "Garage",
          utilization: 0,
          capacity: 1000
        ],
        opts
      )

    struct!(Garage, opts)
  end

  def assert_tweet_like(garages, text) do
    tweet = from_garages(garages)
    assert IO.iodata_to_binary(tweet) =~ text
  end
end
