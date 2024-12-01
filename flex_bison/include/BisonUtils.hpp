#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <iostream>

#include <json.hpp>

using json = nlohmann::json;

#define DEBUG_PARSER

#ifdef DEBUG_PARSER
    #define LOG_PARSER(msg, ...) printf(msg, ##__VA_ARGS__);
#else
    #define LOG_PARSER(msg, ...)
#endif



struct Node {
    json val; 
};



/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

/**
 * Создаёт узел списка добавлением в начало.
 * 
 * @param node[in] узел, добавляемый в начало
 * @param nodes[in] узел списка либо обычный узел, берётся за основу результирующего узла
 * @return новый узел списка
 */
inline Node* mk_node_list_prepend(Node* node, Node* nodes) {
    if (nodes->val.is_array()) {
        nodes->val.insert(nodes->val.begin(), node->val);
        return nodes;
    }

    Node* result = new Node();
    result->val.push_back(nodes->val);
    result->val.insert(result->val.begin(), node->val);
    return result;
}

/**
 * Создаёт узел списка добавлением в конец.
 * 
 * @param node[in] узел, добавляемый в конец
 * @param nodes[in] узел списка либо обычный узел, берётся за основу результирующего узла
 * @return новый узел списка
 */
inline Node* mk_node_list_append(Node* node, Node* nodes) {
    if (nodes->val.is_array()) {
        nodes->val.push_back(node->val);
        return nodes;
    }

    Node* result = new Node();
    result->val.push_back(nodes->val);
    result->val.push_back(node->val);
    return result;
}

inline Node* mk_literal(std::string type, std::string literal) {
    LOG_PARSER("## PARSER ## making %s literal\n", type.c_str());

    Node* node = new Node();
    node->val = {{
        "literal", {
            {"value", literal},
            {"type", type}
        }
    }};

    return node;
}

inline Node* mk_typed_expr(Node* expr, Node* type) {
    LOG_PARSER("## PARSER ## make expr - oexpr with type annotation\n"); 

    Node* node = new Node(); 
    node->val = {{
        "expr_type", {
            {"expr", expr->val}, 
            {"type", type->val} 
    }}};
    return node;
}

inline Node* mk_bin_expr(Node* left, Node* op, Node* right) {
    LOG_PARSER("## PARSER ## make oexpr - bin expr\n");

    Node* node = new Node();
    node->val = {{
        "expr", {
            {"left", left->val}, 
            {"op", op->val},
            {"right", right->val} 
        }
    }};
    return node;
}

inline Node* mk_negate_expr(Node* expr) {
    LOG_PARSER("## PARSER ## make oexpr - negate expr\n"); 

    Node* node = new Node();
    node->val = {{
        "expr", {{"uminus", expr->val}}
    }};
    return node;
}

inline Node* mk_lambda(Node* patterns, Node* body) {
    LOG_PARSER("## PARSER ## make kexpr - lambda\n"); 
    
    Node* node = new Node();
    node->val = {{
        "lambda", {
            {"params", patterns->val}, 
            {"body", body->val} 
        }
    }};
    return node;
}

inline Node* mk_let_in(Node* decls, Node* expr) {
    LOG_PARSER("## PARSER ## make kexpr - LET .. IN ..\n");

    Node* node = new Node();
    node->val = {{
        "let", {
            {"decls", decls->val},
            {"body", expr->val}
        }
    }};
    return node;
}

inline Node* mk_if_else(Node* condition, Node* true_branch, Node* false_branch) {
    LOG_PARSER("## PARSER ## make kexpr - IF .. THEN .. ELSE ..\n");

    Node* node = new Node();
    node->val = {{
        "if_else", {
            {"cond", condition->val},
            {"true_branch", true_branch->val},
            {"false_branch", false_branch->val}
        }
    }};
    return node;
}

inline Node* mk_do(Node* stmts) {
    LOG_PARSER("## PARSER ## make kexpr - DO { stmts }\n");

    Node* node = new Node();
    node->val = {{
        "do", {{"stmts", stmts->val}}
    }};
    return node;
}

inline Node* mk_case(Node* expr, Node* alts) {
    LOG_PARSER("## PARSER ## make kexpr - CASE .. OF .. \n");

    Node* node = new Node();
    node->val = {{
        "case", {
            {"expr", expr->val},
            {"alts", alts->val}
        }
    }};
    return node;
}

inline Node* mk_fapply(Node* fapply, Node* expr) {
    if (expr == NULL) {
        LOG_PARSER("## PARSER ## make func apply - one expr\n");
        return fapply;
    }

    LOG_PARSER("## PARSER ## made func apply - many exprs\n");

    return mk_node_list_append(expr, fapply);
}

inline Node* mk_expr(Node* expr) {
    LOG_PARSER("## PARSER ## make expr\n");

    std::cout << expr << std::endl;

    Node* node = new Node();
    node->val = {{"expr", expr->val}};
    return node;
}

inline Node* mk_expr(std::string funid) {
    LOG_PARSER("## PARSER ## make expr - funid\n");

    Node* node = new Node();
    node->val["expr"]["funid"] = funid;
    return node;
}

inline Node* mk_operator(std::string type, std::string repr) {
    LOG_PARSER("## PARSER ## make op\n");

    Node* node = new Node();
    node->val = {
        {"type", type},
        {"repr", repr}
    };
    return node;
}

inline Node* mk_stmts(Node* stmt, Node* stmts) {
    Node* node = new Node();

    if (stmts != NULL) {
        node->val = stmts->val;
    }
    node->val.push_back(stmt->val);        
    return node;
}

inline Node* mk_binding_stmt(Node* left, Node* right) {
    LOG_PARSER("## PARSER ## make stmt - expr <- expr;\n"); 

    Node* node = new Node();
    node->val = {{
        "binding", {
            {"left", left->val},
            {"right", right->val}
        }
    }};
    return node;
}

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

inline Node* mk_tuple(Node* expr, Node* exprs) {
    Node* node = new Node();
    
    // Создать пустой кортеж
    if (expr == NULL && exprs == NULL) {
        LOG_PARSER("## PARSER ## make tuple - ( )\n");
        node->val["tuple"] = json::array();
        return node;
    }

    LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n");
    node->val["tuple"] = exprs->val;
    node->val["tuple"].push_back(expr->val);
    return node;
}

inline Node* mk_list(Node* exprs) {
    Node* node = new Node();

    // Создать пустой список
    if (exprs == NULL) {
        LOG_PARSER("## PARSER ## make list - [ ]\n");
        node->val["list"] = json::array();
        return node;
    }

    LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n");
    node->val["list"] = exprs->val;
    return node;
}

inline Node* mk_comma_sep_exprs(Node* expr, Node* exprs) {
    if (exprs == NULL) {
        LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); 

        Node* node = new Node();
        node->val.push_back(expr->val);
        return node;
    }

    exprs->val.insert(exprs->val.begin(), expr->val);
    return exprs;
}

inline Node* mk_range(Node* start, Node* snd, Node* end) {
    Node* node = new Node();
    node->val["range"]["start"] = start->val;

    if (snd != NULL) {
        node->val["range"]["second"] = snd->val;
    }

    if (end != NULL) {
        node->val["range"]["end"] = end->val;
    }
    return node;
}

inline Node* mk_var(std::string type, std::string repr) {
    Node* node = new Node();
    node->val["type"] = type;
    node->val["repr"] = repr;
    return node;
}

/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

inline Node* mk_simple_pat(Node* pat) {
    LOG_PARSER("## PARSER ## make apat");

    Node* node = new Node();
    node->val["pattern"] = pat->val;
    return node;
}

inline Node* mk_simple_pat(const std::string& val) {
    LOG_PARSER("## PARSER ## make apat");

    Node* node = new Node();
    node->val["pattern"] = val;
    return node;
}

inline Node* mk_list_pat(Node* pats) {
    LOG_PARSER("## PARSER ## make apat - list");

    Node* node = new Node();
    if (pats == NULL) {
        node->val["pattern"]["list"] = json::array();
        return node;
    }
    node->val["pattern"] = pats->val;
    return node;
}

inline Node* mk_tuple_pat(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make apat - tuple");

    Node* node = new Node();
    node->val["pattern"]["tuple"] = json::array();

    if (pats != NULL && pat != NULL) {
        node->val["pattern"]["tuple"].push_back(pat->val);
        node->val["pattern"]["tuple"].insert(
            node->val["pattern"]["tuple"].begin(), 
            pats->val
        );
    }
    return node;
}

inline Node* mk_pat_list(Node* pats, Node* pat) {
    LOG_PARSER("## PARSER ## make pattern list");

    if (pats == NULL) {
        Node* node = new Node();
        node->val.push_back(pat->val);
        return node;
    }

    pats->val.push_back(pat->val);
    return pats;
}

inline Node* mk_fpat(Node* fpat, Node* pat) {
    LOG_PARSER("## PARSER ## make fpat");

    if (fpat->val.is_array()) {
        fpat->val["fpat"].push_back(pat->val);
        return fpat;
    }

    Node* node = new Node();
    node->val["fpat"].push_back(fpat->val);
    node->val["fpat"].push_back(pat->val);
    return node;
}

inline Node* mk_negate(Node* pat) {
    LOG_PARSER("## PARSER ## make dpat");

    Node* node = new Node();
    node->val["negate"] = pat->val;
    return node;
}

inline Node* mk_bin_pat(Node* left, Node* op, Node* right) {
    LOG_PARSER("## PARSER ## make bin pat");

    Node* node = new Node();
    node->val = {
        {"left", left->val},
        {"op", op->val},
        {"right", right->val}
    };
    return node;
}

inline Node* mk_pats(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make pats");
    
    return mk_node_list_append(pat, pats);
}

inline Node* mk_lambda_pats(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make lambda pats");

    return mk_node_list_prepend(pat, pats);
}

/* ------------------------------- *
 *           Объявления            *
 * ------------------------------- */

inline Node* mk_fun_decl(Node* left, Node* right) {
    LOG_PARSER("## PARSER ## make fun decl");

    Node* node = new Node();
    node->val = {{
        "fun_decl", {
            {"left", left->val},
            {"right", right->val}
        }
    }};
    return node;
}

inline Node* mk_typed_var_list(Node* vars, Node* type) {
    LOG_PARSER("## PARSER ## make typed var list");

    Node* node = new Node();
    node->val = {
        {"vars", vars->val},
        {"type", type->val}
    };
    return node;
}

inline Node* mk_typed_var_list(Node* vars, Node* context, Node* type) {
    LOG_PARSER("## PARSER ## make typed var list with context");

    Node* node = new Node();
    node->val = {
        {"vars", vars->val},
        {"context", context->val},
        {"type", type->val}
    };
    return node;
}

inline Node* mk_empty_decl() {
    LOG_PARSER("## PARSER ## make empty decl");

    Node* node = new Node();
    node->val["decl"] = json::object();
    return node;
}

inline Node* mk_where(Node* decls) {
    LOG_PARSER("## PARSER ## make where");

    Node* node = new Node();
    if (decls != NULL) {
        node->val["where"]["decls"] = decls->val;
    }
    return node;
}

inline Node* mk_funlhs(Node* name, Node* params) {
    LOG_PARSER("## PARSER ## make funlhs");

    Node* node = new Node();
    node->val["funlhs"] = {
        {"name", name->val},
        {"params", params->val}
    };
    return node;
}

inline Node* mk_decl_list(Node* decls, Node* decl) {
    LOG_PARSER("## PARSER ## make decl list");

    return mk_node_list_append(decl, decls);
}

inline Node* mk_con(Node* con) {
    LOG_PARSER("## PARSER ## make con");

    Node* node = new Node();
    node->val["con"] = con->val;
    return node;
}

inline Node* mk_con_list(Node* cons, Node* con) {
    LOG_PARSER("## PARSER ## make con list");

    return mk_node_list_append(con, cons);
}

inline Node* mk_var_list(Node* vars, Node* var) {
    LOG_PARSER("## PARSER ## make var list");

    return mk_node_list_append(var, vars);
}

