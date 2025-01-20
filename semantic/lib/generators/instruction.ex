defmodule Generators.Instruction do
  import Generators.ConstPool

  defstruct [:size, :command, :arg]

  def new(size, command, arg) do
    %__MODULE__{size: size, command: command, arg: arg}
  end

  @doc """
  Загрузка консанты из пула

  Создаёт iconst, bipush, sipush или ldc_w в зависимости от значения
  """
  def load(const_pool, {type, value}) do
    if value in -32768..32767 do
      push(value)
    else
      new(3, :ldc_w, constant_num(const_pool, {type, value}))
    end
  end

  @doc """
  Загрузка локальной переменной по индексу
  """
  def load(var_num) when is_integer(var_num) do
    if var_num in 0..3 do
      new(1, String.to_atom("iload_#{var_num}"), nil)
    else
      new(2, :iload, var_num)
    end
  end

  @doc """
  Положить на стек двубайтовое число (от -32768 до 32767)

  В зависимости от значения выбирается наиболее оптимальная команда
  """
  def push(value) do
    cond do
      value == -1 -> new(1, :iconst_m1, nil)
      value in 0..5 -> new(1, String.to_atom("iconst_#{value}"), nil)
      value in -128..127 -> new(2, :bipush, value)
      value in -32768..32767 -> new(3, :sipush, value)
    end
  end

  @doc """
  Вызов статической функции
  """
  def invoke(const_pool, {name, type}) do
    # TODO: Пуш на стек параметры
    new(3, :invokestatic, constant_num(const_pool, {:class_method, name, type}))
  end

  @doc """
  Условный прыжок на offset
  """
  def jump_if(condition, offset) do
    case condition do
      :eq -> new(3, :if_icmpeq, offset)
      :ne -> new(3, :if_icmpne, offset)
      :lt -> new(3, :if_icmplt, offset)
      :le -> new(3, :if_icmple, offset)
      :gt -> new(3, :if_icmpgt, offset)
      :ge -> new(3, :if_icmpge, offset)
    end
  end

  @doc """
  Воротить вершину стека
  """
  def return() do
    new(1, :ireturn, nil)
  end

  @doc """
  Безусловный прыжок на offset
  """
  def goto(offset) do
    new(3, :goto, offset)
  end

  @doc """
  Размер инструкций в байтах
  """
  def size(instructions) do
    Enum.reduce(instructions, 0, fn instruct, acc -> acc + instruct.size end)
  end

  @doc """
  Конкатенация инструкций

  Отдельный элемент может быть как списком, так и одиночной инструкцией
  """
  def concat(instructs) do
    Enum.reduce(instructs, [], fn instruct, acc ->
      if is_enumerable?(instruct) do
        acc ++ instruct
      else
        acc ++ [instruct]
      end
    end)
  end

  defp is_enumerable?(value) do
    case Enumerable.impl_for(value) do
      nil -> false
      _module -> true
    end
  end

end
