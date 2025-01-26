defmodule Semantic.Transformers do
  @moduledoc"""
  Скопище функций для преобразования дерева
  """

  @doc """
  Связать определение функций с декларациями их типов

  В итоге каждый func_decl преобразуется в
  ```json
  func_decl {
    left: {...},
    right: {...},
    type: {...}
  }
  ```
  """
  def link_funcs_and_types(%{module: module}) do
    %{module: link_funcs_and_types(module)}
  end

  def link_funcs_and_types(%{decls: decls}) do
    types = get_types_decls(decls)
    funcs = get_func_decls(decls)

    # Проверить, нет ли объявлений типов без соответсвующих функций
    # Или функций без объявленного типа
    raise_types_funcs_mismatch!(types, funcs)

    # В каждый func_decl добавить тип
    typed_funcs = zip_types_funcs(types, funcs)
    |> Enum.map(fn {%{type: type}, fun_decl} ->
                Map.update!(fun_decl, :fun_decl, &Map.put(&1, :type, type))
    end)
    |> Enum.map(&deconstruct_type/1)

    # Убрать отдельные определения функций и объявления типов
    remaining_decls = Enum.reject(decls, fn decl ->
      decl in types or decl in funcs
    end)

    %{decls: typed_funcs ++ remaining_decls}
  end

  @doc """
  Добавляет поле `index` ко всем локальным переменным внутри функции
  """
  def index_locals(%{module: module} = node) do
    Map.put(node, :module, index_locals(module))
  end

  def index_locals(%{decls: decls} = node) do
    Map.put(node, :decls, index_locals(decls))
  end

  def index_locals(decls) when is_list(decls) do
    Enum.map(decls, fn decl ->
      if match?(%{fun_decl: _}, decl) do
        index_locals(decl)
      else
        decl
      end
    end)
  end

  def index_locals(%{fun_decl: %{left: %{params: params}, right: right}} = node) do
    params_id = Enum.map(params, & &1.pattern)
    updated_right = map_locals_indexes(right, params_id)
    Map.update!(node, :fun_decl, &Map.put(&1, :right, updated_right))
  end

  def index_locals(node), do: node


  defp map_locals_indexes(%{funid: id}, params) do
    %{funid: Enum.find_index(params, &(&1 == id))}
  end

  defp map_locals_indexes(node, params) when is_map(node) do
    Enum.reduce(node, %{}, fn {k, v}, acc ->
      Map.put(acc, k, map_locals_indexes(v, params))
    end)
  end

  defp map_locals_indexes(node, params) when is_list(node) do
    Enum.map(node, &map_locals_indexes(&1, params))
  end

  defp map_locals_indexes(node, _params) do
    node
  end


  defp get_types_decls(decls) do
    Enum.filter(decls, &match?(%{type: _, vars: _}, &1))
  end

  defp get_func_decls(decls) do
    Enum.filter(decls, &match?(%{fun_decl: _}, &1))
  end

  defp zip_on(first, second, condition) do
    for fst_elem <- first, snd_elem <- second, condition.(fst_elem, snd_elem) do
      {fst_elem, snd_elem}
    end
  end

  defp zip_types_funcs(types, funcs) do
    zip_on(types, funcs, fn
      %{type: _, vars: %{repr: type}},
      %{fun_decl: %{left: %{name: func}}} -> type == func
    end)
  end

  defp raise_types_funcs_mismatch!(types, funcs) do
    types_map = Map.new(types, fn type ->
      %{vars: %{repr: repr}, type: type_value} = type
      {repr, type_value}
    end)

    funcs_map = Map.new(funcs, fn func ->
      %{fun_decl: %{left: %{name: name}}} = func
      {name, func}
    end)

    types_without_funcs = Map.keys(types_map) -- Map.keys(funcs_map)
    funcs_without_types = Map.keys(funcs_map) -- Map.keys(types_map)

    if types_without_funcs != [] do
      raise "Types without corresponding functions: #{Enum.join(types_without_funcs, ", ")}"
    end

    if funcs_without_types != [] do
      raise "Functions without corresponding types: #{Enum.join(funcs_without_types, ", ")}"
    end
  end

  defp deconstruct_type(%{fun_decl: %{type: type}} = node) do
    types = Enum.map(type, &(&1.tycon))
    params = Enum.drop(types, -1)
    return = List.last(types)

    Map.update!(node, :fun_decl, &Map.delete(&1, :type))
    |> Map.update!(:fun_decl, &Map.put_new(&1, :params, params))
    |> Map.update!(:fun_decl, &Map.put_new(&1, :return, return))
  end

  defp deconstruct_type(node), do: node

end
