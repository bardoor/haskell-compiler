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
    node->val["left"] = left->val.is_array() ? left->val[0] : left->val;
    node->val["right"] = right->val.is_array() ? right->val[0] : right->val;
    node->val["op"] = op->val;

    return node;
}

inline Node* mk_negate_expr(Node* expr) {
    LOG_PARSER("## PARSER ## make oexpr - negate expr\n"); 

    Node* node = new Node();
    node->val =  {{"uminus", expr->val}};
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

    node->val["if"]["cond"] = condition->val.is_array() ? condition->val[0] : condition->val;
    node->val["if"]["then"] = true_branch->val;
    node->val["if"]["else"] = false_branch->val;

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

    Node* node = new Node();
    node->val = expr->val;
    return node;
}

inline Node* mk_expr(std::string funid) {
    LOG_PARSER("## PARSER ## make expr - funid\n");

    Node* node = new Node();
    node->val["funid"] = funid;
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

inline Node* mk_comma_sep_stmts(Node* stmt, Node* stmts) {
    if (stmts == NULL) {
        LOG_PARSER("## PARSER ## make commaSepStmts - stmt\n"); 

        Node* node = new Node();
        node->val.push_back(stmt->val);
        return node;
    }

    stmts->val.insert(stmts->val.begin(), stmt->val);
    return stmts;
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

inline Node* mk_comprehension(Node* expr, Node* generators) {
    Node* node = new Node();

    node->val["head"] = expr->val;
    node->val["generators"] = generators->val;

    return node;
}

/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

inline Node* mk_simple_pat(Node* pat) {
    LOG_PARSER("## PARSER ## make apat\n");

    Node* node = new Node();
    node->val["pattern"] = pat->val;
    return node;
}

inline Node* mk_simple_pat(const std::string& val) {
    LOG_PARSER("## PARSER ## make apat\n");

    Node* node = new Node();
    node->val["pattern"] = val;
    return node;
}

inline Node* mk_list_pat(Node* pats) {
    LOG_PARSER("## PARSER ## make apat - list\n");

    Node* node = new Node();
    if (pats == NULL) {
        node->val["pattern"]["list"] = json::array();
        return node;
    }
    node->val["pattern"] = pats->val;
    return node;
}

inline Node* mk_tuple_pat(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make apat - tuple\n");

    Node* node = new Node();

    if (pats == NULL && pat == NULL) {
        node->val["pattern"]["tuple"] = json::array();
        return node;
    }

    node->val["pattern"]["tuple"] = json::array();

    if (pat != NULL) {
        node->val["pattern"]["tuple"].push_back(pat->val);
    }

    if (pats != NULL) {
        if (pats->val.is_array()) {
            for (auto& p : pats->val) {
                node->val["pattern"]["tuple"].push_back(p);
            }
        } else {
            node->val["pattern"]["tuple"].push_back(pats->val);
        }
    }

    return node;
}

inline Node* mk_pat_list(Node* pats, Node* pat) {
    LOG_PARSER("## PARSER ## make pattern list\n");

    if (pats == NULL) {
        Node* node = new Node();
        node->val.push_back(pat->val);
        return node;
    }

    pats->val.push_back(pat->val);
    return pats;
}

inline Node* mk_fpat(Node* fpat, Node* pat) {
    LOG_PARSER("## PARSER ## make fpat\n");

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
    LOG_PARSER("## PARSER ## make dpat\n");

    Node* node = new Node();
    node->val["negate"] = pat->val;
    return node;
}

inline Node* mk_bin_pat(Node* left, Node* op, Node* right) {
    LOG_PARSER("## PARSER ## make bin pat\n");

    Node* node = new Node();
    node->val["left"] = left->val.is_array() ? left->val[0] : left->val;
    node->val["right"] = right->val.is_array() ? right->val[0] : right->val;
    node->val["op"] = op->val;
    
    return node;
}

inline Node* mk_pats(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make pats\n");
    
    return mk_node_list_append(pat, pats);
}

inline Node* mk_lambda_pats(Node* pat, Node* pats) {
    LOG_PARSER("## PARSER ## make lambda pats\n");

    return mk_node_list_prepend(pat, pats);
}

/* ------------------------------- *
 *           Объявления            *
 * ------------------------------- */

inline Node* mk_fun_decl(Node* left, Node* right) {
    LOG_PARSER("## PARSER ## make fun decl\n");

    Node* node = new Node();
    node->val["fun_decl"] = {
        {"left", left->val}
    };

    if (right->val.contains("valrhs1")) {
        node->val["fun_decl"]["right"] = right->val["valrhs1"];
    } else {
        node->val["fun_decl"]["right"] = right->val;
    }

    return node;
}

inline Node* mk_typed_var_list(Node* vars, Node* type) {
    LOG_PARSER("## PARSER ## make typed var list\n");

    Node* node = new Node();
    node->val = {
        {"vars", vars->val},
        {"type", type->val}
    };
    return node;
}

inline Node* mk_typed_var_list(Node* vars, Node* context, Node* type) {
    LOG_PARSER("## PARSER ## make typed var list with context\n");

    Node* node = new Node();
    node->val = {
        {"vars", vars->val},
        {"context", context->val},
        {"type", type->val}
    };
    return node;
}

inline Node* mk_empty_decl() {
    LOG_PARSER("## PARSER ## make empty decl\n");

    Node* node = new Node();
    node->val["decl"] = json::object();
    return node;
}

inline Node* mk_where(Node* decls) {
    LOG_PARSER("## PARSER ## make where\n");

    Node* node = new Node();
    if (decls != NULL) {
        node->val["where"]["decls"] = decls->val;
    }
    return node;
}

inline Node* mk_funlhs(Node* name, Node* params) {
    LOG_PARSER("## PARSER ## make funlhs\n");

    Node* node = new Node();
    node->val["funlhs"] = {
        {"name", name->val},
        {"params", params->val}
    };
    return node;
}

inline Node* mk_decl_list(Node* decls, Node* decl) {
    LOG_PARSER("## PARSER ## make decl list\n");

    return mk_node_list_append(decl, decls);
}

inline Node* mk_con(Node* con) {
    LOG_PARSER("## PARSER ## make con\n");

    Node* node = new Node();
    node->val["con"] = con->val;
    return node;
}

inline Node* mk_con_list(Node* cons, Node* con) {
    LOG_PARSER("## PARSER ## make con list\n");

    return mk_node_list_append(con, cons);
}

inline Node* mk_var_list(Node* vars, Node* var) {
    LOG_PARSER("## PARSER ## make var list\n");

    return mk_node_list_append(var, vars);
}

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

inline Node* mk_module(std::string name, Node* decls) {
    LOG_PARSER("## PARSER ## make module\n");

    Node* node = new Node();
    node->val = {{
        "module", {
            {"name", name},
            {"decls", decls->val}
        }
    }};

    return node;
}

inline Node* mk_module(Node* decls) {
    LOG_PARSER("## PARSER ## make module\n");

    Node* node = new Node();
    node->val["module"]["decls"] = decls->val;
    return node;
}

inline Node* mk_top_decl_list(Node* decl) {
    LOG_PARSER("## PARSER ## make top decl list\n");

    Node* node = new Node();
    node->val = json::array();
    node->val.push_back(decl->val);
    return node;
}

inline Node* mk_top_decl_list(Node* decls, Node* decl) {
    LOG_PARSER("## PARSER ## make top decl list\n");

    if (decls->val.is_array()) {
        decls->val += decl->val;
        return decls;
    }

    Node* node = new Node();
    node->val = { decls->val, decl->val };
    return node;
}

inline Node* mk_class_decl(Node* context, Node* classNode, Node* body) {
    LOG_PARSER("## PARSER ## make classDecl\n");

    Node* node = new Node(); 
    if (context) {
        node->val = {
            {"class_decl", {
                {"context", context->val},
                {"class", classNode->val},
                {"body", body->val}
            }}
        };
    } else {
        node->val = {
            {"class_decl", {
                {"class", classNode->val},
                {"body", body->val}
            }}
        };
    }
    return node;
}

inline Node* mk_class_body_empty() {
    LOG_PARSER("## PARSER ## make classBody - nothing\n");

    Node* node = new Node(); 
    node->val = nullptr;
    return node;
}

inline Node* mk_class_body_declList(Node* decls) {
    LOG_PARSER("## PARSER ## make classBody - WHERE { declList }\n");

    Node* node = new Node(); 
    node->val = decls->val;
    return node;
}

inline Node* mk_context_list(Node* contextList) {
    LOG_PARSER("## PARSER ## make context - (contextList)\n");

    Node* node = new Node(); 
    node->val = contextList->val;
    return node;
}

inline Node* mk_context_class(Node* classNode) {
    LOG_PARSER("## PARSER ## make context - class\n");

    Node* node = new Node(); 
    node->val = classNode->val;
    return node;
}

inline Node* mk_inst_decl_restrict(Node* context, std::string tycon, Node* restrictInst, Node* rinstOpt) {
    LOG_PARSER("## PARSER ## make instDecl - INSTANCE context => tycon restrictInst rinstOpt\n");

    Node* node = new Node();
    node->val = {
        {"inst_decl", {
            {"context", context->val},
            {"tycon", tycon},
            {"restrictInst", restrictInst->val},
            {"rinstOpt", rinstOpt->val}
        }}
    };
    return node;
}

inline Node* mk_inst_decl_general(std::string tycon, Node* generalInst, Node* rinstOpt) {
    LOG_PARSER("## PARSER ## make instDecl - INSTANCE tycon generalInst rinstOpt\n");

    Node* node = new Node();
    node->val = {
        {"inst_decl", {
            {"tycon", tycon},
            {"generalInst", generalInst->val},
            {"rinstOpt", rinstOpt->val}
        }}
    };
    return node;
}

inline Node* mk_class(std::string tycon, Node* tyvar) {
    LOG_PARSER("## PARSER ## make class - tycon tyvar\n");

    Node* node = new Node(); 
    node->val = {
        {"tycon", tycon}, 
        {"tyvar", tyvar->val}  
    };
    return node;
}

inline Node* mk_rinst_opt_empty() {
    LOG_PARSER("## PARSER ## make rinstOpt - nothing\n");

    Node* node = new Node();
    node->val = {{"rinstOpt", nullptr}};
    return node;
}

inline Node* mk_rinst_opt(Node* valDefList) {
    LOG_PARSER("## PARSER ## make rinstOpt - WHERE { valDefList }\n");

    Node* node = new Node();
    node->val = {{"rinstOpt", valDefList->val}};
    return node;
}

inline Node* mk_val_def(Node* opat, Node* valrhs) {
    LOG_PARSER("## PARSER ## make valDef - opat valrhs\n");

    Node* node = new Node();
    node->val = {{"valDef", {{"opat", opat->val}, {"valrhs", valrhs->val}}}};
    return node;
}

inline Node* mk_val_rhs(Node* valrhs1, Node* whereOpt) {
    LOG_PARSER("## PARSER ## make valrhs - valrhs1 whereOpt\n");

    Node* node = new Node();

    node->val = valrhs1->val;
    if (whereOpt != NULL) {
        node->val["where"] = whereOpt->val;
    }
    return node;
}

inline Node* mk_val_rhs1_guardrhs(Node* guardrhs) {
    LOG_PARSER("## PARSER ## make valrhs1 - guardrhs\n");

    Node* node = new Node();
    node->val = {{"valrhs1", {{"guardrhs", guardrhs->val}}}};
    return node;
}

inline Node* mk_val_rhs1_expr(Node* expr) {
    LOG_PARSER("## PARSER ## make valrhs1 - = expr\n");

    Node* node = new Node();
    node->val = {{"valrhs1", expr->val}};
    return node;
}


inline Node* mk_tyvar(std::string funid) {
    LOG_PARSER("## PARSER ## make tyvar - funid\n");

    Node* node = new Node(); 
    node->val["funid"] = funid;
    return node;
}

inline Node* mk_constr_list(Node* constrList, Node* constr){
    if (constrList == NULL) {
        LOG_PARSER("## PARSER ## make constrList - constr\n");
        return constr;
    }

     LOG_PARSER("## PARSER ## make constrList - constrList | constr\n");

    return mk_node_list_append(constr, constrList);
}