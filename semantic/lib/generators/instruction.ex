defmodule Generators.Instruction do
  import Generators.ConstPool

  defstruct [:size, :command, :arg]

  def new(size, command, arg) do
    %__MODULE__{size: size, command: command, arg: arg}
  end

  # Загрузка числовых контстант из пула
  def load(const_pool, {type, value}) do
    cond do
      value == -1 -> new(1, :iconst_m1, nil)
      value in 0..5 -> new(1, String.to_atom("iconst_#{value}"), nil)
      value in -128..127 -> new(2, :bipush, value)
      value in -32768..32767 -> new(3, :sipush, value)
      true -> new(3, :ldc_w, constant_num(const_pool, {type, value}))
    end
  end

  # Загрузка локальной переменной
  def load(var_num) when is_integer(var_num) do
    if var_num in 0..3 do
      new(1, String.to_atom("iload_#{var_num}"), nil)
    else
      new(2, :iload, var_num)
    end
  end

  # Вызов функции
  def invoke(const_pool, {name, type}) do
    # TODO: Пуш на стек параметры
    new(3, :invokestatic, constant_num(const_pool, {:class_method, name, type}))
  end

  
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

  def size(instructions) do
    Enum.reduce(instructions, 0, fn instruct, acc -> acc + instruct.size end)
  end

end
