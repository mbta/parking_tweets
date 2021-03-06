defmodule ParkingTweets.FakeTwitter do
  @moduledoc """
  Module to pretend to send a tweet.
  """

  def configure(_) do
    :ok
  end

  def verify_credentials do
    %ExTwitter.Model.User{}
  end

  def update(status) do
    send(self(), {:tweet, status})
  end
end
