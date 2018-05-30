defmodule ParkingTweets.GarageMap do
  @moduledoc """
  Responsible for maintaing a map of garages and and their current state.
  """
  alias ParkingTweets.{Garage, IdMapSet}

  defstruct garages: IdMapSet.new(&Garage.id/1),
            facility_to_stop_id: %{},
            stop_id_to_stop_name: %{}

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
    data
    |> Jason.decode!()
    |> Enum.reduce(%__MODULE__{}, &put_json(&2, &1))
  end

  def update(%__MODULE__{} = map, %{event: "update", data: data}) do
    data |> Jason.decode!() |> (&put_json(map, &1)).()
  end

  defp put_json(map, %{"type" => "facility"} = json) do
    %{
      "id" => facility_id,
      "relationships" => %{
        "stop" => %{
          "data" => %{
            "id" => stop_id
          }
        }
      }
    } = json

    put_in(map.facility_to_stop_id[facility_id], stop_id)
  end

  defp put_json(map, %{"type" => "stop"} = json) do
    %{
      "id" => stop_id,
      "attributes" => %{
        "name" => stop_name
      }
    } = json

    put_in(map.stop_id_to_stop_name[stop_id], stop_name)
  end

  defp put_json(map, json) do
    garage = Garage.from_json_api(json)
    stop_id = Map.get(map.facility_to_stop_id, garage.id)
    stop_name = Map.get(map.stop_id_to_stop_name, stop_id)
    garage = Garage.put_name(garage, stop_name)
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
