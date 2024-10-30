#pragma once

#include <memory>
#include <vector>
#include <iostream>
#include <string>
#include <stdio.h>
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

struct Module : public Node {
public:
    Module(FuncDecl* fDecl) {
        decl = std::unique_ptr<FuncDecl>(fDecl);
    }

protected:
    std::unique_ptr<FuncDecl> decl;
};

struct Expr : public Node {
    virtual ~Expr() = default;
};

struct BinaryExpr : public Expr {
public:    
    BinaryExpr(Expr* l, Expr* r) {
        left = std::unique_ptr<Expr>(l);
        right = std::unique_ptr<Expr>(r);
    }

protected:
    std::unique_ptr<Expr> left;
    std::unique_ptr<Expr> right;
};

struct IntLiteral : public Expr {
public:
    IntLiteral(long long v) : val(v) {} 

protected:
    long long val;
};
