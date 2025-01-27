defmodule Generators.GenClass do
  @moduledoc """
  Модуль генерации класса

  Обходит дерево и собирает Java класс, готовый к трансляции в байткод
  """

  alias Generators.GenMethod
  alias Generators.GenInstr

  defstruct minor_version: 0,
            major_version: 65,
            constant_pool: [],
            access_flags: [:public],
            this_class: "rtl/core/Main",
            super_class: "java/lang/Object",
            interfaces: [],
            fields: [],
            methods: [],
            attributes: []

  @modifiers [:public, :protected, :private, :static, :abstract]

  def new() do
    %__MODULE__{}
  end

  def generate(class, %{module: module}) do
    class |> generate(module)
  end

  def generate(class, %{decls: decls}) do
    decls |> Enum.map(&generate(class, &1))
  end

  def generate(class, %{fun_decl: %{left: left, right: right, type: type}}) do
    code = GenInstr.generate(class.constant_pool, right)

    add_method(class, left.repr, type.params, type.return, [:public, :static], code)
  end

  @doc """
  Добавляет метод в класс

  ## Параметры

    - class: Класс для добавления
    - name: Название метода
    - params_type: Типы параметров в порядке следования
    - return_type: Тип возвращаемого значения
    - modifiers: Список модификаторов метода
    - code: Список инструкций
  """
  def add_method(%__MODULE__{} = class, name, params_type, return_type, modifiers, instructions) do
    validate_modifiers!(modifiers)

    class = Map.update!(class, :constant_pool, &ConstPool.add_constant(&1, {:utf8, "Code"}))

    method = class.constant_pool
    |> GenMethod.new(name, params_type, return_type, modifiers)
    |> GenMethod.add_instructions(instructions)

    Map.update!(class, :methods, &(&1 ++ [method]))
  end

  defp validate_modifiers!(modifiers) do
    if not Enum.all?(modifiers, &(&1 in @modifiers)) do
      raise "Некорректный модификатор класса: #{modifiers}"
    end
  end

end
