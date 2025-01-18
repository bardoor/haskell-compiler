defmodule Generators.GenClass do
  alias Generators.ConstPool
  defstruct minor_version: 0,
            major_version: 65,
            constant_pool: [],
            access_flags: [:public],
            super_class: :Object,
            interfaces: [],
            fields: [],
            methods: [],
            attributes: []

  @modifiers [:public, :protected, :private, :static, :abstract]

  def new do
    %__MODULE__{}
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

end
