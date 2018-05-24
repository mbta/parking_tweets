defmodule ParkingTweets.TweetGenerator do
  @moduledoc """
  GenStage Consumer responsible for sending tweets based on parking updates.
  """
  use GenStage
  alias ParkingTweets.{Garage, GarageMap}

  defstruct garages: GarageMap.new(), queued: [], last_tweet_at: nil, frequency: 15 * 60

  def start_link(opts) do
    start_link_opts = Keyword.take(opts, [:name])
    opts = Keyword.drop(opts, [:name])
    GenStage.start_link(__MODULE__, opts, start_link_opts)
  end

  def init(opts) do
    {:producer_consumer, %__MODULE__{last_tweet_at: now()}, opts}
  end

  def handle_events(events, _from, state) do
    {garages, updates} = GarageMap.update_multiple(state.garages, events)
    all_updates = Enum.uniq_by(updates ++ state.queued, & &1.id)

    {state, events} =
      if all_updates != [] and should_tweet?(state, updates) do
        sorted_updates = Enum.sort_by(all_updates, &Garage.utilization_percent/1, &>=/2)
        {%{state | last_tweet_at: now(), queued: []}, [sorted_updates]}
      else
        {%{state | queued: all_updates}, []}
      end

    state = %{state | garages: garages}
    {:noreply, events, state}
  end

  def should_tweet?(state, updates) do
    cond do
      now() - state.last_tweet_at > state.frequency ->
        true

      Enum.any?(updates, & &1.status) ->
        true

      true ->
        false
    end
  end

  defp now do
    System.monotonic_time(:seconds)
  end
end
