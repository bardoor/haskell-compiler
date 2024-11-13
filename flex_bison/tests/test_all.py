import subprocess
import pytest

def run_parser(code: str, parser_name="bin/haskellc"):
    return subprocess.run([parser_name, "-c", code], capture_output=True)

def find_in_output(process: subprocess.CompletedProcess, substr: str):
    return process.stdout.decode("utf-8").find(substr)
     

def test_constant_declare():
    process = run_parser("a = x + 1")
    assert find_in_output(process, "syntax error") == -1


