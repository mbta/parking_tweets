defmodule ParkingTweets.Tweet do
  @moduledoc """
  Generates/sends tweets based on the parking statuses.
  """
  alias ParkingTweets.Garage

  def from_garages(garages) do
    garage_statuses = for garage <- garages do
      Garage.utilization_text(garage)
    end
    ["#MBTA #Parking Update: ", Enum.intersperse(garage_statuses, ", ")]
  end

  def send_tweet(tweet) do
    IO.puts([tweet, " (", Integer.to_string(IO.iodata_length(tweet)), ")"])
  end
end
