import tools

class Tree:
    def __init__(self, code: str):
        __root_node = self.from_code(code)

    def from_code(self, code: str):
        match tools.parse_to_dict(str):
            case ('ok', tree):
                return from_dict(tree)
            case ('error', reason):
                raise RuntimeError(reason)

    def from_dict(self, source):
        # Ну а что нам остаётся?
        # Славным трём богатырям
        # Кончились деньки господства
        # Ветки case писать пора
        node = None

        match source:
            case {'module': body, 'name': 0}:
                node = Module()
                node["name"] = ""
                node["body"] = self.from_dict(body, self.__root_node)
            case {'decls': decls}:
                node = Decls()
                for i, decl in enumerate(decls):
                    node[i] = self.from_dict(decl)
            case {'decl': [{'left': left}, {'right': right}]}:
                node = FunDecl()
                node['left']

        return node
            

print(tools.parse_to_dict("{ b = a + 1; }"))
