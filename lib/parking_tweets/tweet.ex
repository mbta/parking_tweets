defmodule ParkingTweets.Tweet do
  @moduledoc """
  Generates/sends tweets based on the parking statuses.
  """
  alias ParkingTweets.Garage
  require Logger

  @twitter Application.get_env(:parking_tweets, :twitter_mod)

  defstruct statuses: [], long_status?: false

  def from_garages([_ | _] = garages) do
    parsed = Enum.reduce(garages, %__MODULE__{}, &reduce_garage/2)

    case parsed.statuses do
      [{garage, status}] ->
        if Garage.status?(garage) do
          ["#Parking Availability: ", garage.name, " is ", status, "."]
        else
          ["#Parking Availability:: ", garage.name, " has ", status, "."]
        end

      multiple ->
        texts =
          for {garage, status} <- Enum.reverse(multiple) do
            [garage.name, ": ", status]
          end

        ["#Parking Availability\n\n", Enum.intersperse(texts, "\n")]
    end
  end

  defp reduce_garage(garage, state) do
    cond do
      Garage.status?(garage) ->
        %{state | statuses: [{garage, garage.status} | state.statuses]}
      state.long_status? ->
        %{state | statuses: [{garage, short_status(garage)} | state.statuses]}
      true ->
        %{state | statuses: [{garage, long_status(garage)} | state.statuses], long_status?: true}
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

  def send_tweet(tweet) do
    status = IO.iodata_to_binary(tweet)
    @twitter.update(status)
  catch
    ExTwtter.Error, e ->
      Logger.error(fn -> inspect(e) end)
  end
end
