defmodule Generators.ConstPool do
  @moduledoc """
  Модуль управления таблицей констант
  """
  @type type :: :int | :float | :str | {:class, String.t()}
  @type constant_pool :: [tuple()]
  @type constant ::
            {:utf8, String.t()}
          | {:int, integer()}
          | {:float, float()}
          | {:class, String.t()}
          | {:name_and_type, String.t(), String.t()}
          | {:class_method, String.t(), String.t(), String.t()}

  @u4_const [:int, :float]

  @doc """
  Добавляет в таблицу констант запись
  """
  @spec add_constant(constant_pool(), constant()) :: constant_pool()
  def add_constant(constant_pool, {:utf8, str}) do
    add_if_miss(constant_pool, {:utf8, String.length(str), str})
  end

  def add_constant(constant_pool, {:class, class_name}) do
    constant_pool = add_constant(constant_pool, {:utf8, class_name})
    name_const_num = constant_num(constant_pool, {:utf8, class_name})

    add_if_miss(constant_pool, {:class, name_const_num})
  end

  def add_constant(constant_pool, {type, _} = const) when type in @u4_const do
    add_if_miss(constant_pool, const)
  end

  def add_constant(constant_pool, {:name_and_type, name, type}) do
    new_pool =
      constant_pool
      |> add_constant({:utf8, name})
      |> add_constant({:utf8, type})

    name_num = constant_num(new_pool, {:utf8, name})
    type_num = constant_num(new_pool, {:utf8, type})

    add_if_miss(new_pool, {:name_and_type, name_num, type_num})
  end

  def add_constant(constant_pool, {:class_method, name, type, class}) do
    new_pool = add_constants(constant_pool, [
      {:name_and_type, name, type},
      {:class, class}
    ])
    name_and_type_num = constant_num(new_pool, {:name_and_type, name, type})
    class_num = constant_num(new_pool, {:class, class})

    add_if_miss(new_pool, {:class_method, class_num, name_and_type_num})
  end

  def add_constant(constant_pool, {:int, value}) do
    add_if_miss(constant_pool, {:int, value})
  end

  @doc """
  Добавляет в пул множество констант
  """
  @spec add_constant(constant_pool(), [constant()]) :: constant_pool()
  def add_constants(constant_pool, constants) do
    Enum.reduce(constants, constant_pool,
      fn constant, acc -> add_constant(acc, constant)
    end)
  end


  @doc """
  Создаёт строку дескриптора для метода
  """
  @spec method_descriptor([type()], type()) :: {:utf8, String.t()}
  def method_descriptor(params, return) do
    params_str = params
      |> Enum.map(&descriptor_type/1)
      |> Enum.join("")

    {:utf8, enclose(params_str, "(", ")") <> descriptor_type(return)}
  end


  @doc """
  Получить номер константы из таблицы
  """
  @spec constant_num(constant_pool(), constant()) :: non_neg_integer()
  def constant_num(const_pool, {:utf8, str}) do
    case Enum.find_index(const_pool, fn const -> match?({:utf8, _len, ^str}, const) end) do
      nil -> raise "{:utf8, #{str}} not found!"
      index -> index + 1
    end
  end

  def constant_num(const_pool, {:class, name}) do
    name_num = constant_num(const_pool, {:utf8, name})

    case Enum.find_index(const_pool, fn const -> match?({:class, ^name_num}, const) end) do
      nil -> raise "{:class, #{name}} not found!"
      index -> index + 1
    end
  end

  def constant_num(const_pool, {:name_and_type, name, type}) do
    name_num = constant_num(const_pool, {:utf8, name})
    type_num = constant_num(const_pool, {:utf8, type})

    case Enum.find_index(const_pool, fn const -> match?({:name_and_type, ^name_num, ^type_num}, const) end) do
      nil -> raise "{:name_and_type, #{name}, #{type}} not found!"
      index -> index + 1
    end
  end

  def constant_num(const_pool, {:class_method, name, type, class}) do
    name_and_type_num = constant_num(const_pool, {:name_and_type, name, type})
    class_num = constant_num(const_pool, {:class, class})

    case Enum.find_index(const_pool, fn const -> match?({:class_method, ^class_num, ^name_and_type_num}, const) end) do
      nil -> raise "{:class_method, #{class}, #{name}, #{type}} not found!"
      index -> index + 1
    end
  end

  def constant_num(const_pool, {:int, value}) when is_integer(value) do
    case Enum.find_index(const_pool, fn const -> match?({:int, ^value}, const) end) do
      nil -> raise "{:int, #{value}} not found!"
      index -> index + 1
    end
  end


  @doc """
  Найти метод по имени

  Делаются допущенья:
  * Имена всех методов уникальны
  * Нет перегрузки методов
  """
  def find_method(const_pool, name) do
    name_num = constant_num(const_pool, {:utf8, name})

    {_,_,type_num} = Enum.find(const_pool, fn const ->
      match?({:name_and_type, ^name_num, _type}, const)
    end)

    {:utf8, _, type} = Enum.at(const_pool, type_num - 1)

    name_and_type_num = constant_num(const_pool, {:name_and_type, name, type})

    {_, class_num, _} = Enum.find(const_pool, fn const ->
      match?({:class_method, _class_num, ^name_and_type_num}, const)
    end)

    {:class, class_name_num} = Enum.at(const_pool, class_num - 1)
    {:utf8, _, class_name} = Enum.at(const_pool, class_name_num - 1)

    {name, type, class_name}
  end


  # Добавляет значение в коллекцию, если его там нет
  defp add_if_miss(enum, value) do
    if Enum.member?(enum, value), do: enum, else: enum ++ [value]
  end

  defp enclose(str, first, last) do
    first <> str <> last
  end

  defp descriptor_type(type) do
    case type do
      :int -> "I"
      :float -> "F"
      :void -> "V"
      :str -> "Ljava/lang/String;"
      :list -> "Lhaskell/prelude/List;"
      {:class, name} -> "L#{name};"
    end
  end

  def str_to_type(type) when is_binary(type) do
    type = type
    |> String.downcase()
    |> String.trim()

    case type do
      "int" -> :int
      "float" -> :float
      "string" -> :str
      "io" -> :void
    end
  end

  def str_to_type(%{list: _type}) do
    :list
  end

end
