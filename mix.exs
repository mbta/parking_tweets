defmodule ParkingTweets.MixProject do
  use Mix.Project

  def project do
    [
      app: :parking_tweets,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 0.13"},
      {:server_sent_event_stage, "~> 0.1"},
      {:jason, "~> 1.0"},
      {:extwitter, "~> 0.9"},
      {:fast_local_datetime, "~> 0.1"},
      {:crontab, "~> 1.1"},
      {:credo, "~> 0.9", only: [:dev, :test]},
      {:excoveralls, "~> 0.8", only: [:dev, :test]},
      {:distillery, "~> 1.5", only: [:dev, :prod]}
    ]
  end
end
