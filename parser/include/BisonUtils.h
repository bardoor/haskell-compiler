#include <memory>
#include <vector>
#include <iostream>

enum Tokens {
    WHEREKW = 1, 
    FUNC_ID = 2, 
    CONSTRUCT_ID = 3, 
    INTC = 4, 
    MODULEKW = 5
};

class FunDecl {};
class Expr {};

class Module {
protected:
    std::vector<FunDecl> funDecls;
};

class BinaryExpr : public Expr {
protected:
    std::unique_ptr<Expr> left;
    std::unique_ptr<Expr> right;
};

class BinaryPlusExpr : public BinaryExpr {};

class NumbericLiteral : public Expr {
protected:
    long long value;
};

