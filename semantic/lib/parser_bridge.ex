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
    |> Jason.decode!(keys: :atoms)
  end

  defp get_error(str) do
    {start, _len} = :binary.match(str, "syntax error")

    str
    |> String.slice(start..-1//1)
    |> String.trim()
  end

end
