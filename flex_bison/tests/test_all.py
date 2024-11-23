import subprocess

import tree_sitter_json as tsjson 
from tree_sitter import Language, Parser, Tree

JSON_LANG = Language(tsjson.language())
JSON_PARSER = Parser(JSON_LANG)

def run_parser(code: str, parser_name: str = "bin/haskellc") -> tuple[str, str]:
    output = subprocess.run([parser_name, "-c", code], capture_output=True)
    return (output.stdout.decode(), output.stderr.decode())

def test_constant_declare():
    (out, errors) = run_parser("{ a = x + 1; }")
    
    json_index = out.find("json")
    assert json_index != -1

    json_str = out[json_index + 5:]
    json_tree = JSON_PARSER.parse(bytes(json_str, "utf-8"))
    
    assert len(errors) == 0
