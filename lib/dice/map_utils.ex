defmodule Dice.MapUtils do
  @moduledoc """
  Utilities for working with Maps

  See Also:
  https://gist.github.com/kipcole9/0bd4c6fb6109bfec9955f785087f53fb
  """

  @doc """
  Given a map with string keys, convert it to a keyword list where the keys are atoms.
  """
  @spec to_atom_keyword_list(map) :: [{Keyword.t(), any}]
  def to_atom_keyword_list(map) when is_map(map) do
    Enum.map(map, fn {key, value} ->
      case is_atom(key) do
        true ->
          {key, value}

        _not_an_atom ->
          # We're not going to have 10,000 exisiting atoms
          try do
            {String.to_existing_atom(key), value}
          rescue
            # A new Atom
            ArgumentError ->
              new_key =
                key
                |> Macro.underscore()
                |> String.replace(" ", "")
                |> String.to_atom()

              {new_key, value}
          end
      end
    end)
  end

  @doc """
  Convert map string camelCase keys to underscore_keys

  Given a list, atomize the keys of any map members
  """
  @spec underscore_keys(map | list) :: map | list
  def underscore_keys(nil), do: nil

  def underscore_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {Macro.underscore(k), underscore_keys(v)} end)
    |> Enum.map(fn {k, v} -> {String.replace(k, "-", "_"), v} end)
    |> Enum.into(%{})
  end

  def underscore_keys([head | rest]) do
    [underscore_keys(head) | underscore_keys(rest)]
  end

  # It's ... not a map.
  def underscore_keys(not_a_map) do
    not_a_map
  end

  @doc """
  Convert map string keys to :atom keys

  Given a Map of mixed keys (String/Atom), or a list with Map members, convert all the Keys to Atoms
  """
  @spec atomize_keys(map | list) :: map | list
  def atomize_keys(nil), do: nil

  # Structs don't do enumerable and anyway the keys are already atoms
  def atomize_keys(struct = %{__struct__: _}) do
    struct
  end

  def atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} ->
      case is_atom(k) do
        true -> {k, atomize_keys(v)}
        _ -> {String.to_atom(k), atomize_keys(v)}
      end
    end)
    |> Enum.into(%{})
  end

  # Walk the list and atomize the keys of of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  # It's ... not a map.
  def atomize_keys(not_a_map) do
    not_a_map
  end

  @doc """
  Given a Map of mixed keys (String/Atom), or a list with Map members, convert all the Keys to Strings
  """
  @spec stringify_keys(map | list) :: map | list
  def stringify_keys(nil), do: nil

  def stringify_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and stringify the keys of of any map members
  def stringify_keys([head | rest]) do
    [stringify_keys(head) | stringify_keys(rest)]
  end

  # It's ... not a map.
  def stringify_keys(not_a_map) do
    not_a_map
  end

  @doc """
  Deep merge two maps
  """
  @spec deep_merge(map, map) :: map
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end
end
