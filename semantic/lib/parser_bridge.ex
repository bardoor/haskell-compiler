defmodule ParserBridge do
  @moduledoc false

  def parse(code, parser_path \\ "../bin/haskellc.exe") do
    case System.cmd(Path.expand(parser_path), ["-c", code], stderr_to_stdout: true) do
      {output, 0} -> {:ok, get_json(output)}
      {output, _} -> {:error, get_error(output)}
    end
  end

  defp get_json(str) do
    {start, len} = :binary.match(str, "json:")

    str
    |> String.slice((start + len)..-1//1)
    |> JSON.decode!()
    |> keys_to_atoms()
  end

  defp get_error(str) do
    {start, _len} = :binary.match(str, "syntax error")

    str
    |> String.slice(start..-1//1)
    |> String.trim()
  end

  defp keys_to_atoms(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      if is_map(value) or is_list(value) do
        {String.to_atom(key), keys_to_atoms(value)}
      else
        {String.to_atom(key), value}
      end
    end)
    |> Enum.into(%{})
  end

  defp keys_to_atoms(collection) when is_list(collection) do
    collection
    |> Enum.map(&keys_to_atoms(&1))
  end


end
