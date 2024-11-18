import subprocess
import pytest

def run_parser(code: str, parser_name="bin/haskellc"):
    output = subprocess.run([parser_name, "-c", code], capture_output=True)
    return (output.stdout.decode(), output.stderr.decode())


def test_constant_declare():
    (out, errors) = run_parser("{ a = x + 1 }")
    assert "syntax error" not in errors
