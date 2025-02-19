defmodule Semantic.TypeValidation do

alias Generators.ConstPool

  def validate!(class, %{fun_decl: %{right: body, params: params, return: return}}) do
    params = Enum.map(params, &(String.downcase(&1) |> String.to_atom()))
    ensure_type!(class, return, params, body)
  end

  def validate!(class, node) when is_map(node) do
    validate!(class, node)
  end

  def validate!(class, node) when is_list(node) do
    Enum.map(node, &validate!(class, &1))
  end

  defp ensure_type!(class, type, params_types, %{left: left, right: right, op: op}) do
    op_type = operator_atom(op)

    {left_type, right_type, result_type} =
      cond do
        op_type in [:or, :and, :not, :eq, :ne, :lt, :le, :gt, :ge]
          -> {:bool, :bool, :bool}

        op_type in [:minus, :plus, :mul, :div]
          -> {:int, :int, :int}

        op_type == :cons
          -> {:int, :list, :list}
      end

    type == result_type or raise "Result type of #{op_type} is #{result_type}, but #{type} expected"

    ensure_type!(class, left_type, params_types, left)
    ensure_type!(class, right_type, params_types, right)
  end

  defp ensure_type!(class, type, params_types, %{funid: funid, params: params}) do
    {_, func_desc, _} = ConstPool.find_method(class.constant_pool, funid)
    {func_params, return} = ConstPool.descriptor_to_atoms(func_desc)

    return == type or raise "#{funid} returns #{return}, but #{type} expected"

    length(params) == length(func_params)
      or raise """
      #{length(func_params)} arguments expected when applying #{funid}, but #{length(params)} was given
      """

    params
    |> Enum.zip(func_params)
    |> Enum.map(fn {param, type} -> ensure_type!(class, type, params_types, param) end)
  end

  defp ensure_type!(_class, type, _params_types, %{list: _}) do
    type == :list or raise "Incorrect type! #{type} inspected, but list was given"
  end

  defp ensure_type!(_class, type, _params_types, %{literal: %{type: "int", funid: funid}}) when is_binary(funid) do
    type == :int or raise "Incorrect type! #{type} inspected, but int was given"
  end

  defp operator_atom(%{type: type}) when is_atom(type), do: type

  defp operator_atom(%{type: type}) do
    type
    |> String.downcase()
    |> String.to_atom()
  end

end
