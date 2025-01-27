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

    {:ok, file} = File.open("#{class.this_class}.class", [:write, :binary])
    IO.binwrite(file, GenBytecode.generate(class))

    # TODO
    # Манглирование where
    # Валидация типов + разрешение имен (нет повторяющихся)
    # Запихнуть тип функции в её свойства - ГОТОВО
    # ? Проверка корректного обращения к структурам
    # ? Проверка паттерн матчинга?
    # ? Проверка сходимости рекурсии?


    # Int -> Float -> String
    # func a b = ...

    # funid {
    #   left {}
    #   right {}
    #   type {
    #     params: []
    #     return: []
    #   }
    # }
  end

  def put_error(message) do
    IO.puts("\e[31m" <> message <> "\e[0m")
  end

end
