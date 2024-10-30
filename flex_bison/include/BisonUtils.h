#pragma once

#include <memory>
#include <vector>
#include <iostream>
#include <string>
#include <sstream>
#include <stdio.h>
#include "Parser.hpp"

// TODO: class, type, typeclass, newtype, where, let, string, char, guards, pattern matching, data constructors, op create, 
struct Node {
public:
    Node() : id(nextId++) {}

    virtual std::string generateDot() = 0;

    virtual ~Node() = default;

    long long getId() const { return id; }

    static long long nextId;

protected:
    long long id;
};

struct Expr : public Node {
    virtual ~Expr() = default;
};

struct Param : public Node {
public:
    Param(std::string paramName) : name(paramName) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"" << name << "\", shape=ellipse];\n";
        return ss.str();
    }

protected:
    std::string name;
};

struct ParamList : public Node {
public:
    ParamList() {}

    void add(Param* param) {
        params.push_back(std::unique_ptr<Param>(param));
    }

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"ParamList\", shape=box];\n";
        for (auto& param : params) {
            ss << param->generateDot();
            ss << "    node" << getId() << " -> node" << param->getId() << ";\n";
        }
        return ss.str();
    }

protected:
    std::vector<std::unique_ptr<Param>> params;
};

struct FuncDecl : public Node {
public:
    FuncDecl(std::string functionName, ParamList* parametersList, Expr* funcBody)
        : name(functionName), paramList(parametersList), body(funcBody) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"Function: " << name << "\", shape=box];\n";
        ss << paramList->generateDot();
        ss << "    node" << getId() << " -> node" << paramList->getId() << ";\n";
        if (body) {
            ss << body->generateDot();
            ss << "    node" << getId() << " -> node" << body->getId() << ";\n";
        }
        return ss.str();
    }

protected:
    std::string name;
    std::unique_ptr<ParamList> paramList;
    std::unique_ptr<Expr> body;
};

struct Module : public Node {
public:
    Module(FuncDecl* fDecl) {
        decl = std::unique_ptr<FuncDecl>(fDecl);
    }

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"Module\", shape=folder];\n";
        if (decl) {
            ss << decl->generateDot();
            ss << "    node" << getId() << " -> node" << decl->getId() << ";\n";
        }
        return ss.str();
    }

protected:
    std::unique_ptr<FuncDecl> decl;
};

struct BinaryExpr : public Expr {
public:
    BinaryExpr(Expr* l, Expr* r) {
        left = std::unique_ptr<Expr>(l);
        right = std::unique_ptr<Expr>(r);
    }

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"BinaryExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }

protected:
    std::unique_ptr<Expr> left;
    std::unique_ptr<Expr> right;
};

struct AddExpr : public BinaryExpr {
    AddExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"AddExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct SubExpr : public BinaryExpr {
    SubExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"Substract\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct MulExpr : public BinaryExpr {
    MulExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"Multiply\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct DivExpr : public BinaryExpr {
    DivExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"Division\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct AndExpr : public BinaryExpr {
    AndExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"AndExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct OrExpr : public BinaryExpr {
    OrExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"OrExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct EqualExpr : public BinaryExpr {
    EqualExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"EqualExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct NotEqualExpr : public BinaryExpr {
    NotEqualExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"NotEqualExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct LessThanExpr : public BinaryExpr {
    LessThanExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"LessThanExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct GreaterThanExpr : public BinaryExpr {
    GreaterThanExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"GreaterThanExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct LessExpr : public BinaryExpr {
    LessExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"LessExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};

struct GreaterExpr : public BinaryExpr {
    GreaterExpr(Expr* l, Expr* r) : BinaryExpr(l, r) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"GreaterExpr\", shape=diamond];\n";
        if (left) {
            ss << left->generateDot();
            ss << "    node" << getId() << " -> node" << left->getId() << " [label=\"left\"];\n";
        }
        if (right) {
            ss << right->generateDot();
            ss << "    node" << getId() << " -> node" << right->getId() << " [label=\"right\"];\n";
        }
        return ss.str();
    }
};


struct IntLiteral : public Expr {
public:
    IntLiteral(long long v) : val(v) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"IntLiteral: " << val << "\", shape=ellipse];\n";
        return ss.str();
    }

protected:
    long long val;
};

struct FloatLiteral : public Expr {
public:
    FloatLiteral(long double v) : val(v) {}

    std::string generateDot() override {
        std::stringstream ss;
        ss << "    node" << getId() << " [label=\"FloatLiteral: " << val << "\", shape=ellipse];\n";
        return ss.str();
    }

protected:
    long double val;
};

struct UnaryExpr : public Expr {
public:
    UnaryExpr(Expr* exp) {
        expr = std::unique_ptr<Expr>(exp);
    }

protected:
    std::unique_ptr<Expr> expr;
};

struct NotExpr : public UnaryExpr {
public:
    std::string generateDot() override {
        std::stringstream ss;
        ss << expr->generateDot();
        ss << "    node" << getId() << " [label=\"NotExpr\", shape=ellipse];\n";
        ss << "    node" << getId() << " -> node" << expr->getId() << " ;\n";

        return ss.str();
    }
};

struct NegateExpr : public UnaryExpr {
public:
    std::string generateDot() override {
        std::stringstream ss;
        ss << expr->generateDot();
        ss << "    node" << getId() << " [label=\"NegateExpr\", shape=ellipse];\n";
        ss << "    node" << getId() << " -> node" << expr->getId() << " ;\n";

        return ss.str();
    }
};


std::string generateDot(Module* root);
