# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :parking_tweets,
  # url set by URL envvar
  url: "https://api-v3.mbta.com/",
  # api_key set by API_KEY envvar
  start?: true,
  twitter_mod: ExTwitter,
  facility_ids: [
    "park-alfcl-garage",
    "park-ER-0183-garage",
    "park-brntn-garage",
    "park-woodl-garage",
    "park-NEC-2173-garage",
    "park-ER-0168-garage",
    "park-qamnl-garage",
    "park-wondl-garage"
  ],
  # 30 minutes
  tweet_frequency: 30 * 60

case Mix.env() do
  :dev ->
    config :parking_tweets,
      twitter_mod: ParkingTweets.FakeTwitter,
      tweet_frequency: 5 * 60

  :test ->
    config :logger, level: :warn

    config :parking_tweets,
      start?: false,
      url: "https://test.example/path/",
      api_key: "test_api_key",
      twitter_mod: ParkingTweets.FakeTwitter

  _ ->
    :ok
end
