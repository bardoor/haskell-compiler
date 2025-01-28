defmodule SemanticTest do
  use ExUnit.Case
  doctest Compiler

  @build_dir "../program"

  test "func with type" do
    Compiler.compile("""
      func :: Int -> Int
      func a = if a < 1 || a == 25 then a else 999
    """, @build_dir)
  end

  test "constant" do
    Compiler.compile("""
      const :: Int
      const = 12 - 11
    """, @build_dir)
  end

  test "invoke function no params" do
    Compiler.compile("""
      const :: Int
      const = 1 - 3

      calculation :: Int
      calculation = const - 12
    """, @build_dir)
  end

  test "invoke function with params" do
    Compiler.compile("""
      sub :: Int -> Int -> Int
      sub a b = a - b

      calculation :: Int
      calculation = (sub 9 5) - 12
    """, @build_dir)
  end

  test "invoke recursive function" do
    Compiler.compile("""
      fib :: Int -> Int
      fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
    """, @build_dir)
  end

end
