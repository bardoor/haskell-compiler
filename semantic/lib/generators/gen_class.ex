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
            this_class: "Main",
            super_class: "java/lang/Object",
            interfaces: [],
            fields: [],
            methods: [],
            attributes: []

  @modifiers [:public, :protected, :private, :static, :abstract]

  def new() do
    %__MODULE__{}
  end

  def generate(%__MODULE__{} = class, %{module: module}) do
    generate(class, module)
  end

  def generate(%__MODULE__{} = class, %{decls: decls}) do
    Enum.reduce(decls, class, fn decl, acc ->
      generate(acc, decl)
    end)
  end

  def generate(%__MODULE__{} = class, %{fun_decl: %{left: left, right: right, return: return, params: params}}) do
    code = GenInstr.generate(class.constant_pool, right)
    params = Enum.map(params, &ConstPool.str_to_type/1)
    return = ConstPool.str_to_type(return)

    add_method(class, left.name, params, return, [:public, :static], code)
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

  @doc """
  Заполняет таблицу констант по АСД
  """
  def fill_constant_pool(%__MODULE__{} = class, %{module: module}) do
    c_pool = ConstPool.add_constants(class.constant_pool, [
      {:utf8, "java/lang/Object"},
      {:utf8, "<init>"},
      {:utf8, "()V"}
    ])

    fill_constant_pool(%{class | constant_pool: c_pool}, module)
  end

  def fill_constant_pool(%__MODULE__{} = class, %{decls: decls}) do
    Enum.reduce(decls, class, fn decl, acc ->
      if match?(%{fun_decl: _}, decl) do
        fill_constant_pool(acc, decl)
      else
        acc
      end
    end)
  end

  def fill_constant_pool(%__MODULE__{} = class, %{fun_decl: %{left: left, right: right, params: params, return: return}}) do
    name = left.name
    params = Enum.map(params, &ConstPool.str_to_type/1)
    return = ConstPool.str_to_type(return)
    {:utf8, type_desc} = ConstPool.method_descriptor(params, return)

    class = fill_constant_pool(class, right)

    c_pool = ConstPool.add_constant(class.constant_pool,
      {:class_method, name, type_desc, class.this_class}
    )

    %{class | constant_pool: c_pool}
  end

  def fill_constant_pool(%__MODULE__{} = class, _node) do
    class
  end

  defp validate_modifiers!(modifiers) do
    if not Enum.all?(modifiers, &(&1 in @modifiers)) do
      raise "Некорректный модификатор класса: #{modifiers}"
    end
  end

end
