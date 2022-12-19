# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

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
  alternates: [
    ["park-brntn-garage", "park-qamnl-garage"],
    ["park-ER-0183-garage", "park-ER-0168-garage"]
  ],
  capacity_overrides: %{},
  # every 30 minutes
  tweet_cron: "*/30 * * * *",
  # 1 hour
  stale_garage_timeout: 60 * 60

case Mix.env() do
  :dev ->
    config :parking_tweets,
      twitter_mod: ParkingTweets.FakeTwitter,
      tweet_cron: "*/5 * * *"

  :test ->
    config :logger, level: :warn

    config :parking_tweets,
      start?: false,
      url: "https://test.example/path/",
      api_key: "test_api_key",
      twitter_mod: ParkingTweets.FakeTwitter,
      capacity_overrides: %{
        "fake-garage" => 5
      }

  _ ->
    :ok
end
