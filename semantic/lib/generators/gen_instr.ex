defmodule Generators.GenInstr do
  @moduledoc """
  Модуль генерации инструкций JVM в логическом представлении

  Работает с АСД, превращая его в последовательность инструкций
  """

  alias Generators.Instruction, as: Instr

  def generate(const_pool, %{fun_decl: %{left: _left, right: right}}) do
    # TODO: left пока игорируется, нужно будет на паттерн матчинге?
    generate(const_pool, right)
  end

  def generate(const_pool, %{if: %{cond: condition, then: then, else: else_expr}}) do
    cond_instrs = generate(const_pool, condition)
    then_instrs = generate(const_pool, then)
    else_instrs = generate(const_pool, else_expr)
    then_instrs = Instr.concat([then_instrs, Instr.goto(Instr.size(else_instrs) + 1)])

    Instr.concat([
      cond_instrs,
      Instr.push(0),
      Instr.jump_if(:eq, Instr.size(then_instrs) + 1),
      then_instrs,
      else_instrs,
      Instr.return()
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
      :or -> Instr.ior()
      :and -> Instr.iand()
      type when type in [:eq, :ne, :lt, :le, :gt, :ge] -> Instr.icompare(type)
      _ -> raise "Unknown operation: #{type}"
    end

    Instr.concat([
      generate(const_pool, left),
      generate(const_pool, right),
      op_instrs
    ])
  end
end
