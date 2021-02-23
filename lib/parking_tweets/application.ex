defmodule ParkingTweets.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @twitter Application.compile_env(:parking_tweets, :twitter_mod)

  def start(_type, _args) do
    # List all child processes to be supervised
    children = children_to_start(Application.get_env(:parking_tweets, :start?))
    opts = [strategy: :one_for_all, name: ParkingTweets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def children_to_start(true) do
    override_environment!()
    override_twitter_environment!()

    [
      {ServerSentEventStage, name: :event_producer, url: {ParkingTweets, :url, []}},
      {ParkingTweets.UpdatedGarages, subscribe_to: [:event_producer]}
    ]
  end

  def children_to_start(false) do
    []
  end

  def override_environment! do
    for {key, envvar} <- [url: "URL", api_key: "API_KEY", tweet_cron: "TWEET_CRON"] do
      case System.get_env(envvar) || Application.get_env(:parking_tweets, key) do
        binary when is_binary(binary) ->
          Application.put_env(:parking_tweets, key, binary)

        nil ->
          Logger.error(fn -> "missing environment variable #{envvar}" end)
      end
    end

    :ok
  end

  def override_twitter_environment! do
    configuration =
      for {key, envvar} <- [
            consumer_key: "CONSUMER_KEY",
            consumer_secret: "CONSUMER_SECRET",
            access_token: "ACCESS_TOKEN",
            access_token_secret: "ACCESS_TOKEN_SECRET"
          ] do
        case System.get_env(envvar) do
          binary when is_binary(binary) ->
            {key, binary}

          nil ->
            Logger.error(fn -> "missing environment variable #{envvar}" end)
            {key, nil}
        end
      end

    @twitter.configure(configuration)
    %ExTwitter.Model.User{} = @twitter.verify_credentials()
    :ok
  end
end
