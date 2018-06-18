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
    garage = struct!(__MODULE__, opts)
    %{garage | updated_at: garage.updated_at || DateTime.utc_now()}
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

  @doc """
  Has the garage not been updated recently?

  Uses the :stale_garage_timeout configuration to determine how many seconds a garage is allowed to not be updated.

      iex> zero = DateTime.from_naive!(~N[1970-01-01T00:00:00], "Etc/UTC")
      iex> half_hour = DateTime.from_naive!(~N[1970-01-01T00:30:00], "Etc/UTC")
      iex> two_hour = DateTime.from_naive!(~N[1970-01-01T02:00:00], "Etc/UTC")
      iex> garage = new(updated_at: zero)
      iex> stale?(garage, half_hour)
      false
      iex> stale?(garage, two_hour)
      true
  """
  def stale?(%__MODULE__{updated_at: updated_at}, %DateTime{} = current_time) do
    difference = DateTime.to_unix(current_time) - DateTime.to_unix(updated_at)
    difference > Application.get_env(:parking_tweets, :stale_garage_timeout)
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
