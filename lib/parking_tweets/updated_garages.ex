defmodule ParkingTweets.UpdatedGarages do
  @moduledoc """
  GenStage Consumer responsible for sending tweets about updated garages.
  """
  use GenStage
  alias ParkingTweets.{Garage, GarageMap, Tweet}
  require Logger

  defstruct garages: GarageMap.new(), queued: [], last_tweet_at: nil, frequency: 15 * 60

  def start_link(opts) do
    start_link_opts = Keyword.take(opts, [:name])
    opts = Keyword.drop(opts, [:name])
    GenStage.start_link(__MODULE__, opts, start_link_opts)
  end

  def init(opts) do
    {:consumer, %__MODULE__{last_tweet_at: now()}, opts}
  end

  def handle_events(events, _from, state) do
    state =
      state
      |> update_garages(events)
      |> maybe_send_tweet(now())

    {:noreply, [], state}
  end

  def update_garages(state, events) do
    {garages, updates} = GarageMap.update_multiple(state.garages, events)
    all_updates = Enum.uniq_by(updates ++ state.queued, & &1.id)
    %{state | garages: garages, queued: all_updates}
  end

  def maybe_send_tweet(state, time) do
    if should_tweet?(state, time) do
      send_tweet(state, time)
    else
      state
    end
  end

  def send_tweet(state, time) do
    sorted_updates = Enum.sort_by(state.queued, &Garage.utilization_percent/1, &>=/2)
    tweet = Tweet.from_garages(sorted_updates)

    Logger.info(fn ->
      "Sending Tweet: #{tweet}"
    end)

    Tweet.send_tweet(tweet)

    %{state | last_tweet_at: time, queued: []}
  end

  def should_tweet?(state, time) do
    cond do
      state.queued == [] ->
        false

      time - state.last_tweet_at > state.frequency ->
        true

      Enum.any?(state.queued, &Garage.status?/1) ->
        true

      true ->
        false
    end
  end

  defp now do
    System.monotonic_time(:seconds)
  end
end