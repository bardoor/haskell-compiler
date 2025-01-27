defmodule Generators.GenMethod do
  alias Generators.ConstPool
  defstruct access_flags: [:static, :public],
            name_num: nil,
            descriptor_num: nil,
            max_stack: 100,
            max_locals: 100,
            code_const_num: nil,
            code: nil


  def new(const_pool, name, params_type, return_type, modifiers) do
    name_num = ConstPool.constant_num(const_pool, {:utf8, name})
    descriptor_num = ConstPool.constant_num(const_pool, ConstPool.method_descriptor(params_type, return_type))
    code_const_num = ConstPool.constant_num(const_pool, {:utf8, "Code"})

    %__MODULE__{access_flags: modifiers, name_num: name_num, descriptor_num: descriptor_num, code_const_num: code_const_num}
  end

  def add_instructions(%__MODULE__{} = gen_method, instructions) do
    if not is_list(instructions) do
      %{gen_method | code: [instructions]}
    else
      %{gen_method | code: instructions}
    end

  end
end
