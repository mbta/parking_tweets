defmodule ParkingTweets.UpdatedGarages do
  @moduledoc """
  GenStage Consumer responsible for sending tweets about updated garages.
  """
  use GenStage
  alias ParkingTweets.{Garage, GarageMap, Tweet}
  require Logger

  defstruct current: GarageMap.new(),
            previous: GarageMap.new(),
            last_tweet_at: nil,
            frequency: Application.get_env(:parking_tweets, :tweet_frequency)

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
    garages = GarageMap.update_multiple(state.current, events)
    %{state | current: garages}
  end

  def maybe_send_tweet(state, time) do
    if should_tweet?(state, time) do
      send_tweet(state, time)
    else
      state
    end
  end

  def send_tweet(state, time) do
    {:ok, local_time} =
      FastLocalDatetime.unix_to_datetime(System.system_time(:seconds), "America/New_York")

    tweet =
      state.current
      |> GarageMap.difference(state.previous)
      |> Enum.sort_by(& &1.name)
      |> Tweet.from_garages(local_time)

    Logger.info(fn ->
      "Sending Tweet: #{tweet}"
    end)

    Tweet.send_tweet(tweet)

    %{state | last_tweet_at: time, previous: state.current}
  end

  def should_tweet?(state, time) do
    differences = GarageMap.difference(state.current, state.previous)

    cond do
      Enum.empty?(differences) ->
        false

      time - state.last_tweet_at > state.frequency ->
        true

      true ->
        Enum.any?(differences, &Garage.status?/1)
    end
  end

  defp now do
    System.monotonic_time(:seconds)
  end
end
