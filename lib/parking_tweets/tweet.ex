defmodule ParkingTweets.Tweet do
  @moduledoc """
  Generates/sends tweets based on the parking statuses.
  """
  alias ParkingTweets.Garage
  require Logger

  def from_garages([first | rest]) do
    long_status = long_status(first)

    short_statuses =
      for garage <- rest do
        short_status(garage)
      end

    garage_statuses =
      case short_statuses do
        [] ->
          long_status

        _ ->
          [long_status, "; " | Enum.intersperse(short_statuses, ", ")]
      end

    ["#MBTA #Parking Update: ", garage_statuses, "."]
  end

  defp long_status(garage) do
    if Garage.status?(garage) do
      [garage.name, " is ", garage.status]
    else
      [
        garage.name,
        " has ",
        Integer.to_string(Garage.free_spaces(garage)),
        " free spaces (",
        Integer.to_string(Garage.utilization_percent(garage)),
        "% full)"
      ]
    end
  end

  defp short_status(garage) do
    if Garage.status?(garage) do
      [garage.name, ": ", garage.status]
    else
      [
        garage.name,
        ": ",
        Integer.to_string(Garage.free_spaces(garage)),
        " (",
        Integer.to_string(Garage.utilization_percent(garage)),
        "%)"
      ]
    end
  end

  def equal?(equal, equal) do
    true
  end

  def equal?(first, second) do
    IO.iodata_to_binary(first) == IO.iodata_to_binary(second)
  end

  def send_tweet(tweet) do
    status = IO.iodata_to_binary(tweet)
    ExTwitter.update(status).text
  catch
    ExTwtter.Error, e ->
      Logger.error(fn -> inspect(e) end)
  end

  def last_tweet() do
    screen_name = ExTwitter.verify_credentials().screen_name
    [full_tweet | _] = ExTwitter.user_timeline(user: screen_name, count: 1)
    full_tweet.text
  end
end
