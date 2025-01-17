defmodule Generators.GenCode do
  defstruct instructions: [], const_pool: []

  def new do
    %Generators.GenCode{}
  end

  def start_if(%__MODULE__{} = gen_code, {:cmp, first, second}) do
    # Загрузить на стек first и second из таблицы констант если переменная либо большое число
    # ЛИБО загрузить на стек число

    # [load first, load second, {if<тип>cmpne, nil}]
  end

  def load_const(%__MODULE__{} = gen_code, const) do
    # Загрузить на стек константу из таблицы констант
  end

  def load_var(%__MODULE__{} = gen_code, var) do
    # Загрузить на стек переменную
  end

  def end_if(%__MODULE__{} = gen_code) do
    # К последнему if добавить строку перехода
  end

  def return(%__MODULE__{} = gen_code) do
    # Добавить в инструкции return
  end

end
