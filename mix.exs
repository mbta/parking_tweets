defmodule ParkingTweets.MixProject do
  use Mix.Project

  def project do
    [
      app: :parking_tweets,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: LcovEx],
      releases: [
        parking_tweets: [
          applications: [
            parking_tweets: :permanent,
            runtime_tools: :permanent,
            oauther: :permanent,
            extwitter: :permanent
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ParkingTweets.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:server_sent_event_stage, "~> 1.0"},
      {:mint, "~> 1.3"},
      {:castore, "~> 0.1"},
      {:jason, "~> 1.0"},
      {:extwitter, "~> 0.9"},
      {:oauther,
       github: "Glimesh/oauther", ref: "2e3f681b32fbebe8b0e2c6464cf56cdafe8ae558", override: true},
      {:fast_local_datetime, "~> 1.0"},
      {:crontab, "~> 1.1"},
      {:credo, "~> 1.1", only: [:dev, :test]},
      {:lcov_ex, "~> 0.2", only: [:dev, :test]}
    ]
  end
end
