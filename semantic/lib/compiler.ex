defmodule Semantic do
  alias Generators.GenBytecode
  alias Generators.GenClass
  alias Semantic.Transformers

  def start(str) do
    #IO.puts("""
    #     @@@           @@@           @@@
    #   @@@@@@@       @@@@@@@       @@@@@@@
    # @@@@@@@@@@@   @@@@@@@@@@@   @@@@@@@@@@@
    #  @@@@@@@@       @@@@@@@       @@@@@@@
    #     @@@           @@@           @@@
    #      |             |             |
    #      |             |             |
    #      |             |             |
    #    Haskell compiler. Enjoy the ride
    #""")

    {:ok, tree} = ParserBridge.parse(str)

    transformed = tree
    |> Transformers.link_funcs_and_types
    |> Transformers.index_locals
    |> IO.inspect()

    class = GenClass.new()
    |> GenClass.generate(transformed)


  end

  def put_error(message) do
    IO.puts(:stderr, "\e[31m" <> message <> "\e[0m")
  end

end
