defmodule ParkingTweets.TweetTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ParkingTweets.Tweet
  alias ParkingTweets.Garage

  @time ~N[1970-01-01T00:00:00]

  describe "from_garages/1" do
    test "uses status when available" do
      assert_tweet_like([garage(status: "FULL")], ": Garage is FULL as of 12:00 AM.")
    end

    test "uses free spots and percentage" do
      assert_tweet_like(
        [garage(utilization: 901)],
        ": Garage has 99 free spaces (90% full) as of 12:00 AM."
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

      tweet = IO.iodata_to_binary(from_garages(garages, @time))

      assert tweet ==
               "#Parking Availability @ 12:00 AM\n\nGarage: 1000 free spaces (0% full)\nGarage: 1000 (0%)\nGarage: 1000 (0%)"
    end

    test "a full garage with a non-full alternate includes that information" do
      non_full = garage(name: "half", utilization: 50, capacity: 100)
      full = garage(name: "full", status: "FULL", alternates: [non_full])

      assert_tweet_like([full], "full is FULL as of")
      assert_tweet_like([full], "(try half)")
      assert_tweet_like([full, non_full], "full: FULL (try half)")
    end

    test "a full garage with a full alternate does not include that information" do
      full1 = garage(name: "one", status: "FULL")
      full2 = garage(name: "two", status: "FULL", alternates: [full1])
      garages = [full2]
      tweet = IO.iodata_to_binary(from_garages(garages, @time))
      refute tweet =~ "try"
    end

    test "formats the current time into the update" do
      garages = [
        garage(),
        garage()
      ]

      for {hour, minute, expected} <- [
            {11, 05, "11:05 AM"},
            {12, 00, "12:00 PM"},
            {13, 25, "1:25 PM"}
          ] do
        time = %{@time | hour: hour, minute: minute}
        assert_tweet_like(time, garages, expected)
      end
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

    Garage.new(opts)
  end

  def assert_tweet_like(time \\ @time, garages, text) do
    tweet = from_garages(garages, time)
    assert IO.iodata_to_binary(tweet) =~ text
  end
end
