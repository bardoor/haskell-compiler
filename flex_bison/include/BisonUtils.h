#pragma once

#include <memory>
#include <vector>
#include <iostream>
#include <string>
#include "Parser.hpp"

struct Node {
public:
    Node() : id(nextId++) {} // убрано дублирующее присвоение id
    virtual std::string generateDot() = 0;
    virtual ~Node() = default;

protected:
    static int nextId;
    long long id;
};

int Node::nextId = 0; // инициализация статического члена nextId

struct Param : public Node {
public:
    Param(std::string& paramName) : name(paramName) {} // инициализация ссылки name

protected:
    std::string& name;
};

struct ParamList : public Node {
public:
    ParamList(std::vector<Param*>& parameters) : params(parameters) {} // инициализация params

protected:
    std::vector<Param*> params;
};

struct FuncDecl : public Node {
public:
    FuncDecl(std::string& functionName, ParamList* parametersList, Expr* funcBody)
        : name(functionName), paramList(parametersList), body(funcBody) {} // инициализация всех полей

protected:
    std::string& name;
    std::unique_ptr<ParamList> paramList;
    std::unique_ptr<Expr> body;
};

struct Module {
public:
    Module(FuncDecl* fDecl) : decl(fDecl) {} // инициализация decl

protected:
    FuncDecl* decl;
};

struct Expr {
    virtual ~Expr() = default;
};

struct BinaryExpr : public Expr {
    BinaryExpr(Expr* l, Expr* r) : left(l), right(r) {} // инициализация left и right
    Expr* left;
    Expr* right;
};

struct IntLiteral : public Expr {
    IntLiteral(long long v) : val(v) {} // инициализация val
    long long val;
};
