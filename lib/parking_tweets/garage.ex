defmodule ParkingTweets.Garage do
  @moduledoc """
  Struct to represent information about a parking garage
  """
  defstruct [:id, :name, :updated_at, :status, capacity: -1, utilization: 0, alternates: []]

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
  def from_json_api(%{"id" => id, "attributes" => attributes}) do
    {:ok, updated_at, _} = DateTime.from_iso8601(Map.fetch!(attributes, "updated_at"))

    properties =
      attributes
      |> Map.fetch!("properties")
      |> Enum.reduce(
        %{},
        fn %{"name" => name, "value" => value}, properties ->
          Map.put(properties, name, value)
        end
      )

    new(
      id: id,
      updated_at: updated_at,
      capacity: Map.get(properties, "capacity", -1),
      utilization: Map.get(properties, "utilization", 0),
      status: Map.get(properties, "status", nil)
    )
  end

  @doc "Updates the name of a garage"
  def put_name(%__MODULE__{} = garage, name) when is_binary(name) do
    %{garage | name: name}
  end

  @doc "Updates the alternate garages"
  def put_alternates(%__MODULE__{} = garage, [%__MODULE__{} | _] = alternates) do
    %{garage | alternates: alternates}
  end
end
