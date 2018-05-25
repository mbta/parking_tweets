defmodule ParkingTweets.GarageMap do
  @moduledoc """
  Responsible for maintaing a map of garages and and their current state.
  """
  alias ParkingTweets.Garage

  defstruct garages: %{}

  def new do
    %__MODULE__{}
  end

  def empty?(%__MODULE__{garages: garages}) when map_size(garages) > 0, do: false
  def empty?(%__MODULE__{}), do: true

  def update_multiple(%__MODULE__{} = map, events) do
    {map, updates} =
      Enum.reduce(events, {map, []}, fn event, {map, updates} ->
        {map, new_updates} = update(map, event)
        {map, new_updates ++ updates}
      end)

    {map, Enum.uniq_by(updates, & &1.id)}
  end

  def update(%__MODULE__{} = map, %{event: "reset", data: data}) do
    new_garages =
      for update <- Jason.decode!(data), into: %{} do
        garage = Garage.from_json_api(update)
        {garage.id, garage}
      end

    updates =
      if empty?(map) do
        []
      else
        Map.values(new_garages)
      end

    {%__MODULE__{garages: new_garages}, updates}
  end

  def update(%__MODULE__{} = map, %{event: "update", data: data}) do
    garage = data |> Jason.decode!() |> Garage.from_json_api()
    old_garage = Map.get(map.garages, garage.id)
    new_map = put_in(map.garages[garage.id], garage)

    if not is_nil(old_garage) and
         Garage.utilization_percent(old_garage) == Garage.utilization_percent(garage) do
      {new_map, []}
    else
      {new_map, [garage]}
    end
  end
end
