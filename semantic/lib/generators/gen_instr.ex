defmodule Generators.GenInstr do
  alias Generators.Instruction, as: Instr

  def generate(const_pool, %{cond: condition, then: then, else: else_expr}) do
    cond_instrs = generate(const_pool, condition)
    then_instrs = generate(const_pool, then)
    else_instrs = generate(const_pool, else_expr)

    Instr.concat([
      cond_instrs,
      Instr.push(0),
      Instr.jump_if(:eq, Instr.size(then_instrs) + 1),
      then_instrs,
      Instr.goto(Instr.size(else_instrs) + 1),
      else_instrs,
      Instr.return()
    ])
  end

end
