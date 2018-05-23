defmodule ParkingTweets.Tweeter do
  @moduledoc """
  GenStage Consumer responsible for sending tweets based on parking updates.
  """
  use GenStage
  alias ParkingTweets.{Garage, Tweet}

  defstruct garages: %{}

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, %__MODULE__{}, opts}
  end

  def handle_events(events, _from, state) do
    garages =
      Enum.reduce(events, state.garages, fn event, garages ->
        update_garages(garages, event.event, Jason.decode!(event.data))
      end)

    state = %{state | garages: garages}
    {:noreply, [], state}
  end

  def update_garages(old_garages, "reset", updates) do
    new_garages =
      for update <- updates, into: %{} do
        garage = Garage.from_json_api(update)
        {garage.id, garage}
      end

    unless old_garages == %{} do
      sorted_garages =
        old_garages |> Map.values() |> Enum.sort_by(&Garage.utilization_percent/1, &>=/2)

      tweet = Tweet.from_garages(sorted_garages)
      IO.puts(tweet)
      Tweet.send_tweet(tweet)
    end

    new_garages
  end

  def update_garages(garages, "update", update) do
    new_garage = Garage.from_json_api(update)
    old_garage = Map.fetch!(garages, new_garage.id)

    new_tweet = Tweet.from_garages([new_garage])
    old_tweet = Tweet.from_garages([old_garage])

    unless Tweet.equal?(old_tweet, new_tweet) do
      IO.puts(new_tweet)
      Tweet.send_tweet(new_tweet)
    end

    Map.put(garages, new_garage.id, new_garage)
  end
end
