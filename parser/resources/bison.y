%{
#include parser.h
#include <iostream>

extern int yylex();
extern int yylineno;

%}

%union {
    long long val;
    std::unique_ptr<BinaryExpr> bin_expr;
}

%start module

%type <bin_expr> expr
%type <val> INTC

%token FUNC_ID INTC MODULEKW CONSTRUCT_ID WHEREKW

%%
module : MODULEKW CONSTRUCT_ID WHEREKW funcList
       ;

funcList : funcDecl
         : funcList funcDecl
         ;

funcDecl : FUNC_ID '=' expr
         ;

expr : INTC '+' INTC { $$ = $1 + $3; std::cout << "Add result: " << $$ << std::endl; }
     ;


%%
void yyerror(const char *s) {
    cerr << "Error: " << s << " on line " << yylineno << endl;
}

int main() {
    yyparse(); 
    return 0;
}