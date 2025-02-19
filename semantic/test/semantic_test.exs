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

  test "insert sort" do
    Compiler.compile("""
      insert :: Int -> [Int] -> [Int]
      insert x lst = if length lst == 0 then x : []
                     else if x <= head lst then x : (head lst) : (tail lst)
                     else (head lst) : insert x (tail lst)

      isort :: [Int] -> [Int]
      isort lst = if length lst == 0 then []
                  else insert (head lst) (isort (tail lst))
    """, @build_dir)
  end

  test "simple list" do
    Compiler.compile("""
      index :: [Int] -> Int -> Int
      index xs x = indexHelper xs x 0

      indexHelper :: [Int] -> Int -> Int -> Int
      indexHelper xs x idx = if length xs == 0 then -1
                             else if head xs == x then idx
                                  else indexHelper (tail xs) x (idx + 1)
    """, @build_dir)
  end

  test "arguments" do
    Compiler.compile("""
      arguments :: [Int] -> Int -> Int -> [Int] -> Int -> [Int]
      arguments xs a b ys c = xs
    """, @build_dir)
  end

  test "list build" do
    Compiler.compile("""
      lst :: [Int]
      lst = 1 : 2 : 3 : []
    """, @build_dir)
  end

end
