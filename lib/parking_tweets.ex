defmodule ParkingTweets do
  @moduledoc """
  Documentation for ParkingTweets.
  """

  @doc "Generates the URL to fetch based on the parking lots we care about."
  def url do
    base_url = Application.fetch_env!(:parking_tweets, :url)
    api_key = Application.fetch_env!(:parking_tweets, :api_key)
    parking_lot_ids = Map.keys(Application.fetch_env!(:parking_tweets, :parking_lots))

    "#{base_url}?api_key=#{api_key}&filter[id]=#{Enum.join(parking_lot_ids, ",")}"
  end
end
