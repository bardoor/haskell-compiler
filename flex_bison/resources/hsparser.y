%require "3.2"
%locations

%{
#define YYDEBUG 1

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

%left	CASEKW		LETKW	 INKW	'\\'
  	    IFKW		ELSEKW

%left SYMS '+' '-' BQUOTE

%left DCOLON

%nonassoc LOWER_THAN_COMMA

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
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE SYMS
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW CHARC 

%start module

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

simpleLiteral : INTC
              | FLOATC   
              | STRINGC  
              | CHARC 
              | list
              | tuple
              ;

literal : range                                    
        | comprehension                            
        ;

expr : 

exprOnly : exprOnly op exprOnly %prec '+'
         | LETKW '{' declList '}' INKW exprOnly
         | IFKW exprOnly THENKW


expr : expr op expr %prec '+'                   { LOG_PARSER("## PARSER ## make expr - expr op expr\n"); }
     | '-' expr                                 { LOG_PARSER("## PARSER ## make expr - minus expr\n"); }
     | LETKW '{' declList '}' INKW expr         { LOG_PARSER("## PARSER ## make expr - let .. in ..\n") }
     | IFKW expr THENKW expr ELSEKW expr        { LOG_PARSER("## PARSER ## make expr - if then else\n"); }
     | '\\' patternList RARROW expr             { LOG_PARSER("## PARSER ## make expr - lambda\n"); }
     | DOKW '{' stmtList expr '}'               { LOG_PARSER("## PARSER ## make expr - do\n"); }
     | CASEKW expr OFKW '{' alternativeList '}' { LOG_PARSER("## PARSER ## make expr - case\n"); }
     | conid '{' fbindList '}'                  { LOG_PARSER("## PARSER ## make expr - create data\n"); }
     | cut param                                { LOG_PARSER("## PARSER ## make expr - cut\n"); }
     | '(' expr ')'                             { LOG_PARSER("## PARSER ## make expr - (expr)\n"); }
     | literal                                  { LOG_PARSER("## PARSER ## make expr - literal\n"); }
     | fapply                                   { LOG_PARSER("## PARSER ## make expr - application\n"); }
     ; 

fapply : funid paramList                  
       ;

param : literal
      | funid
      | '(' expr ')'
      ;

paramList : param
          | paramList param
          ;

funid : '(' SYMS ')'
      | '(' '+' ')'
      | '(' '-' ')'
      | FUNC_ID
      ;

fbind : funid '=' expr
      ;

fbindList : fbind
          | fbindList ',' fbind
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

alternativeList : alternative
                | alternative ';' alternativeList
                ;

alternative : exclusivePattern RARROW expr
            | exprPattern RARROW expr
            ;

guardPattern : '|' expr RARROW expr
             | '|' expr RARROW expr guardPattern
             ;

stmtList : stmt
         | stmtList stmt
         ;

stmt : expr ';' 
     | exprPattern LARROW expr ';'
     | LETKW '{' declList '}' ';'
     | ';'
     ;

/* ------------------------------- *
 *        Паттерн матчинг          *
 * ------------------------------- */

exprPattern : simpleLiteral
            | '-' INTC
            | '-' FLOATC
            | funid
            | '(' exprPattern ')'
            | '[' patternList ']'
            ;

exclusivePattern : WILDCARD
                 | funid AS exprPattern
                 | funid AS exclusivePattern
                 ;

patternList : exclusivePattern %prec LOWER_THAN_COMMA
            | patternList ',' exprPattern
            | patternList ',' exclusivePattern
            | exprList ',' exclusivePattern 
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
     | funid '=' exprPattern        { LOG_PARSER("## PARSER ## make decl - funid = exprPattern\n"); }
     ;

funList : funid
        | funList ',' funid
        ;

conid : CONSTRUCTOR_ID
      ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' exprList ')'  { LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); }
      | '(' ')'                         { LOG_PARSER("## PARSER ## make tuple - ( )\n"); }
      ;

// TODO: разобраться в comprehension, это неверно..
comprehension : '[' expr '|' exprList ']'  { LOG_PARSER("## PARSER ## make comprehension\n"); }
              ;

list : '[' ']'                { LOG_PARSER("## PARSER ## make list - [ ]\n"); }
     | '[' exprList ']'  { LOG_PARSER("## PARSER ## make list - [ exprList ]\n"); }
     ;

exprList : expr %prec LOWER_THAN_COMMA                 
         | expr ',' exprList 
         ;

range : '[' expr DOTDOT ']'               { LOG_PARSER("## PARSER ## make range - [ expr .. ]\n"); }
      | '[' expr DOTDOT expr ']'          { LOG_PARSER("## PARSER ## make range - [ expr .. expr ]\n"); }
      | '[' expr ',' expr DOTDOT expr ']' { LOG_PARSER("## PARSER ## make range - [ expr, expr .. expr \n"); }
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

