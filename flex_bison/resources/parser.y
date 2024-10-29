%require "3.2"
%locations

%{
#include <BisonUtils.h>

Module* root;

extern int yylex();
extern int yylineno;

void yyerror(const char* s);
%}

%union {
    long long intVal;
    const char* str;
    struct Expression* expr;
    struct Module* module;
}

%start module

%type <expr> expr;
%type <module> module;

%token FUNC_ID INTC MODULEKW CONSTRUCT_ID WHEREKW

%%
module : expr { $$ = root = new Module($1); }
       ;

expr : INTC { $$ = new NumericLiteral(intc); }
     | expr '+' expr { $$ = new BinaryExpr($1, $3);  }
     ;

%%
void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
