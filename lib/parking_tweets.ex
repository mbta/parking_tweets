defmodule ParkingTweets do
  @moduledoc false

  @doc "Generates the URL to fetch based on the parking lots we care about."
  def url do
    base_url = Application.fetch_env!(:parking_tweets, :url)
    api_key = Application.fetch_env!(:parking_tweets, :api_key)
    facility_ids = Application.fetch_env!(:parking_tweets, :facility_ids)

    base_query =
      "include=facility.stop&fields[live-facility]=updated_at,properties&fields[facilty]=&fields[stop]=name"

    facility_ids_binary = Enum.join(facility_ids, ",")
    query = "?#{base_query}&api_key=#{api_key}&filter[id]=#{facility_ids_binary}"

    base_url
    |> URI.parse()
    |> URI.merge("live-facilities/")
    |> URI.merge(query)
    |> URI.to_string()
  end
end
