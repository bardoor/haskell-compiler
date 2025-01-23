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

  def add_field(%__MODULE__{} = gen_class, name, type, modifiers) do
    nil
  end

  def add_method(%__MODULE__{} = gen_class, name, type, modifiers, code) do
    nil
  end

end
