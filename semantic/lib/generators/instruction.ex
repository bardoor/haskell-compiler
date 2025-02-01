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
  def iload(const_pool, {:int, value}) when is_integer(value) do
    if value in -32768..32767 do
      push(value)
    else
      new(3, :ldc_w, constant_num(const_pool, {:int, value}))
    end
  end

  @doc """
  Загрузка локальной переменной по индексу
  """
  def iload(var_num) when is_integer(var_num) do
    if var_num in 0..3 do
      new(1, String.to_atom("iload_#{var_num}"), nil)
    else
      new(2, :iload, var_num)
    end
  end

  def aload(local_id) when is_integer(local_id) do
    new(2, :aload, local_id)
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
  def invoke(const_pool, {name, type, class}) do
    new(3, :invokestatic, constant_num(const_pool, {:class_method, name, type, class}))
  end

  @doc """
  Условный прыжок на offset
  """
  def jump_if(condition, offset) do
    case condition do
      :eq -> new(3, :if_icmpeq, offset + 3)
      :ne -> new(3, :if_icmpne, offset + 3)
      :lt -> new(3, :if_icmplt, offset + 3)
      :le -> new(3, :if_icmple, offset + 3)
      :gt -> new(3, :if_icmpgt, offset + 3)
      :ge -> new(3, :if_icmpge, offset + 3)
    end
  end

  @doc """
  Побитовое или
  """
  def ior() do
    new(1, :ior, nil)
  end

  @doc """
  Побитовое и
  """
  def iand() do
    new(1, :iand, nil)
  end

  @doc """
  Сложить два числа на стеке и положить вместо них результат
  """
  def iadd() do
    new(1, :iadd, nil)
  end

  @doc """
  Вычесть два числа на стеке и положить вместо них результат
  """
  def isub() do
    new(1, :isub, nil)
  end

  @doc """
  Умножить два числа на стеке и положить вместо них результат
  """
  def imul() do
    new(1, :imul, nil)
  end

  @doc """
  Поделить два числа на стеке и положить вместо них результат
  """
  def idiv() do
    new(1, :idiv, nil)
  end

  @doc """
  Воротить вершину стека
  """
  def return() do
    new(1, :ireturn, nil)
  end

  @doc """
  Безусловный прыжок на offset (не считая сам goto)
  """
  def goto(offset) do
    new(3, :goto, offset + 3)
  end

  @doc """
  Сравнение двух элементов на стеке

  Кладёт результат сравнения на стек
  """
  def icompare(op) do
    false_branch = push(0)

    true_branch = concat([
      push(1),
      goto(size(false_branch))
    ])

    jump_op = negate_op(op)

    concat([
      jump_if(jump_op, size(true_branch)),
      true_branch,
      false_branch
    ])
  end

  @doc """
  Размер инструкций в байтах
  """
  def size(instructions) when is_list(instructions) do
    Enum.reduce(instructions, 0, fn instruct, acc -> acc + instruct.size end)
  end

  def size(instruction) do
    instruction.size
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

  defp negate_op(op) do
    case op do
      :eq -> :ne
      :ne -> :eq
      :lt -> :ge
      :le -> :gt
      :gt -> :le
      :ge -> :lt
    end
  end

end
