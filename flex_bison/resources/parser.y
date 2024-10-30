%require "3.2"
%locations

%{
#include <BisonUtils.h>
long long Node::nextId = 0;

Module* root;

extern int yylex();
extern int yylineno;

#define DEBUG_PARSER

#ifdef DEBUG_PARSER
    #define LOG_PARSER(msg, ...) printf(msg, ##__VA_ARGS__);
#else
    #define LOG_PARSER(msg, ...)
#endif

void yyerror(const char* s);
%}

%union {
    long long intVal;
    long double floatVal;
    const char* str;
    struct Expr* expr;
    struct Module* module;
    struct FuncDecl* funcDecl;
    struct Param* param;
    struct ParamList* paramList;
}

%left '+' '-'

%start module

%type <expr> expr;
%type <module> module;
%type <param> param;
%type <funcDecl> funcDecl;
%type <paramList> paramList paramListE;

%token <intVal> INTC
%token <floatVal> FLOATC
%token <str> FUNC_ID

%%
module : funcDecl { $$ = root = new Module($1); LOG_PARSER("## PARSER ## made Module\n"); }
       ;

funcDecl : FUNC_ID paramListE '=' expr { $$ = new FuncDecl($1, $2, $4); LOG_PARSER("## PARSER ## made funcDecl\n"); }
         ;

param : FUNC_ID { $$ = new Param(std::string($1)); LOG_PARSER("## PARSER ## made param\n"); }
      ;

paramList : param            { $$ = new ParamList(); LOG_PARSER("## PARSER ## made paramList\n"); }
          | paramList param  { $1->add($2); $$ = $1; LOG_PARSER("## PARSER ## add to paramList\n"); }
          ;

paramListE : /* nothing */   { $$ = new ParamList(); LOG_PARSER("## PARSER ## made empty paramListE\n"); }
           | paramList       { $$ = $1; LOG_PARSER("## PARSER ## made not empty paramListE\n"); }
           ;

expr : INTC          { $$ = new IntLiteral($1); LOG_PARSER("## PARSER ## made IntLiteral\n"); }
     | FLOATC        { $$ = new FloatLiteral($1); LOG_PARSER("## PARSER ## made FloatLiteral\n"); }
     | expr '+' expr { $$ = new BinaryExpr($1, $3); LOG_PARSER("## PARSER ## made BinaryExpr\n"); }
     ;

%%

void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}

std::string generateDot(Module* root) {
    std::stringstream ss;
    ss << "digraph AST {\n";
    if (root) {
        ss << root->generateDot();
    }
    ss << "}\n";
    return ss.str();
}
