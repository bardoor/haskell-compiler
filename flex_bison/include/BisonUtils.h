#pragma once

#include <memory>
#include <vector>
#include <iostream>
#include <string>
#include "Parser.hpp"

struct Node {
public:
    Node() : id(nextId++) {}
    //virtual std::string generateDot() = 0;
    virtual ~Node() = default;

    static long long nextId;

protected:
    long long id;
};

struct Param : public Node {
public:
    Param(std::string paramName) : name(paramName) {} 

protected:
    std::string name;
};

struct ParamList : public Node {
public:
    ParamList() {} 
    //ParamList(std::vector<Param*>& parameters) : params(parameters) {} 

    void add(Param* param) {
        params.push_back(param);
    }

protected:
    std::vector<Param*> params;
};

struct FuncDecl : public Node {
public:
    FuncDecl(std::string functionName, ParamList* parametersList, Expr* funcBody)
        : name(functionName), paramList(parametersList), body(funcBody) {} 
protected:
    std::string name;
    std::unique_ptr<ParamList> paramList;
    std::unique_ptr<Expr> body;
};

struct Module {
public:
    Module(FuncDecl* fDecl) : decl(fDecl) {} 

protected:
    FuncDecl* decl;
};

struct Expr {
    virtual ~Expr() = default;
};

struct BinaryExpr : public Expr {
    BinaryExpr(Expr* l, Expr* r) : left(l), right(r) {} 
    Expr* left;
    Expr* right;
};

struct IntLiteral : public Expr {
    IntLiteral(long long v) : val(v) {} 
    long long val;
};
