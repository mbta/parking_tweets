defmodule ParkingTweets.SampleEvents do
  @moduledoc """
  Sample Events to use be used for testing.
  """
  alias ServerSentEventStage.Event

  @doc """
  Build a `reset` event for the Alewife and Braintree garages.
  """
  def reset do
    json_api =
      for {garage_id, stop_id, name} <- [
            {"park-alfcl-garage", "place-alfcl", "Alewife"},
            {"park-brntn-garage", "place-brntn", "Braintree"}
          ],
          item <- [
            %{"id" => stop_id, "type" => "stop", "attributes" => %{"name" => name}},
            %{
              "id" => garage_id,
              "type" => "facility",
              "relationships" => %{"stop" => %{"data" => %{"id" => stop_id}}},
              "attributes" => %{"properties" => []}
            },
            %{
              "id" => garage_id,
              "type" => "live-facility",
              "attributes" => %{"updated_at" => "1970-01-01T00:00:00Z", "properties" => []}
            }
          ] do
        item
      end

    %Event{
      event: "reset",
      data: Jason.encode!(json_api)
    }
  end
end
