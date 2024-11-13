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
    struct TypeDecl* typeDecl;
}


/* ------------------------------- *
 *           Приоритеты            *
 * ------------------------------- */

%left	CASE		LET	IN		LAMBDA
  	IF		ELSE

%left SYMS '+' '-' BQUOTE

%left DCOLON

%left ';' ','

%left '(' '[' '{'

%left '='

%right DARROW
%right RARROW


/* ------------------------------- *
 *        Объявления типов         *
 * ------------------------------- */

//%type <expr> expr;
//%type <module> module;
//%type <param> param;
//%type <funcDecl> funcDecl;
//%type <paramList> paramList paramListE;
//%type <typeDecl> typeDecl;


/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <intVal> INTC
%token <floatVal> FLOATC
%token <str> STRINGC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR ASPATTERN BQUOTE SYMS
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW CHARC 

%start module

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { LOG_PARSER("## PARSER ## make literal - INTC\n"); }
        | FLOATC    { LOG_PARSER("## PARSER ## make literal - FLOATC\n"); }
        | STRINGC   { LOG_PARSER("## PARSER ## make literal - STRINGC\n"); }
        | CHARC     { LOG_PARSER("## PARSER ## make literal - CHARC\n"); }
        ;

expr : expr op expr %prec '+'                   { LOG_PARSER("## PARSER ## make expr - expr op expr\n"); }
     | '-' expr                                 { LOG_PARSER("## PARSER ## make expr - minus expr\n"); }
     | LETKW '{' declList '}' INKW expr         { LOG_PARSER("## PARSER ## make expr - let .. in ..\n") }
     | IFKW expr THENKW expr ELSEKW expr        { LOG_PARSER("## PARSER ## make expr - if then else\n"); }
//     | '\\' patternList RARROW expr           
//     | DOKW '{' stmtList '}'
//     | CASEKW expr OFKW '{' /* alts */ '}'   
     | fapply                                   { LOG_PARSER("## PARSER ## make expr - function application\n"); }
     | literal                                  { LOG_PARSER("## PARSER ## make expr - literal\n"); }
     | '(' expr ')'                             { LOG_PARSER("## PARSER ## make expr - (expr)\n"); }
     | range                                    { LOG_PARSER("## PARSER ## make expr - range\n"); }
     | list                                     { LOG_PARSER("## PARSER ## make expr - list\n"); }
     | tuple                                    { LOG_PARSER("## PARSER ## make expr - tuple\n"); }
     | comprehension                            { LOG_PARSER("## PARSER ## make expr - comprehension\n"); }
     | cut                                      { LOG_PARSER("## PARSER ## make expr - cut\n"); }
     ;

fapply : funid exprList        { LOG_PARSER("## PARSER ## made func apply - many exprs\n"); }
       | funid                 { LOG_PARSER("## PARSER ## make func apply - identifier\n"); }
       ;

exprList : expr
         | exprList expr       { LOG_PARSER("## PARSER ## make exprList\n"); }
         ;

funid : '(' SYMS ')'
      | '(' '+' ')'
      | '(' '-' ')'
      | FUNC_ID
      ;

/* Оператор */
op : SYMS                   
   | BQUOTE funid BQUOTE    
   | '+'                    
   | '-'                    
   ;

operatorList : op
             | operatorList ',' op
             ;

cut : '(' '+' expr  ')'
    | '(' BQUOTE funid BQUOTE expr ')'
    | '(' SYMS expr ')'
    | '(' expr '+' ')'
    | '(' expr BQUOTE funid BQUOTE ')'
    | '(' expr SYMS ')'
    ;

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

module : MODULEKW conid WHEREKW '{' declList '}'  { LOG_PARSER("## PARSER ## make explicit module\n"); }
       | '{' declList '}'                         { LOG_PARSER("## PARSER ## make module - body only\n"); }
       ;

declList : declE
         | declList ';' declE   { LOG_PARSER("## PARSER ## make declList\n"); }
         ;

declE : /* nothing */
      | decl
      ;

decl : funList DCOLON conid         { LOG_PARSER("## PARSER ## make decl - funList :: type\n"); }
     | INFIXKW INTC operatorList    { LOG_PARSER("## PARSER ## make decl - infix INTC operators\n"); }
     | INFIXLKW INTC operatorList   { LOG_PARSER("## PARSER ## make decl - infixl INTC operators\n"); }
     | INFIXRKW INTC operatorList   { LOG_PARSER("## PARSER ## make decl - infixr INTC operators\n"); }
     | funid '=' expr               { LOG_PARSER("## PARSER ## make decl - funid = expr\n"); }
     ;

funList : funid
        | funList ',' funid
        ;

conid : CONSTRUCTOR_ID
     ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' commaSepExprs ')'  { LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); }
      | '(' ')'                         { LOG_PARSER("## PARSER ## make tuple - ( )\n"); }
      ;

comprehension : '[' expr '|' commaSepExprs ']'  { LOG_PARSER("## PARSER ## make comprehension\n"); }
              ;

list : '[' ']'                            { LOG_PARSER("## PARSER ## make list - [ ]\n"); }
     | '[' commaSepExprs ']'              { LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n"); }
     ;

commaSepExprs : expr                      { LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); }
              | commaSepExprs ',' expr    { LOG_PARSER("## PARSER ## make commaSepExprs - expr ',' commaSepExprs\n"); }
              ;

range : '[' expr DOTDOT ']'               { LOG_PARSER("## PARSER ## make range - [ expr .. ]\n"); }
      | '[' expr DOTDOT expr ']'          { LOG_PARSER("## PARSER ## make range - [ expr .. expr ]\n"); }
      | '[' expr ',' expr DOTDOT expr ']' { LOG_PARSER("## PARSER ## make range - [ expr, expr .. expr ]\n"); }
      | '[' expr ',' expr DOTDOT ']'      { LOG_PARSER("## PARSER ## make range - [ expr, expr .. ]\n"); }  
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

