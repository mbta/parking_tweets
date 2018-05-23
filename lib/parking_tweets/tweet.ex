defmodule ParkingTweets.Tweet do
  @moduledoc """
  Generates/sends tweets based on the parking statuses.
  """
  alias ParkingTweets.Garage

  def from_garages(garages) do
    garage_statuses =
      for garage <- garages do
        Garage.utilization_text(garage)
      end

    ["#MBTA #Parking Update: ", Enum.intersperse(garage_statuses, ", "), "."]
  end

  def equal?(equal, equal) do
    true
  end

  def equal?(first, second) do
    IO.iodata_to_binary(first) == IO.iodata_to_binary(second)
  end

  def send_tweet(tweet) do
    status = IO.iodata_to_binary(tweet)
    ExTwitter.update(status).text
  end

  def last_tweet() do
    screen_name = ExTwitter.verify_credentials().screen_name
    [full_tweet | _] = ExTwitter.user_timeline(user: screen_name, count: 1)
    full_tweet.text
  end
end
