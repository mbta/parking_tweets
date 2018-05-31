defmodule ParkingTweets.Garage do
  @moduledoc """
  Struct to represent information about a parking garage
  """
  defstruct [:id, :name, :status, capacity: -1, utilization: 0]

  def id(%__MODULE__{id: id}), do: id

  def status?(%__MODULE__{status: status}) do
    is_binary(status)
  end

  def free_spaces(%__MODULE__{} = garage) do
    garage.capacity - garage.utilization
  end

  def utilization_percent(%__MODULE__{} = garage) do
    div(garage.utilization * 100, garage.capacity)
  end

  @doc "Create a new garage"
  def new(opts) do
    struct!(__MODULE__, opts)
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

    new(
      id: id,
      capacity: Map.get(properties, "capacity", -1),
      utilization: Map.get(properties, "utilization", 0),
      status: Map.get(properties, "status", nil)
    )
  end

  @doc "Updates the name of a garage"
  def put_name(%__MODULE__{} = garage, name) when is_binary(name) do
    %{garage | name: name}
  end
end
