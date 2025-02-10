defmodule Generators.GenClass do
  @moduledoc """
  Модуль генерации класса

  Обходит дерево и собирает Java класс, готовый к трансляции в байткод
  """

  alias Generators.ConstPool
  alias Generators.GenMethod
  alias Generators.GenInstr

  defstruct minor_version: 0,
            major_version: 49,
            constant_pool: [],
            access_flags: [:public],
            this_class: "Functions",
            super_class: "java/lang/Object",
            std_lib: nil,
            interfaces: [],
            fields: [],
            methods: [],
            attributes: []

  @modifiers [:public, :protected, :private, :static, :abstract]

  def new() do
    %__MODULE__{}
    |> Map.put(:std_lib, Prelude.new())
  end

  @doc """
  Создаёт класс, готовый к переводу в байткод

  * Генерирует инструкции для методов
  * Заполняет таблицу констант
  """
  def generate(%__MODULE__{} = class, %{module: module} = root) do
    class
    |> fill_constant_pool(root)
    |> generate(module)
  end

  def generate(%__MODULE__{} = class, %{decls: decls}) do
    Enum.reduce(decls, class, fn decl, acc ->
      generate(acc, decl)
    end)
  end

  def generate(%__MODULE__{} = class, %{fun_decl: %{left: left, right: right, return: return, params: params}} = fun) do
    code = GenInstr.generate(class.constant_pool, fun)
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
      {:class, "java/lang/Object"},
      {:class_method, "<init>", "()V", "java/lang/Object"},
    ] ++ class.std_lib.constants)

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

  def fill_constant_pool(%__MODULE__{} = class, %{literal: %{type: "int", value: val}}) do
    {val, _} = Integer.parse(val)

    if val not in -32768..32767 do
      Map.update!(class, :constant_pool, &ConstPool.add_constant(&1, {:int, val}))
    else
      class
    end
  end

  def fill_constant_pool(%__MODULE__{} = class, node) when is_map(node) do
    Enum.reduce(node, class, fn {k, v}, acc ->
      fill_constant_pool(acc, v)
    end)
  end

  def fill_constant_pool(%__MODULE__{} = class, node) when is_list(node) do
    Enum.reduce(node, class, &fill_constant_pool(&2, &1))
  end

  def fill_constant_pool(%__MODULE__{} = class, _node) do
    class
  end

  defp validate_modifiers!(modifiers) do
    if not Enum.all?(modifiers, &(&1 in @modifiers)) do
      raise "Некорректный модификатор класса: #{modifiers}"
    end
  end

  def method_type(class, method) when is_binary(method) do
    {_name, type, _class} = ConstPool.find_method(class.constant_pool, method)

    descriptor = ConstPool.descriptor_to_atoms(type)

    params = Enum.drop(descriptor, -1)
    return = Enum.take(descriptor, -1)
    {params, return}
  end

end
