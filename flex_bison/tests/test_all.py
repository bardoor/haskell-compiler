from tools import parse_to_dict

def test_constant_declare():
    result = parse_to_dict("{ a = x + 1; b = 5 + 7; c = a - b }")
    
    assert result[0] != 'error', result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "decl": {
                        "left": {"funid": "a"},
                        "right": {
                            "bin_expr": {
                                "left": {"funid": "x"},
                                "op": {"type": "symbols", "repr": "+"},
                                "right": {"literal": {"type": "int", "value": "1"}},
                            }
                        },
                    }
                },
                {
                    "decl": {
                        "left": {"funid": "b"},
                        "right": {
                            "bin_expr": {
                                "left": {"literal": {"type": "int", "value": "5"}},
                                "op": {"type": "symbols", "repr": "+"},
                                "right": {"literal": {"type": "int", "value": "7"}},
                            }
                        },
                    }
                },
                {
                    "decl": {
                        "left": {"funid": "c"},
                        "right": {
                            "bin_expr": {
                                "left": {"funid": "a"},
                                "op": {"type": "symbols", "repr": "-"},
                                "right": {"funid": "b"},
                            }
                        },
                    }
                },
            ],
            "name": 0,
        }
    }
    
    assert expected == actual
