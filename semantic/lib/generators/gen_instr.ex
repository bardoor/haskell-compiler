defmodule Generators.GenInstr do
  @moduledoc """
  Модуль генерации инструкций JVM в логическом представлении

  Работает с АСД, превращая его в последовательность инструкций
  """
  alias Generators.ConstPool
  alias Generators.Instruction, as: Instr

  @doc """
  Генерирует инструкции JVM
  """
  @spec generate(ConstPool.constant_pool(), map()) :: [%Instr{}] | %Instr{}
  def generate(const_pool, %{fun_decl: %{left: _left, right: right}}) do
    Instr.concat([
      generate(const_pool, right),
      Instr.return()
    ])
  end

  def generate(const_pool, %{if: %{cond: condition, then: then, else: else_expr}}) do
    cond_instrs = generate(const_pool, condition)
    then_instrs = generate(const_pool, then)
    else_instrs = generate(const_pool, else_expr)
    then_instrs = Instr.concat([then_instrs, Instr.goto(Instr.size(else_instrs))])

    Instr.concat([
      cond_instrs,
      Instr.push(0),
      Instr.jump_if(:eq, Instr.size(then_instrs)),
      then_instrs,
      else_instrs,
    ])
  end

  def generate(_const_pool, %{funid: funid}) when is_number(funid) do
    Instr.load(funid)
  end

  def generate(const_pool, %{literal: %{type: "int", value: value}}) do
    {value, _} = Integer.parse(value)

    Instr.load(const_pool, {:int, value})
  end

  def generate(const_pool, %{op: %{type: type}, left: left, right: right}) do
    type = String.to_atom(type)

    op_instrs = case type do
      :or    -> Instr.ior()
      :and   -> Instr.iand()
      :minus -> Instr.isub()
      :plus  -> Instr.iadd()
      :mul   -> Instr.imul()
      :div   -> Instr.idiv()
      type when type in [:eq, :ne, :lt, :le, :gt, :ge] -> Instr.icompare(type)
      _ -> raise "Unknown operation: #{type}"
    end

    Instr.concat([
      generate(const_pool, left),
      generate(const_pool, right),
      op_instrs
    ])
  end

  def generate(const_pool, %{funid: id, params: params}) do
    method = ConstPool.find_method(const_pool, id)

    load_instrs = if length(params) == 1 do
      generate(const_pool, Enum.at(params, 0))
    else
      Enum.reverse(params) |> Enum.flat_map(&generate(const_pool, &1))
    end

    Instr.concat([load_instrs, Instr.invoke(const_pool, method)])
  end

  def generate(const_pool, %{funid: id}) when is_binary(id) do
    method = ConstPool.find_method(const_pool, id)

    Instr.invoke(const_pool, method)
  end
end
