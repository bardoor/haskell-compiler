defmodule Generators.GenBytecode do
  import Bitwise
  alias Generators.Instruction
  alias Generators.GenMethod
  alias Generators.ConstPool
  alias Generators.GenClass

  def generate(%GenClass{} = class) do
    const_count = length(class.constant_pool) + 1
    interfaces_count = length(class.interfaces)
    fields_count = length(class.fields)
    methods_count = length(class.methods)
    this_class = ConstPool.constant_num(class.constant_pool, {:class, class.this_class})
    super_class = ConstPool.constant_num(class.constant_pool, {:class, class.super_class})

    <<0xCA, 0xFE, 0xBA, 0xBE>>
    <> <<class.minor_version::16>>
    <> <<class.major_version::16>>
    <> <<const_count::16>>
    <> bytify_const_pool(class.constant_pool)
    <> bytify_class_access_flags(class.access_flags)
    <> <<this_class::16>>
    <> <<super_class::16>>
    <> <<0::16>>
    <> <<0::16>>
    <> <<methods_count::16>>
    <> bytify_methods(class.methods)
    <> <<0::16>>  # Количество атрибутов класса
  end


  @spec bytify_const_pool(list()) :: binary()
  defp bytify_const_pool(const_pool) do
    Enum.reduce(const_pool, <<>>, fn const, acc ->
      IO.puts("Обрабатываем: #{inspect(const)}")
      acc <> case const do
        {:int, value}     -> <<3, value::32>> |> IO.inspect()
        {:class, num}     -> <<7, num::16>> |> IO.inspect()
        {:utf8, len, str} -> <<1, len::16>> <> str |> IO.inspect()
        {:name_and_type, name, type}      -> <<12, name::16, type::16>> |> IO.inspect()
        {:class_method, class, name_type} -> <<10, class::16, name_type::16>> |> IO.inspect()
        _ -> raise "Неизвестная команда"
      end
    end)
  end

  @spec bytify_class_access_flags(list()) :: binary()
  defp bytify_class_access_flags(flags) do
    mask = Enum.reduce(flags, 0, fn flag, acc ->
      case flag do
        :public -> acc ||| 0x0001
        :final  -> acc ||| 0x0010
        :super  -> acc ||| 0x0020
        :enum   -> acc ||| 0x4000
        :interface -> acc ||| 0x0200
        :abstract  -> acc ||| 0x0400
      end
    end)

    <<mask::16>>
  end

  @spec bytify_methods([%GenMethod{}]) :: binary()
  defp bytify_methods(methods) do
    Enum.reduce(methods, <<>>, fn method, acc ->
      code_size = Instruction.size(method.code)

      acc
      <> bytify_method_access_flags(method.access_flags)
      <> <<method.name_num::16>>
      <> <<method.descriptor_num::16>>
      <> <<1::16>>
      <> <<method.code_const_num::16>>
      <> <<code_size + 12::32>>  # Длина атрибута
      <> <<method.max_stack::16>>
      <> <<method.max_locals::16>>
      <> <<code_size::32>>
      <> bytify_code(method.code)
      <> <<0::16>>  # Длина таблицы обработчиков исключений
      <> <<0::16>>  # Количество атрибутов
    end)
  end

  @spec bytify_code(%Instruction{}) :: binary()
  defp bytify_code(code) do
    Enum.reduce(code, <<>>, fn instr, acc -> acc <> bytify_instr(instr) end)
  end

  @spec bytify_instr([%Instruction{}]) :: binary()
  defp bytify_instr(%Instruction{} = instr) do
    case instr do
      %Instruction{command: :iconst_m1} -> <<2>>
      %Instruction{command: :iconst_0}  -> <<3>>
      %Instruction{command: :iconst_1}  -> <<4>>
      %Instruction{command: :iconst_2}  -> <<5>>
      %Instruction{command: :iconst_3}  -> <<6>>
      %Instruction{command: :iconst_4}  -> <<7>>
      %Instruction{command: :iconst_5}  -> <<8>>

      %Instruction{command: :bipush, arg: val} -> <<0x10, val>>
      %Instruction{command: :sipush, arg: val} -> <<0x11, val::16>>

      %Instruction{command: :if_icmpeq, arg: val} -> <<159, val::16>>
      %Instruction{command: :if_icmpne, arg: val} -> <<160, val::16>>
      %Instruction{command: :if_icmplt, arg: val} -> <<161, val::16>>
      %Instruction{command: :if_icmpge, arg: val} -> <<162, val::16>>
      %Instruction{command: :if_icmpgt, arg: val} -> <<163, val::16>>
      %Instruction{command: :if_icmple, arg: val} -> <<164, val::16>>

      %Instruction{command: :ior}  -> <<0x80>>
      %Instruction{command: :iand} -> <<0x7E>>

      %Instruction{command: :iload_0} -> <<0x1A>>
      %Instruction{command: :iload_1} -> <<0x1B>>
      %Instruction{command: :iload_2} -> <<0x1C>>
      %Instruction{command: :iload_3} -> <<0x1D>>
      %Instruction{command: :iload, arg: val} -> <<0x15, val>>

      %Instruction{command: :ldc_w, arg: val} -> <<0x13, val::16>>

      %Instruction{command: :invokestatic, arg: val} -> <<0xB8, val::16>>

      %Instruction{command: :ireturn} -> <<0xAC>>

      %Instruction{command: :goto, arg: val} -> <<0xA7, val::16>>
    end
  end

  @spec bytify_method_access_flags(list()) :: binary()
  defp bytify_method_access_flags(flags) do
    mask = Enum.reduce(flags, 0, fn flag, acc ->
      case flag do
        :public    -> acc ||| 0x0001
        :private   -> acc ||| 0x0002
        :protected -> acc ||| 0x0004
        :static    -> acc ||| 0x0008
      end
    end)

    <<mask::16>>
  end


  @spec bytify_interfaces(list()) :: binary()
  defp bytify_interfaces(_interfaces) do
    <<>>
  end

  @spec bytify_fields(list()) :: binary()
  defp bytify_fields(_fields) do
    <<>>
  end
end
