import subprocess
import json
from graphviz import Digraph


def run_parser(code: str, parser_name: str = "bin/haskellc") -> tuple[str, str]:
    output = subprocess.run([parser_name, "-c", code], capture_output=True)
    return (output.stdout.decode(), output.stderr.decode())


def parse_to_dict(code: str, parser_name: str = "bin/haskellc") -> dict:
    (out, errors) = run_parser(code, parser_name)

    if len(errors) != 0:
        return ("error", errors)

    # Прибавляем 5 - длину строки 'json:'
    json_index = out.find("json:") + 5
    json_str = out[json_index:]

    return ("ok", json.loads(json_str))


def _dict_node_to_dot(value, current_node, graph):
    if isinstance(value, dict):
        dict_to_dot(value, current_node, graph)
    elif isinstance(value, list):
        for i, leaf in enumerate(value):
            leaf_node = f"{current_node}.{i}"  
            graph.node(leaf_node, label=f"[{i}]") 
            graph.edge(current_node, leaf_node)  
            _dict_node_to_dot(leaf, leaf_node, graph)  
    else:
        leaf_node = f"{current_node}.{value}"
        graph.node(leaf_node, label=str(value))
        graph.edge(current_node, leaf_node)


def dict_to_dot(source: dict, parent=None, graph=None):
    if graph is None:
        graph = Digraph()
    
    for key, value in source.items():
        current_node = f"{parent}.{key}" if parent else key
        graph.node(current_node, label=key)

        if parent is not None:
            graph.edge(parent, current_node)

        _dict_node_to_dot(value, current_node, graph)

    return graph

(status, result) = parse_to_dict("{ a = a + 1; b = 5 + 7; c = a + b; d = c + a + b; }")
print(result)
dict_to_dot(result).render(format='pdf')