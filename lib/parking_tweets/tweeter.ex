defmodule ParkingTweets.Tweeter do
  @moduledoc """
  GenStage Consumer responsible for sending tweets based on parking updates.
  """
  use GenStage
  alias ParkingTweets.Tweet

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :ignored, opts}
  end

  def handle_events(events, _from, state) do
    updates = List.last(events)
    tweet = Tweet.from_garages(updates)
    IO.puts(tweet)
    Tweet.send_tweet(tweet)

    {:noreply, [], state}
  end
end
