defmodule SemanticTest do
  use ExUnit.Case
  doctest Semantic

  test "simple if one variable" do
    Semantic.start("a = if b == 7 then 1 else 2")
    |>IO.inspect()
  end

  test "complex if condition" do
    Semantic.start("a = if (a == 5 && b == 7 || b == 9) && c == 11 then 1 else 2")
    |>IO.inspect()
  end
end
