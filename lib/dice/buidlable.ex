defmodule Dice.Buildable do
  @moduledoc """
  Macro to DRY up our Contexts.

  VASTLY cuts down on common operations when working with Structs in a common way
  """

  # Default functions available
  @context_functions ~w(build __before_build__ __after_build__)a

  defmacro __using__(opts \\ []) do
    opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))

    quote do
      # The singular name of a model, i.e. `MyApp.Users.User`
      @model Keyword.get(unquote(opts), :model)

      @valid_attrs Keyword.get(unquote(opts), :valid_attrs)

      @type this_type :: @model.t()

      unquote(generate_methods(opts))
    end
  end

  defp generate_methods(opts) do
    only = Keyword.get(opts, :only, @context_functions)
    except = Keyword.get(opts, :except, [])

    for method <- @context_functions do
      for bang <- [:safe], method in only && method not in except do
        gen(method, bang, opts)
      end
    end
  end

  # build methods
  defp gen(:build, :safe, _opts) do
    quote location: :keep do
      # Called by the `build_actual` function below. Sanitizing everything has already been done.
      @doc ~s"""
      Build out a struct for a @model
      """
      @spec build(Keyword.t()) :: {:ok, this_type} | {:error, String.t()}
      def build(list) when is_list(list) do
        list
        |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
        |> Keyword.take(@valid_attrs)
        |> Enum.into(%{})
        |> Dice.MapUtils.atomize_keys()
        |> __before_build__()
        |> build(:valid)
        |> __after_build__()
      end

      @spec build(map) :: {:ok, this_type} | {:error, String.t()}
      def build(params) when is_map(params) do
        params
        |> build_actual()
      end

      @spec build_actual(map) :: {:ok, this_type} | {:error, String.t()}
      defp build_actual(params) do
        params
        |> Dice.MapUtils.to_atom_keyword_list()
        |> Enum.reject(fn {_, v} -> is_nil(v) || v == [] end)
        |> build()
      end

      @spec build(map(), :valid) ::
              {:ok, this_type} | {:error, String.t()}
      defp build(valid_map, :valid) when is_map(valid_map) do
        {:ok, struct!(__MODULE__, valid_map)}
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end
  end

  defp gen(:__before_build__, :safe, _opts) do
    quote location: :keep do
      defp __before_build__(%{} = map_with_atom_keys) do
        map_with_atom_keys
      end
    end
  end

  defp gen(:__after_build__, :safe, _opts) do
    quote location: :keep do
      defp __after_build__(%@model{} = buildable) do
        buildable
      end

      defp __after_build__({:ok, %@model{}} = result) do
        result
      end
    end
  end
end
