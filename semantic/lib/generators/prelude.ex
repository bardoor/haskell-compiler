defmodule Generators.Prelude do
  defstruct [:constants]

  def new() do
    Map.put(%__MODULE__{}, :constants, [
      {:class, "haskell/prelude/List"},
      {:class, "haskell/prelude/ListNode"},
      {:class_method, "length", "(Lhaskell/prelude/List;)I", "haskell/prelude/List"},
      {:class_method, "prepend", "(Lhaskell/prelude/List;I)Lhaskell/prelude/List;", "haskell/prelude/List"},
      {:class_method, "head", "(Lhaskell/prelude/List;)I", "haskell/prelude/List"},
      {:class_method, "tail", "(Lhaskell/prelude/List;)Lhaskell/prelude/List;", "haskell/prelude/List"},
      {:class_method, "create", "()Lhaskell/prelude/List;", "haskell/prelude/List"},
    ])
  end

end
