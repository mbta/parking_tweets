defmodule ParkingTweets.UpdatedGarages do
  @moduledoc """
  GenStage Consumer responsible for sending tweets about updated garages.
  """
  use GenStage
  alias ParkingTweets.{Garage, GarageMap, Tweet}
  alias Crontab.Scheduler, as: CrontabScheduler
  alias Crontab.CronExpression.Parser, as: CrontabParser
  require Logger

  alternates = Application.get_env(:parking_tweets, :alternates)
  initial_map = GarageMap.new(alternates: alternates)

  defstruct current: initial_map,
            previous: initial_map,
            last_tweet_at: nil,
            crontab: CrontabParser.parse!(Application.get_env(:parking_tweets, :tweet_cron))

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

  def maybe_send_tweet(state, %DateTime{} = time) do
    if should_tweet?(state, time) do
      send_tweet(state, time)
    else
      state
    end
  end

  def send_tweet(state, %DateTime{} = time) do
    tweet =
      state.current
      |> GarageMap.with_alternates()
      |> Enum.reject(&Garage.stale?(&1, time))
      |> Enum.sort_by(& &1.name)
      |> Tweet.from_garages(time)

    Logger.info(fn ->
      "Sending Tweet: #{tweet}"
    end)

    Tweet.send_tweet(tweet)

    new_state = %{state | last_tweet_at: time, previous: state.current}

    Logger.info(fn ->
      "Next tweet scheduled: #{inspect(next_scheduled_time(new_state))}"
    end)

    new_state
  end

  def should_tweet?(state, time) do
    differences = GarageMap.difference(state.current, state.previous)

    cond do
      Enum.empty?(differences) ->
        false

      DateTime.compare(time, next_scheduled_time(state)) != :lt ->
        true

      true ->
        Enum.any?(differences, &Garage.status?/1)
    end
  end

  defp now do
    {:ok, local_now} =
      FastLocalDatetime.unix_to_datetime(System.system_time(:seconds), "America/New_York")

    local_now
  end

  def next_scheduled_time(state) do
    # CrontabScheduler only works with NaiveDateTime (since crontabs don't
    # have timezone information). For simplicity, we keep the next scheduled
    # time in the same time zone as the current time, even if that might
    # technically be the wrong timezone.
    {:ok, naive} =
      CrontabScheduler.get_next_run_date(state.crontab, DateTime.to_naive(state.last_tweet_at))

    %{
      state.last_tweet_at
      | year: naive.year,
        month: naive.month,
        day: naive.day,
        hour: naive.hour,
        minute: naive.minute,
        second: naive.second,
        microsecond: naive.microsecond
    }
  end
end
