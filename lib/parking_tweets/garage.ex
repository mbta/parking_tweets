defmodule ParkingTweets.Garage do
  @moduledoc """
  Struct to represent information about a parking garage
  """
  defstruct ~w(id name capacity utilization status)a

  def status?(%__MODULE__{status: status}) do
    is_binary(status)
  end

  def free_spaces(%__MODULE__{} = garage) do
    garage.capacity - garage.utilization
  end

  def utilization_percent(%__MODULE__{} = garage) do
    div(garage.utilization * 100, garage.capacity)
  end

  @doc "Convert a JSON-API map to a Garage"
  def from_json_api(map) do
    id = map["id"]

    properties =
      Enum.reduce(
        map["attributes"]["properties"],
        %{},
        fn attribute, properties ->
          Map.put(properties, attribute["name"], attribute["value"])
        end
      )

    %__MODULE__{
      id: id,
      name: name_from_id(id),
      capacity: Map.get(properties, "capacity", -1),
      utilization: Map.get(properties, "utilization", 0),
      status: Map.get(properties, "status", nil)
    }
  end

  for {id, name} <- Application.get_env(:parking_tweets, :parking_lots) do
    def name_from_id(unquote(id)), do: unquote(name)
  end
end
