defmodule ParkingTweets.GarageMap do
  @moduledoc """
  Responsible for maintaing a map of garages and and their current state.
  """
  alias ParkingTweets.{Garage, IdMapSet}

  defstruct garages: IdMapSet.new(&Garage.id/1)

  def new do
    %__MODULE__{}
  end

  def empty?(%__MODULE__{garages: garages}) do
    IdMapSet.size(garages) == 0
  end

  def update_multiple(%__MODULE__{} = map, events) do
    Enum.reduce(events, map, fn event, map -> update(map, event) end)
  end

  def update(%__MODULE__{}, %{event: "reset", data: data}) do
    new_garages =
      for update <- Jason.decode!(data), into: IdMapSet.new(&Garage.id/1) do
        Garage.from_json_api(update)
      end

    %__MODULE__{garages: new_garages}
  end

  def update(%__MODULE__{} = map, %{event: "update", data: data}) do
    garage = data |> Jason.decode!() |> Garage.from_json_api()
    put(map, garage)
  end

  @doc "Insert a garage directly"
  def put(%__MODULE__{} = map, %Garage{} = garage) do
    %{map | garages: IdMapSet.put(map.garages, garage)}
  end

  def difference(%__MODULE__{} = garage_map_1, %__MODULE__{} = garage_map_2) do
    IdMapSet.difference_by(
      garage_map_1.garages,
      garage_map_2.garages,
      &Garage.utilization_percent/1
    )
  end
end
