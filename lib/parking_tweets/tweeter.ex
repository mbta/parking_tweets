defmodule ParkingTweets.Tweeter do
  @moduledoc """
  GenStage Consumer responsible for sending tweets based on parking updates.
  """
  use GenStage
  alias ParkingTweets.Tweet
  require Logger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :ignored, opts}
  end

  def handle_events(events, _from, state) do
    updates = List.last(events)
    tweet = Tweet.from_garages(updates)

    Logger.info(fn ->
      "Sending Tweet: #{tweet}"
    end)

    Tweet.send_tweet(tweet)

    {:noreply, [], state}
  end
end
