# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :parking_tweets,
  # url set by URL envvar
  # api_key set by API_KEY envvar
  start?: true,
  parking_lots: %{
    "park-alfcl-garage" => "Alewife",
    "park-brntn-garage" => "Braintree",
    "park-woodl-garage" => "Woodland",
    "park-NEC-2173-garage" => "Route 128",
    "park-ER-0168-garage" => "Salem",
    "park-qamnl-garage" => "Quincy Adams",
    "park-wondl-garage" => "Wonderland"
  }

config :logger, level: :info

if Mix.env() == :test do
  config :parking_tweets, start?: false
end
