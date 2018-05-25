defmodule ParkingTweets.TestTwitter do
  @moduledoc """
  Test module to pretend to send a tweet.
  """

  def update(status) do
    send(self(), {:tweet, status})
  end
end
