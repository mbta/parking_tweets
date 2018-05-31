defmodule ParkingTweets.GarageMap do
  @moduledoc """
  Responsible for maintaing a map of garages and and their current state.
  """
  alias ParkingTweets.{Garage, IdMapSet}

  defstruct garages: IdMapSet.new(&Garage.id/1),
            alternates: %{},
            facility_to_stop_id: %{},
            stop_id_to_stop_name: %{}

  def new do
    %__MODULE__{}
  end

  def new(opts) do
    alternates = build_alternate_map(Keyword.get(opts, :alternates))
    %__MODULE__{alternates: alternates}
  end

  def empty?(%__MODULE__{garages: garages}) do
    IdMapSet.size(garages) == 0
  end

  def update_multiple(%__MODULE__{} = map, events) do
    Enum.reduce(events, map, fn event, map -> update(map, event) end)
  end

  def update(%__MODULE__{} = map, %{event: "reset", data: data}) do
    reset_map = %__MODULE__{alternates: map.alternates}
    data
    |> Jason.decode!()
    |> Enum.reduce(reset_map, &put_json(&2, &1))
  end

  def update(%__MODULE__{} = map, %{event: "update", data: data}) do
    data |> Jason.decode!() |> (&put_json(map, &1)).()
  end

  defp build_alternate_map(nil) do
    %{}
  end
  defp build_alternate_map(alternates) do
    # `alternates` is a list of lists of garage IDs. In a given list of IDs,
    # any of the garages can be substituted with each other.
    Enum.reduce(alternates, %{}, fn ids, acc ->
      set = MapSet.new(ids)
      Enum.reduce(ids, acc, fn id, acc ->
        without_current = MapSet.delete(set, id)
        Map.update(acc, id, without_current, &MapSet.union(&1, without_current))
      end)
    end)
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
    for garage <- IdMapSet.difference_by(
      garage_map_1.garages,
      garage_map_2.garages,
      &Garage.utilization_percent/1
        ) do
        case calculate_alternates(garage_map_1, garage) do
          [] ->
            garage
          alternates ->
            Garage.put_alternates(garage, alternates)
        end
    end
  end

  defp calculate_alternates(map, garage) do
    for alternate_id <- Map.get(map.alternates, garage.id, []),
      %Garage{} = alternate_garage <- [IdMapSet.get(map.garages, alternate_id)] do
        alternate_garage
    end
  end
end
