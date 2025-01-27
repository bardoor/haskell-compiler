defmodule Semantic.TypeValidation do
  def validate(%{type: type, vars: vars}, context) do
  end

  def validate(%{fun_decl: %{left: left, right: right}}, context) do
  end

  def validate(%{decls: decls}, context) do
    decls
    |> Enum.map(fn decl ->
      inner_context =
        type_decls(decls)
        |> MapSet.delete(decl)
        |> Enum.concat(context)

      validate(decl, inner_context)
    end)
  end

  def validate(%{module: module}, context) do
    validate(module, context)
  end

  defp type_decls(decls) do
    decls
    |> Enum.filter(&is_type?/1)
    |> MapSet.new()
  end

  defp is_type?(%{type: _, vars: _}), do: true
  defp is_type?(_), do: false
end
