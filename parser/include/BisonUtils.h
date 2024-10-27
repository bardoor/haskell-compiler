#include <memory>
#include <vector>


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
