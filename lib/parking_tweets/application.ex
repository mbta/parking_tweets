defmodule ParkingTweets.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    override_environment!()
    # List all child processes to be supervised
    children = [
      {ServerSentEvent.Producer, name: ServerSentEvent.Producer, url: {ParkingTweets, :url, []}},
      {ParkingTweets.Tweeter, subscribe_to: [ServerSentEvent.Producer]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: ParkingTweets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp override_environment! do
    for {key, envvar} <- [url: "URL", api_key: "API_KEY"] do
      case System.get_env(envvar) do
        binary when is_binary(binary) ->
          Application.put_env(:parking_tweets, key, binary)

        nil ->
          Logger.error(fn -> "missing environment variable #{envvar}" end)
      end
    end

    :ok
  end
end
