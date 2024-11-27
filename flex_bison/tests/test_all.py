from tools import parse_to_dict


def test_constant_declarations():
    result = parse_to_dict("{ a = x + 1; b = 5 + 7; c = a - b }")

    assert result[0] != "error", result[1]

    actual = result[1]

    expected = {
        "module": {
            "decls": [
                {
                    "decl": {
                        "left": {"funid": "a"},
                        "right": {
                            "bin_expr": {
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
                    "decl": {
                        "left": {"funid": "b"},
                        "right": {
                            "bin_expr": {
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
                    "decl": {
                        "left": {"funid": "c"},
                        "right": {
                            "bin_expr": {
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
                    "decl": {
                        "left": {
                            "funlhs": {
                                "name": {"funid": "func"},
                                "params": [
                                    {"pattern": {"funid": "a"}},
                                    {"pattern": {"funid": "b"}},
                                    {"pattern": {"funid": "c"}},
                                ],
                            }
                        },
                        "right": {
                            "bin_expr": {
                                "left": {
                                    "expr": {"literal": {"type": "int", "value": "2"}}
                                },
                                "op": {"repr": {"symbols": "*"}, "type": "symbols"},
                                "right": {
                                    "bin_expr": {
                                        "left": {
                                            "bin_expr": {
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
                    "decl": {
                        "left": {
                            "funlhs": {
                                "name": {"funid": "otherFunc"},
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
                    "decl": {
                        "left": {
                            "funlhs": {
                                "name": {"funid": "func"},
                                "params": [
                                    {
                                        "pattern": {
                                            "tuple": [
                                                {
                                                    "pattern": {
                                                        "literal": {
                                                            "type": "int",
                                                            "value": "1",
                                                        }
                                                    }
                                                },
                                                {
                                                    "pattern": {
                                                        "literal": {
                                                            "type": "int",
                                                            "value": "2",
                                                        }
                                                    }
                                                },
                                                {"pattern": "wildcard"},
                                                {"pattern": {"funid": "xs"}},
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
                    "decl": {
                        "left": {"funid": "a"},
                        "right": {
                            "do": {
                                "stmts": [
                                    {
                                        "binding": {
                                            "left": [
                                                {
                                                    "expr": {
                                                        "tuple": [
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
                                                                        "value": "2",
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
                                                }
                                            ],
                                            "right": [{"expr": {"funid": "lol"}}],
                                        }
                                    },
                                    [
                                        {
                                            "binding": {
                                                "left": [
                                                    {
                                                        "expr": {
                                                            "tuple": [
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
                                                                            "value": "2",
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
                                                    }
                                                ],
                                                "right": [{"expr": {"funid": "lol"}}],
                                            }
                                        }
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