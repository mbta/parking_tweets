defmodule ParkingTweets.Garage do
  @moduledoc """
  Struct to represent information about a parking garage
  """
  defstruct ~w(id name capacity utilization status updated_at)a

  def utilization_text(garage)
  def utilization_text(%__MODULE__{name: name, status: status}) when is_binary(status) do
    [name, " is ", status]
  end
  def utilization_text(%__MODULE__{} = garage) do
    [garage.name, " ", Integer.to_string(utilization_percent(garage)), "% full"]
  end

  def utilization_percent(%__MODULE__{} = garage) do
    div(garage.utilization * 100, garage.capacity)
  end

  @doc "Convert a JSON-API map to a Garage"
  def from_json_api(map) do
    id = map["id"]

    {properties, updated_at} =
      Enum.reduce(
        map["attributes"]["properties"],
        {%{}, "9999-99-99T99:99:99Z"},
        fn attribute, {properties, updated_at} ->
          properties = Map.put(properties, attribute["name"], attribute["value"])
          updated_at = min(updated_at, attribute["updated_at"])
          {properties, updated_at}
        end
      )

    %__MODULE__{
      id: id,
      name: name_from_id(id),
      capacity: properties["capacity"],
      utilization: properties["utilization"],
      status: properties["status"],
      updated_at: DateTime.from_iso8601(updated_at) |> elem(1)
    }
  end

  for {id, name} <- Application.get_env(:parking_tweets, :parking_lots) do
    def name_from_id(unquote(id)), do: unquote(name)
  end
end
