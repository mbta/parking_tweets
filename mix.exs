defmodule ParkingTweets.MixProject do
  use Mix.Project

  def project do
    [
      app: :parking_tweets,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ParkingTweets.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 0.13"},
      {:httpoison, "~> 1.1"},
      {:jason, "~> 1.0"},
      {:bypass, "~> 0.8", only: :test, required: false}
    ]
  end
end
