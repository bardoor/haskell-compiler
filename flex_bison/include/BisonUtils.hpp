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


void inline mk_literal(Node* node, std::string type, std::string literal) {
    LOG_PARSER("## PARSER ## making %s literal", type.c_str());

    node = new Node();
    node->val = {{
        "literal", {
            {"value", literal},
            {"type", type}
        }
    }};
}

void inline mk_typed_expr(Node* node, Node* expr, Node* type) {
    LOG_PARSER("## PARSER ## make expr - oexpr with type annotation\n"); 

    node = new Node(); 
    node->val = {{
        "expr_type", {
            {"expr", expr->val}, 
            {"type", type->val} 
    }}};
}

void inline mk_bin_expr(Node* node, Node* left, Node* op, Node* right) {
    LOG_PARSER("## PARSER ## make oexpr - oexpr op oexpr\n"); 

    node = new Node();
    node->val = {{
        "bin_expr", {
            {"left", left->val},
            {"op", op->val},
            {"right", right->val}
        }
    }};
}   

void inline mk_negate_expr(Node* node, Node* expr) {
    LOG_PARSER("## PARSER ## make oexpr - oexpr op oexpr\n"); 

    node = new Node();
    node->val = {{
        "expr", {{
            "uminus", expr->val
        }}
    }};
}

void inline mk_lambda(Node* node, Node* patterns, Node* body) {
    LOG_PARSER("## PARSER ## make kexpr - lambda\n"); 
    
    node = new Node(); 
    node->val = {{
        "lambda", {
            {"params", patterns->val}, 
            {"body", body->val} 
        }
    }};
}

void inline mk_let_in(Node* node, Node* decls, Node* expr) {
    LOG_PARSER("## PARSER ## make kexpr - LET .. IN ..\n");

    node = new Node();
    node->val = {{
        "let", {
            {"decls", decls->val},
            {"body", expr->val}
        }
    }};
}

void inline mk_if_else(Node* node, Node* condition, Node* true_branch, Node* false_branch) {
    LOG_PARSER("## PARSER ## make kexpr - IF .. THEN .. ELSE ..\n");

    node = new Node();
    node->val = {{
        "if_else", {
            {"cond", condition->val},
            {"true_branch", true_branch->val},
            {"false_branch", false_branch->val}
        }
    }};
}

void inline mk_do(Node* node, Node* stmts) {
    LOG_PARSER("## PARSER ## make kexpr - DO { stmts }");

    node = new Node();
    node->val = {{
        "do", {{
            "stmts", stmts->val
        }}
    }};
}

void inline mk_case(Node* node, Node* expr, Node* alts) {
    LOG_PARSER("## PARSER ## make kexpr - CASE .. OF .. \n");

    node = new Node();
    node->val = {{
        "case", {
            {"expr", expr->val},
            {"alts", alts->val}
        }
    }};
}

void inline mk_fapply(Node* node, Node* fapply, Node* expr) {
    if (expr == NULL) {
        LOG_PARSER("## PARSER ## make func apply - one expr\n");
        node = fapply;
        return;
    }

    LOG_PARSER("## PARSER ## made func apply - many exprs\n");

    if (fapply->val.is_array()) {
        fapply->val["func_apply"].push_back(expr->val);
        node = fapply;
    }
    else {
        node = new Node();
        node->val["func_apply"].push_back(fapply->val);
        node->val["func_apply"].push_back(expr->val);
    }
} 

void inline mk_expr(Node* node, Node* expr) {
    LOG_PARSER("## PARSER ## make expr\n");

    node = new Node();
    node->val = {{
        "expr", expr->val
    }};
}

void inline mk_expr(Node* node, std::string funid) {
    LOG_PARSER("## PARSER ## make expr - funid\n");

    node = new Node();
    node->val["expr"]["funid"] = funid;
}

void inline mk_operator(Node* node, std::string type, std::string repr) {
    LOG_PARSER("## PARSER ## make op\n");

    node = new Node();
    node->val = {
        {"type", type},
        {"repr", repr}
    };
}

void inline mk_stmts(Node* node, Node* stmt, Node* stmts) {
    node = new Node();

    if (stmts != NULL) {
        node->val = stmts->val;
    }
    node->val.push_back(stmt->val);        
}

void inline mk_binding_stmt(Node* node, Node* left, Node* right) {
    LOG_PARSER("## PARSER ## make stmt - expr <- expr;\n"); 

    node = new Node();
    node->val = {{
        "binding", {
            {"left", left->val},
            {"right", right->val}
        }
    }};
}

void inline mk_tuple(Node* node, Node* expr, Node* exprs) {
    node = new Node();
    
    // Создать пустой кортеж
    if (expr == NULL && exprs == NULL) {
        LOG_PARSER("## PARSER ## make tuple - ( )\n");
        node->val["tuple"] = json::array();
        return;
    }

    LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n");
    node->val["tuple"] = exprs->val;
    node->val["tuple"].push_back(expr->val);
}

void inline mk_list(Node* node, Node* exprs) {
    node = new Node();

    // Создать пустой список
    if (exprs == NULL) {
        LOG_PARSER("## PARSER ## make list - [ ]\n");
        node->val["list"] = json::array();
        return;
    }

    LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n");
    node->val["list"] = exprs->val;
}

void inline mk_comma_sep_exprs(Node* node, Node* expr, Node* exprs) {
    if (exprs == NULL) {
        LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); 

        node = new Node();
        node->val.push_back(expr->val);
        return;
    }

    node = exprs;
    node->val.insert(node->val.begin(), expr->val);
}

void inline mk_range(Node* node, Node* start, Node* snd, Node* end) {
    node = new Node();
    node->val["range"]["start"] = start->val;

    if (snd != NULL) {
        node->val["range"]["second"] = snd->val;
    }

    if (end != NULL) {
        node->val["range"]["end"] = end->val;
    }
}

void inline mk_var(Node* node, std::string type, std::string repr) {
    node = new Node();
    node->val["type"] = type;
    node->val["repr"] = repr;
}

void inline mk_simple_pat(Node* node, Node* pat) {
    LOG_PARSER("## PARSER ## make apat");

    node = new Node();
    node->val["pattern"] = pat->val;
}

void inline mk_simple_pat(Node* node, std::string val) {
    LOG_PARSER("## PARSER ## make apat");

    node = new Node();
    node->val["pattern"] = val;
}

void inline mk_list_pat(Node* node, Node* pats) {
    LOG_PARSER("## PARSER ## make apat - list");

    node = new Node();
    if (pats == NULL) {
        node->val["pattern"]["list"] = json::array();
        return;
    }
    node->val["pattern"] = pats->val;
}

void inline mk_tuple_pat(Node* node, Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make apat - tuple");

    node = new Node();
    node->val["pattern"]["tuple"] = json::array();

    if (pats != NULL && pat == NULL) {
        node->val["pattern"]["tuple"].push_back(pat->val);
        node->val["pattern"]["tuple"].insert(
            node->val["pattern"]["tuple"].begin(), 
            pats->val
            );
        return;
    }
}

void inline mk_pat_list(Node* node, Node* pats, Node* pat) {
    LOG_PARSER("## PARSER ## make pattern list");

    if (pats == NULL) {
       node = new Node();
       node->val.push_back(pat->val);
       return;
    }

    node = pats;
    node->val.push_back(pat->val);
}   

void inline mk_fpat(Node* node, Node* fpat, Node* pat) {
    LOG_PARSER("## PARSER ## make fpat");

    if (fpat->val.is_array()) {
        fpat->val["fpat"].push_back(pat->val);
        node = fpat;
    }
    else {
        node = new Node();
        node->val["fpat"].push_back(fpat->val);
        node->val["fpat"].push_back(pat->val);
    }
}

void inline mk_negate(Node* node, Node* pat) {
    LOG_PARSER("## PARSER ## make dpat");

    node = new Node();
    node->val["negate"] = pat->val;
}

void inline mk_bin_pat(Node* node, Node* left, Node* op, Node* right) {
    LOG_PARSER("## PARSER ## make bin pat");

    node = new Node();
    node->val = {
        {"left", left->val},
        {"op", op->val},
        {"right", right->val}
    };
}

void inline mk_pats(Node* node, Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make pats");
    
    if (pats->val.is_array()) {
        node = pats;
        node->val.push_back(pat->val);
        return;
    }

    node = new Node();
    node->val.push_back(pats->val);
    node->val.push_back(pat->val);
}

void inline mk_lambda_pats(Node* node, Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make lambda pats");

    if (pats->val.is_array()) {
        node = pats;
        node->val.push_back(pat->val);
        return;
    }

    node = new Node();
    node->val.push_back(pats->val);
    node->val.insert(node->val.begin(), pat->val);
}
