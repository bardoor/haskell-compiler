defmodule Compiler do
  alias Generators.GenBytecode
  alias Generators.GenClass
  alias Semantic.{Transformers, TypeValidation}

  def compile(code, output_dir) do
    IO.puts("""
         @@@           @@@           @@@
       @@@@@@@       @@@@@@@       @@@@@@@
     @@@@@@@@@@@   @@@@@@@@@@@   @@@@@@@@@@@
      @@@@@@@@       @@@@@@@       @@@@@@@
         @@@           @@@           @@@
          |             |             |
          |             |             |
          |             |             |
        Haskell compiler. Enjoy the ride
    """)

    {:ok, tree} = ParserBridge.parse(code)

    transformed = tree
    |> Transformers.link_funcs_and_types()
    |> Transformers.index_locals()
    |> IO.inspect()

    GenClass.new()
    |> GenClass.generate(transformed)
    |> TypeValidation.validate!(transformed)
    |> save_bytecode(output_dir)

  end

  def put_error(message) do
    IO.puts(:stderr, "\e[31m" <> message <> "\e[0m")
  end

  defp save_bytecode(class, dir) do
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{class.this_class}.class")

    case File.open(path, [:write, :binary]) do
      {:ok, file} ->
        IO.binwrite(file, GenBytecode.generate(class))
        File.close(file)

      {:error, reason} ->
        put_error(to_string(reason))
    end
  end

end
