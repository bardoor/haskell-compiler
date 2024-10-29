%language "C++"
%defines
%locations

%{
#include <BisonUtils.h>

extern int yylex();
extern int yylineno;
void yyerror(const char* s);
%}

%union {
    long long val;
    Expr* expr;
}

%type <val> INTC;
%type <expr> expr;

%token FUNC_ID INTC MODULEKW CONSTRUCT_ID WHEREKW

%%
expr : INTC { $$ = new NumericLiteral($1); }
     | expr '+' expr { 
        $$ = new BinaryExpr($1, $3); 
        std::cout << "Add result: " << $$ << std::endl; }
     ;

%%
void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
