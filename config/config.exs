# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :parking_tweets,
  # url set by URL envvar
  url: "https://api-v3.mbta.com/",
  # api_key set by API_KEY envvar
  start?: true,
  twitter_mod: ExTwitter,
  parking_lots: %{
    "park-alfcl-garage" => "Alewife",
    "park-ER-0183-garage" => "Beverly",
    "park-brntn-garage" => "Braintree",
    "park-woodl-garage" => "Woodland",
    "park-NEC-2173-garage" => "Route 128",
    "park-ER-0168-garage" => "Salem",
    "park-qamnl-garage" => "Quincy Adams",
    "park-wondl-garage" => "Wonderland"
  }

case Mix.env() do
  :dev ->
    config :parking_tweets, twitter_mod: ParkingTweets.FakeTwitter

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
