from tools import parse_to_dict


def test_constant_declarations():
    result = parse_to_dict("{ a = x + 1; b = 5 + 7; c = a - b }")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "fun_decl": {
                        "left": {"repr": "a", "type": "funid"},
                        "right": {
                            "expr": {
                                "left": {"expr": {"funid": "x"}},
                                "op": {"repr": "+", "type": "symbols"},
                                "right": {
                                    "expr": {"literal": {"type": "int", "value": "1"}}
                                },
                            }
                        },
                    }
                },
                {
                    "fun_decl": {
                        "left": {"repr": "b", "type": "funid"},
                        "right": {
                            "expr": {
                                "left": {
                                    "expr": {"literal": {"type": "int", "value": "5"}}
                                },
                                "op": {"repr": "+", "type": "symbols"},
                                "right": {
                                    "expr": {"literal": {"type": "int", "value": "7"}}
                                },
                            }
                        },
                    }
                },
                {
                    "fun_decl": {
                        "left": {"repr": "c", "type": "funid"},
                        "right": {
                            "expr": {
                                "left": {"expr": {"funid": "a"}},
                                "op": {"repr": "-", "type": "symbols"},
                                "right": {"expr": {"funid": "b"}},
                            }
                        },
                    }
                },
            ],
            "name": 0,
        }
    }
    assert expected == actual


def test_func_declarations():
    result = parse_to_dict("{ func a b c = 2 * (a + b - c); otherFunc 1 2 3 = 15 }")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "fun_decl": {
                        "left": {
                            "funlhs": {
                                "name": {"repr": "func", "type": "funid"},
                                "params": [
                                    {"pattern": "a"},
                                    {"pattern": "b"},
                                    {"pattern": "c"},
                                ],
                            }
                        },
                        "right": {
                            "expr": {
                                "left": {
                                    "expr": {"literal": {"type": "int", "value": "2"}}
                                },
                                "op": {"repr": "*", "type": "symbols"},
                                "right": {
                                    "expr": {
                                        "left": {
                                            "expr": {
                                                "left": {"expr": {"funid": "a"}},
                                                "op": {"repr": "+", "type": "symbols"},
                                                "right": {"expr": {"funid": "b"}},
                                            }
                                        },
                                        "op": {"repr": "-", "type": "symbols"},
                                        "right": {"expr": {"funid": "c"}},
                                    }
                                },
                            }
                        },
                    }
                },
                {
                    "fun_decl": {
                        "left": {
                            "funlhs": {
                                "name": {"repr": "otherFunc", "type": "funid"},
                                "params": [
                                    {
                                        "pattern": {
                                            "literal": {"type": "int", "value": "1"}
                                        }
                                    },
                                    {
                                        "pattern": {
                                            "literal": {"type": "int", "value": "2"}
                                        }
                                    },
                                    {
                                        "pattern": {
                                            "literal": {"type": "int", "value": "3"}
                                        }
                                    },
                                ],
                            }
                        },
                        "right": {"expr": {"literal": {"type": "int", "value": "15"}}},
                    }
                },
            ],
            "name": 0,
        }
    }

    assert expected == actual


def test_patterns_func_def():
    result = parse_to_dict("{ func (1,2,_,xs) = xs }")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "fun_decl": {
                        "left": {
                            "funlhs": {
                                "name": {"repr": "func", "type": "funid"},
                                "params": [
                                    {
                                        "pattern": {
                                            "tuple": [
                                                [
                                                    {
                                                        "pattern": {
                                                            "literal": {
                                                                "type": "int",
                                                                "value": "2",
                                                            }
                                                        }
                                                    },
                                                    {"pattern": "wildcard"},
                                                    {"pattern": "xs"},
                                                ],
                                                {
                                                    "pattern": {
                                                        "literal": {
                                                            "type": "int",
                                                            "value": "1",
                                                        }
                                                    }
                                                },
                                            ]
                                        }
                                    }
                                ],
                            }
                        },
                        "right": {"expr": {"funid": "xs"}},
                    }
                }
            ],
            "name": 0,
        }
    }

    assert expected == actual


def test_do_stmt():
    result = parse_to_dict('{ a = do { (1,2,3) <- lol; put "hehe"; }}')

    assert result[0] != "error", result[1]

    actual = result[1]

    excepted = {
        "module": {
            "decls": [
                {
                    "fun_decl": {
                        "left": {"repr": "a", "type": "funid"},
                        "right": {
                            "do": {
                                "stmts": [
                                    {
                                        "binding": {
                                            "left": {
                                                "expr": {
                                                    "tuple": [
                                                        {
                                                            "expr": {
                                                                "literal": {
                                                                    "type": "int",
                                                                    "value": "2",
                                                                }
                                                            }
                                                        },
                                                        {
                                                            "expr": {
                                                                "literal": {
                                                                    "type": "int",
                                                                    "value": "3",
                                                                }
                                                            }
                                                        },
                                                        {
                                                            "expr": {
                                                                "literal": {
                                                                    "type": "int",
                                                                    "value": "1",
                                                                }
                                                            }
                                                        },
                                                    ]
                                                }
                                            },
                                            "right": {"expr": {"funid": "lol"}},
                                        }
                                    },
                                    [
                                        {"expr": {"funid": "put"}},
                                        {
                                            "expr": {
                                                "literal": {
                                                    "type": "str",
                                                    "value": "hehe",
                                                }
                                            }
                                        },
                                    ],
                                ]
                            }
                        },
                    }
                }
            ],
            "name": 0,
        }
    }

    assert excepted == actual


def test_typed_vars_decl():
    result = parse_to_dict("{ a :: Num a => a }")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "context": {
                        "overlay": {"constructor": "Num", "type_list": [{"funid": "a"}]}
                    },
                    "type": {"funid": "a"},
                    "vars": {"repr": "a", "type": "funid"},
                }
            ],
            "name": 0,
        }
    }

    assert expected == actual


def test_class_decl_body_none():
    result = parse_to_dict("{class MyClass foo}")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "class_decl": {
                        "body": None,
                        "class": {"tycon": "MyClass", "tyvar": {"funid": "foo"}},
                    }
                }
            ],
            "name": 0,
        }
    }

    assert expected == actual


def test_class_decl_with_where():
    result = parse_to_dict("{class MyClass foo where {}}")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "class_decl": {
                        "body": {"decl": {}},
                        "class": {"tycon": "MyClass", "tyvar": {"funid": "foo"}},
                    }
                }
            ],
            "name": 0,
        }
    }

    assert expected == actual


def test_class_decl_with_contextList():
    result = parse_to_dict("{class (Read a, Show a) => Textual a}")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "class_decl": {
                        "body": None,
                        "class": {"tycon": "Textual", "tyvar": {"funid": "a"}},
                        "context": {
                            "contextList": [
                                {"tycon": "Read", "tyvar": {"funid": "a"}},
                                {"tycon": "Show", "tyvar": {"funid": "a"}},
                            ]
                        },
                    }
                }
            ],
            "name": 0,
        }
    }

    assert expected == actual
