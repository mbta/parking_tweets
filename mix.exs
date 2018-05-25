defmodule ParkingTweets.MixProject do
  use Mix.Project

  def project do
    [
      app: :parking_tweets,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
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
      {:server_sent_event_stage, "~> 0.1"},
      {:jason, "~> 1.0"},
      {:extwitter, "~> 0.9"},
      {:oauther, "~> 1.1"},
      {:excoveralls, "~> 0.8"}
    ]
  end
end
