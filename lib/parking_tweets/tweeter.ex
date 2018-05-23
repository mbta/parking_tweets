defmodule ParkingTweets.Tweeter do
  @moduledoc """
  GenStage Consumer responsible for sending tweets based on parking updates.
  """
  use GenStage
  alias ParkingTweets.{Garage, Tweet}

  defstruct [garages: %{}, last_tweet: nil]

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

    sorted_garages = garages |> Map.values() |> Enum.sort_by(&Garage.utilization_percent/1, &>=/2)

    tweet = Tweet.from_garages(sorted_garages)
    if tweet != state.last_tweet do
      Tweet.send_tweet(tweet)
    end
    state = %{state | garages: garages, last_tweet: tweet}
    {:noreply, [], state}
  end

  def update_garages(_, "reset", updates) do
    for update <- updates, into: %{} do
      garage = Garage.from_json_api(update)
      {garage.id, garage}
    end
  end

  def update_garages(garages, "update", update) do
    garage = Garage.from_json_api(update)
    Map.put(garages, garage.id, garage)
  end
end
