defmodule ParkingTweets.IdMapSet do
  @moduledoc """
  Similar interface to `MapSet`, but items are unique only by an ID.
  """
  defstruct [:id_fun, :map]

  @opaque t :: %__MODULE__{}

  @doc """
  Returns a new IdMapSet.

      iex> new(& &1)
      #ParkingTweets.IdMapSet<[]>

      iex> new(&elem(&1, 0), [a: 1, b: 2, a: 3])
      #ParkingTweets.IdMapSet<[a: 3, b: 2]>

  IdMapSet also implements the Enumerable protocol:

      iex> set = new(& &1, [1, 2, 3])
      iex> Enum.count(set)
      3
      iex> 3 in set
      true
      iex> Enum.map(set, & &1 + 1)
      [2, 3, 4]

  """
  def new(id_fun, enum \\ []) when is_function(id_fun, 1) do
    map =
      for item <- enum, into: %{} do
        {id_fun.(item), item}
      end

    %__MODULE__{id_fun: id_fun, map: map}
  end

  @doc """
  Returns the number of items in the IdMapSet.

      iex> size(new(& &1))
      0

      iex> size(new(& &1, [1, 2, 3]))
      3
  """
  def size(%__MODULE__{map: map}) do
    map_size(map)
  end

  @doc """
  Returns the items in the IdMapSet as a list.

      iex> set = new(&rem(&1, 2), [1, 2, 3])
      iex> to_list(set)
      [2, 3]
  """
  def to_list(%__MODULE__{} = id_map_set) do
    Map.values(id_map_set.map)
  end

  @doc """
  Insert or update an item in the IdMapSet.

     iex> set = new(& &1)
     iex> 1 in set
     false
     iex> new_set = put(set, 1)
     #ParkingTweets.IdMapSet<[1]>
     iex> 1 in new_set
     true
  """
  def put(%__MODULE__{} = id_map_set, item) do
    %{id_map_set | map: Map.put(id_map_set.map, id_map_set.id_fun.(item), item)}
  end

  @doc """
  Get an item from the IdMapSet by its ID.

      iex> set = new(&elem(&1, 0), [a: 1])
      iex> get(set, :a)
      {:a, 1}
      iex> get(set, :b)
      nil
  """
  def get(%__MODULE__{} = id_map_set, id) do
    Map.get(id_map_set.map, id)
  end

  @doc """
  Returns the items from `id_map_set_1` that are not in `id_map_set_2` with the same values.

      iex> set_1 = new(&elem(&1, 0), [a: 1, b: 2, c: 3])
      iex> set_2 = new(&elem(&1, 0), [a: 1, b: 4])
      iex> difference_by(set_1, set_2, &elem(&1, 1) - 2)
      #ParkingTweets.IdMapSet<[b: 2, c: 3]>
      iex> difference_by(set_1, set_2, &rem(elem(&1, 1), 2))
      #ParkingTweets.IdMapSet<[c: 3]>
  """
  def difference_by(%__MODULE__{} = id_map_set_1, %__MODULE__{} = id_map_set_2, compare_fn)
      when is_function(compare_fn, 1) do
    new(id_map_set_1.id_fun)
    new_set = new(id_map_set_1.id_fun)

    :maps.fold(
      fn id, item, set ->
        old_item = Map.get(id_map_set_2.map, id)

        if is_nil(old_item) or compare_fn.(old_item) != compare_fn.(item) do
          put(set, item)
        else
          set
        end
      end,
      new_set,
      id_map_set_1.map
    )
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(id_map_set, opts) do
      concat(["#ParkingTweets.IdMapSet<", to_doc(@for.to_list(id_map_set), opts), ">"])
    end
  end

  defimpl Enumerable do
    def count(id_map_set) do
      {:ok, @for.size(id_map_set)}
    end

    def member?(id_map_set, element) do
      key = id_map_set.id_fun.(element)
      {:ok, Map.fetch(id_map_set.map, key) == {:ok, element}}
    end

    def reduce(id_map_set, acc, fun) do
      Enumerable.List.reduce(@for.to_list(id_map_set), acc, fun)
    end

    def slice(_id_map_set) do
      {:error, __MODULE__}
    end
  end
end
