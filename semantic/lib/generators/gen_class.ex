defmodule GenClass do
  defstruct minor_version: 0, major_version: 65,
            constant_pool: [], access_flags: [:public],
            super_class: :Object, interfaces: [],
            fields: [], methods: [], attributes: []

  @u4_const [:int, :float]
  @modifiers [:public, :protected, :private, :static, :abstract]

  def new do
    %GenClass{}
  end

  @doc """
  Добавляет в таблицу констант `GenClass` запись

  Подерживается:
  {:utf8, str} - добавляет строку в таблицу констант
  {:class, class_name} - добавляет ссылку на класс в таблицу констант
  {:int, value} - добавляет целое число в таблицу констант
  {:float, value} - добавляет число с плавающей точкой в таблицу констант
  {:name_and_type, name, type} - добавляет имя и тип в таблицу констант
  {:class_method, name, type} - добавляет ссылку на метод в таблицу констант
  """
  def add_constant(%__MODULE__{constant_pool: c_pool} = gen_class, {:utf8, str}) do
    %{gen_class | constant_pool: add_if_miss(c_pool, {:utf8, String.length(str), str})}
  end

  def add_constant(%__MODULE__{} = gen_class, {:class, class_name}) do
    new_gen_class = add_constant(gen_class, {:utf8, class_name})
    name_const_num = constant_num(new_gen_class, {:utf8, class_name})

    %{new_gen_class | constant_pool: add_if_miss(gen_class.constant_pool, {:class, name_const_num})}
  end

  def add_constant(%__MODULE__{} = gen_class, {type, _} = const) when type in @u4_const do
    %{gen_class | constant_pool: add_if_miss(gen_class.constant_pool, const)}
  end

  def add_constant(%__MODULE__{} = gen_class, {:name_and_type, name, type}) do
    new_gen_class = gen_class
    |> add_constant({:utf8, name})
    |> add_constant({:utf8, type})

    name_num = constant_num(new_gen_class, {:utf8, name})
    type_num = constant_num(new_gen_class, {:utf8, type})

    %{new_gen_class | constant_pool: add_if_miss(gen_class.constant_pool, {:name_and_type, name_num, type_num})}
  end

  def add_constant(%__MODULE__{} = gen_class, {:class_method, name, type})do
    new_gen_class = add_constant(gen_class, {:name_and_type, name, type})
    name_and_type_num = constant_num(new_gen_class, {:name_and_type, name, type})

    %{new_gen_class | constant_pool: add_if_miss(gen_class.constant_pool, {:class_method, name_and_type_num})}
  end


  def add_class_modifiers(%__MODULE__{} = gen_class, modifiers) do
    Enum.all?(modifiers, fn mod -> mod in @modifiers end) or raise ArgumentError
    %{gen_class | access_flags: modifiers}
  end


  def add_field(%__MODULE__{} = gen_class, name, type, modifiers) do
    nil
  end


  def add_method(%__MODULE__{} = gen_class, name, type, modifiers, code) do
    nil
  end


  def type() do
    # Из списка типов делает строку для JVM (я бля не помню как)
  end

  # Добавляет значение в коллекцию, если его там нет
  defp add_if_miss(enum, value) do
    if Enum.member?(enum, value), do: enum, else: enum ++ [value]
  end

  defp constant_num(%__MODULE__{} = gen_class, {:utf8, str}) do
    Enum.find_index(gen_class.constant_pool, fn {:utf8, _, ^str} -> true end) + 1
  end

  defp constant_num(%__MODULE__{} = gen_class, {:class, name}) do
    name_num = constant_num(gen_class, {:utf8, name})
    Enum.find_index(gen_class.constant_pool, fn {:class, ^name_num} -> true end) + 1
  end

  defp constant_num(%__MODULE__{} = gen_class, {:name_and_type, name, type}) do
    name_num = constant_num(gen_class, {:utf8, name})
    type_num = constant_num(gen_class, {:utf8, type})
    Enum.find_index(gen_class.constant_pool, fn {:name_and_type, ^name_num, ^type_num} -> true end) + 1
  end
end
