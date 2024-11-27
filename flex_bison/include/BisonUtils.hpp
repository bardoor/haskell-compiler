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

void inline mk_operator(Node* node, std::string type, std::string repr) {
    LOG_PARSER("## PARSER ## make op\n");

    node = new Node();
    node->val = {
        {"type", type},
        {"repr", repr}
    };
}
