#pragma once

#include <memory>
#include <vector>
#include <iostream>
#include <string>
#include "Parser.hpp"

struct Node {
public:
    Node() : id(nextId++) { id = nextId; }
    virtual std::string generateDot() = 0;
    virtual ~Node() = default;
    
protected:
    static int nextId;
    long long id;
};

struct Param : public Node {

};

struct ParamList : public Node {
public:
    ParamList(std::vector<Param*>& parameters) {
        params = parameters;
    }

protected:
    std::vector<Param*> params;
};


struct FuncDecl {
public:
    FuncDecl(std::string& functionName, ParamList* parametersList) {
        name = functionName;
        paramList = std::unique_ptr<ParamList>(parametersList);
    }

protected:
    std::string& name;
    std::unique_ptr<ParamList> paramList;
};

struct Module {
    Module(Expression* e) {
        expr = e;
    }
    
    Expression* expr;
};

struct Expression {
    virtual ~Expression() = default;
};

struct BinaryExpr : public Expression {
    BinaryExpr(Expression* l, Expression* r) : left(l), right(r) {}
    Expression* left;
    Expression* right;
};

struct NumericLiteral : public Expression {
    NumericLiteral(long long v) : val(v) {}
    long long val;
};


