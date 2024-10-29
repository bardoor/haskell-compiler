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
    struct Expr* expr;
    struct Module* module;
    struct FuncDecl* funcDecl;
    struct Param* param;
    struct ParamList* paramList;
}

%start module

%type <expr> expr;
%type <module> module;
%type <param> param;

%token <intVal> INTC
%token <str> FUNC_ID

%%
module : funcDecl { $$ = root = new Module($1); }
       ;

funcDecl : FUNC_ID paramListE '=' expr { $$ = new FuncDecl($1, $2, $4); }
         ;

param : FUNC_ID { $$ = new Param($1); }
      ;

paramList : param            { $$ = new ParamList(); }
          | paramList param  { $1->add($2); $$ = $1; }
          ;

paramListE : /* nothing */   { $$ = new ParamList(); }
           | paramList       { $$ = $1; }
           ;

expr : INTC { $$ = new IntLiteral(intc); }
     | expr '+' expr { $$ = new BinaryExpr($1, $3);  }
     ;

%%
void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
