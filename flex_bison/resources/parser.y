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

%right '$' SEQOP STRICTAPPLY
%right OR
%right AND
%left FMAPOP APPLYFUNCTOR
%nonassoc '<' '>' EQ NEQ GE LE
%right ':' CONCAT
%left '+' '-'
%left '/' '*' DIVOP MODOP QUOTOP REMOP
%right '^'
%left INDEXING
%right '.'
%right NOT NEGATE
%left FUNC_APPLY

%type <expr> expr;
%type <module> module;
%type <param> param;
%type <funcDecl> funcDecl;
%type <paramList> paramList paramListE;

%token <intVal> INTC
%token <floatVal> FLOATC
%token <str> STRINGC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token DIVOP MODOP QUOTOP NEGATE STRICTAPPLY SEQOP NOT FMAPOP APPLYFUNCTOR REMOP INTPOW FRACPOW XOR EQ 
%token NEQ LE GE AND OR CONCAT RANGE FUNCTYPE MONADBINDING GUARDS INDEXING ASPATTERN TYPEANNOTATION TYPECONSTRAINT
%token UNDERSCORE CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC
        | FLOATC
        | STRINGC
        ;

exprList : expr
         | expr exprList 
         ;

expr : literal
     | FUNC_ID exprList  { LOG_PARSER("## PARSER ## made FuncCall named %s\n"); }
     | FUNC_ID
     | '-' expr %prec FUNC_APPLY
     | '(' expr ')'       
     | '(' expr ',' commaSepExprs ')'
     | '[' commaSepExprs ']'
     | '[' commaSepExprs ']'
     | enumeration
     | '[' expr '|' commaSepExprs ']'
     | expr '+' expr      { LOG_PARSER("## PARSER ## made AddExpr\n"); }
     | expr '-' expr      { LOG_PARSER("## PARSER ## made SubExpr\n"); }
     | expr '*' expr      { LOG_PARSER("## PARSER ## made MulExor\n"); }
     | expr '/' expr      { LOG_PARSER("## PARSER ## made DivExpr\n"); }
     | expr AND expr      { LOG_PARSER("## PARSER ## made &&\n"); }
     | expr OR expr       { LOG_PARSER("## PARSER ## made ||\n"); }
     | expr EQ expr       { LOG_PARSER("## PARSER ## made ==\n"); }
     | expr NEQ expr      { LOG_PARSER("## PARSER ## made !=\n"); }
     | expr LE expr       { LOG_PARSER("## PARSER ## made <=\n"); }
     | expr GE expr       { LOG_PARSER("## PARSER ## made  >=\n"); }
     | expr '<' expr      { LOG_PARSER("## PARSER ## made <\n"); }
     | expr '>' expr      { LOG_PARSER("## PARSER ## made >\n"); }
     | NOT expr           { LOG_PARSER("## PARSER ## made UnaryExpr for not\n"); }
     | NEGATE expr        { LOG_PARSER("## PARSER ## made UnaryExpr for negate\n"); }
     ;


/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' texprs ')'     // (1,2,3)
      | '(' ',' commas ')'          // (,,,) 1 2 3
      | '(' ')'                     // ()
      ;

texprs : expr
       | expr ',' texprs
       ;

commas : ','
       | commas ','
       ;

list : '[' ']'
     | '[' commaSepExprs ']'
     ;

commaSepExprs : expr
              | expr ',' commaSepExprs 
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

enumeration : '[' expr RANGE ']'
            | '[' expr RANGE expr ']'
            | '[' expr ',' expr RANGE expr ']'
            | '[' expr ',' expr RANGE ']'
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
