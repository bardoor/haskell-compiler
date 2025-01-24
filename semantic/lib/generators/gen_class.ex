defmodule Generators.GenClass do
  @moduledoc """
  Модуль генерации класса

  Обходит дерево и собирает Java класс, готовый к трансляции в байткод
  """

  alias Generators.ConstPool
  defstruct minor_version: 0,
            major_version: 65,
            constant_pool: [],
            access_flags: [:public],
            this_class: "rtl/core/Functions",
            super_class: "java/lang/Object",
            interfaces: [],
            fields: [],
            methods: [],
            attributes: []

  @modifiers [:public, :protected, :private, :static, :abstract]

  def new do
    %__MODULE__{}
  end

  def add_class_modifiers(%__MODULE__{} = gen_class, modifiers) do
    unless Enum.all?(modifiers, &(&1 in @modifiers)) do
      raise "Некорректный модификатор класса #{gen_class.this_class}: #{modifiers}"
    end
    %{gen_class | access_flags: modifiers}
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

    class.constant_pool
    |> GenMethod.new(name, params_type, return_type, modifiers)
    |> GenMethod.add_instructions(instructions)
  end

  def validate_modifiers!(modifiers) do
    if not Enum.all?(modifiers, &(&1 in @modifiers)) do
      raise "Некорректный модификатор класса: #{modifiers}"
    end
  end

end
