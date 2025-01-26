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

    raise_types_funcs_mismatch!(types, funcs)

    typed_funcs = zip_types_funcs(types, funcs)
    |> Enum.map(fn {%{type: type}, fun_decl} ->
      Map.put(fun_decl, :type, type)
    end)

    %{decls: typed_funcs ++ (decls -- types -- funcs)}
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
    zip_on(types, funcs, fn type, func -> type.vars.repr == func.left.repr end)
  end

  defp raise_types_funcs_mismatch!(types, funcs) do
    types_map = Map.new(types, fn type -> {type.vars.repr, type} end)
    funcs_map = Map.new(funcs, fn func -> {func.left.repr, func} end)

    types_without_funcs = Map.keys(types_map) -- Map.keys(funcs_map)
    funcs_without_types = Map.keys(funcs_map) -- Map.keys(types_map)

    if types_without_funcs != [] do
      raise "Types without corresponding functions: #{Enum.join(types_without_funcs, ", ")}"
    end

    if funcs_without_types != [] do
      raise "Functions without corresponding types: #{Enum.join(funcs_without_types, ", ")}"
    end
  end

end
