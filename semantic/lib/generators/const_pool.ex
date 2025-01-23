defmodule Generators.ConstPool do
  @type constant_pool :: [tuple()]
  @type constant ::
            {:utf8, String.t()}
          | {:int, integer()}
          | {:float, float()}
          | {:class, String.t()}
          | {:name_and_type, String.t(), String.t()}
          | {:class_method, String.t(), String.t()}

  @u4_const [:int, :float]

  @doc """
  Добавляет в таблицу констант запись
  """
  @spec add_constant(constant_pool(), constant()) :: constant_pool()
  def add_constant(constant_pool, {:utf8, str}) do
    add_if_miss(constant_pool, {:utf8, String.length(str), str})
  end

  def add_constant(constant_pool, {:class, class_name}) do
    new_pool = add_constant(constant_pool, {:utf8, class_name})
    name_const_num = constant_num(constant_pool, {:utf8, class_name})

    add_if_miss(new_pool, {:class, name_const_num})
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

  def add_constant(constant_pool, {:class_method, name, type}) do
    new_pool = add_constant(constant_pool, {:name_and_type, name, type})
    name_and_type_num = constant_num(new_pool, {:name_and_type, name, type})

    add_if_miss(new_pool, {:class_method, name_and_type_num})
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
    Enum.find_index(const_pool, fn {:utf8, _, ^str} -> true end) + 1
  end

  def constant_num(const_pool, {:class, name}) do
    name_num = constant_num(const_pool, {:utf8, name})
    Enum.find_index(const_pool, fn {:class, ^name_num} -> true end) + 1
  end

  def constant_num(const_pool, {:name_and_type, name, type}) do
    name_num = constant_num(const_pool, {:utf8, name})
    type_num = constant_num(const_pool, {:utf8, type})
    Enum.find_index(const_pool, fn {:name_and_type, ^name_num, ^type_num} -> true end) + 1
  end

  def constant_num(const_pool, {:class_method, name, type}) do
    name_and_type_num = constant_num(const_pool, {:name_and_type, name, type})
    Enum.find_index(const_pool, fn {:class_method, ^name_and_type_num} -> true end) + 1
  end

  # Добавляет значение в коллекцию, если его там нет
  defp add_if_miss(enum, value) do
    if Enum.member?(enum, value), do: enum, else: enum ++ [value]
  end
end
