defmodule ParkingTweets.Tweet do
  @moduledoc """
  Generates/sends tweets based on the parking statuses.
  """
  alias ParkingTweets.Garage
  require Logger

  @twitter Application.get_env(:parking_tweets, :twitter_mod)

  defstruct statuses: [], long_status?: false

  def from_garages([_ | _] = garages, now) do
    parsed = Enum.reduce(garages, %__MODULE__{}, &reduce_garage/2)
    formatted_time = format_time(now)

    case parsed.statuses do
      [{garage, status}] ->
        if Garage.status?(garage) do
          [
            "#Parking Availability: ",
            garage.name,
            " is ",
            garage.status,
            " as of ",
            formatted_time,
            maybe_alternate_text(garage.alternates),
            "."
          ]
        else
          [
            "#Parking Availability: ",
            garage.name,
            " has ",
            status,
            " as of ",
            formatted_time,
            "."
          ]
        end

      multiple ->
        texts =
          for {garage, status} <- Enum.reverse(multiple) do
            [garage.name, ": ", status]
          end

        ["#Parking Availability @ ", format_time(now), "\n\n", Enum.intersperse(texts, "\n")]
    end
  end

  defp reduce_garage(garage, state) do
    cond do
      Garage.status?(garage) ->
        %{
          state
          | statuses: [
              {garage, [garage.status, maybe_alternate_text(garage.alternates)]} | state.statuses
            ]
        }

      state.long_status? ->
        %{state | statuses: [{garage, short_status(garage)} | state.statuses]}

      true ->
        %{state | statuses: [{garage, long_status(garage)} | state.statuses], long_status?: true}
    end
  end

  defp maybe_alternate_text(alternates) do
    non_full_alternates = Enum.reject(alternates, &Garage.status?/1)

    if non_full_alternates == [] do
      []
    else
      [
        " (try ",
        Enum.intersperse(Enum.map(alternates, & &1.name), ", "),
        ")"
      ]
    end
  end

  defp long_status(garage) do
    [
      Integer.to_string(Garage.free_spaces(garage)),
      " free spaces (",
      Integer.to_string(Garage.utilization_percent(garage)),
      "% full)"
    ]
  end

  defp short_status(garage) do
    [
      Integer.to_string(Garage.free_spaces(garage)),
      " (",
      Integer.to_string(Garage.utilization_percent(garage)),
      "%)"
    ]
  end

  defp format_time(%{hour: hour, minute: minute}) do
    {hour, am_pm} =
      cond do
        hour == 0 ->
          {12, "AM"}

        hour == 12 ->
          {12, "PM"}

        hour < 12 ->
          {hour, "AM"}

        true ->
          {hour - 12, "PM"}
      end

    [
      Integer.to_string(hour),
      ":",
      if(minute < 10, do: "0", else: ""),
      Integer.to_string(minute),
      " ",
      am_pm
    ]
  end

  def send_tweet(tweet) do
    status = IO.iodata_to_binary(tweet)
    @twitter.update(status)
  catch
    ExTwtter.Error, e ->
      Logger.error(fn -> inspect(e) end)
  end
end
