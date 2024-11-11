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
%token DIVOP MODOP QUOTOP NEGATE STRICTAPPLY SEQOP NOT FMAPOP APPLYFUNCTOR REMOP INTPOW FRACPOW XOR EQ 
%token NEQ LE GE AND OR CONCAT RANGE FUNCTYPE MONADBINDING GUARDS INDEXING ASPATTERN TYPEANNOTATION TYPECONSTRAINT
%token UNDERSCORE CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW CHARC

%start fapply

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { LOG_PARSER("## PARSER ## make literal - INTC\n"); }
        | FLOATC    { LOG_PARSER("## PARSER ## make literal - FLOATC\n"); }
        | STRINGC   { LOG_PARSER("## PARSER ## make literal - STRINGC\n"); }
        | CHARC     { LOG_PARSER("## PARSER ## make literal - CHARC\n"); }
        ;

exprListE : exprList        { LOG_PARSER("## PARSER ## make ExprListE - ExprList\n"); }
          | /* nothing */   { LOG_PARSER("## PARSER ## make ExprListE - nothing\n"); }
          ;

exprList : expr             { LOG_PARSER("## PARSER ## make ExprList - expr\n"); }
         | expr exprList    { LOG_PARSER("## PARSER ## make ExprList - exprList\n"); }
         ;

fapply : fapply expr        { LOG_PARSER("## PARSER ## made func apply\n"); }
       | expr
       ;

expr : literal         { LOG_PARSER("## PARSER ## make expr - literal\n"); }
     | FUNC_ID
     | '(' expr ')'    
     | tuple           { LOG_PARSER("## PARSER ## make expr - tuple\n"); }
     | list            { LOG_PARSER("## PARSER ## make expr - list\n"); }
     | enumeration     { LOG_PARSER("## PARSER ## make expr - enumeration\n"); }
     | comprehension   { LOG_PARSER("## PARSER ## make expr - list comprehension\n"); }
     | binExpr         { LOG_PARSER("## PARSER ## make expr - binary expr\n"); }
     ;

binExpr : expr '+' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr + expr\n"); }
        | expr '-' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr - expr\n"); }
        | expr '*' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr * expr\n"); }
        | expr '/' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr / expr\n"); }
        | expr AND expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr AND expr\n"); }
        | expr OR expr                  { LOG_PARSER("## PARSER ## make binaryExpr - expr OR expr\n"); }
        | expr EQ expr                  { LOG_PARSER("## PARSER ## make binaryExpr - expr EQ expr\n"); }
        | expr NEQ expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr NEQ expr\n"); }
        | expr LE expr                  { LOG_PARSER("## PARSER ## make binaryExpr - expr LE expr\n"); }
        | expr GE expr                  { LOG_PARSER("## PARSER ## make binaryExpr - expr GE expr\n"); }
        | expr '<' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr < expr\n"); }
        | expr '>' expr                 { LOG_PARSER("## PARSER ## make binaryExpr - expr > expr\n"); }
        ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' commaSepExprs ')'  { LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); }
      | '(' ')'                         { LOG_PARSER("## PARSER ## make tuple - ( )\n"); }
      ;

commas : ','                            { LOG_PARSER("## PARSER ## make commas - ,\n"); }
       | commas ','                     { LOG_PARSER("## PARSER ## make commas - commas ,\n"); }
       ;

comprehension : '[' expr '|' commaSepExprs ']'
              ;

list : '[' ']'                          { LOG_PARSER("## PARSER ## make list - [ ]\n"); }
     | '[' commaSepExprs ']'            { LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n"); }
     ;

commaSepExprs : expr                    { LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); }
              | expr ',' commaSepExprs  { LOG_PARSER("## PARSER ## make commaSepExprs - expr ',' commaSepExprs\n"); }
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 ... и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

enumeration : '[' expr RANGE ']'               { LOG_PARSER("## PARSER ## make enumeration - [ expr .. ]\n"); }
            | '[' expr RANGE expr ']'          { LOG_PARSER("## PARSER ## make enumeration - [ expr .. expr ]\n"); }
            | '[' expr ',' expr RANGE expr ']' { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. expr ]\n"); }
            | '[' expr ',' expr RANGE ']'      { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. ]\n"); }  
            ;

/* ------------------------------- *
 *              Типы               *
 * ------------------------------- */

typeDecl : TYPEKW CONSTRUCTOR_ID '=' type      
         ;

type : btype                
     | btype FUNCTYPE type        
     ;

btype : '[' btype ']' atype     
      | atype              
      ;

atype : gtycon             
      | tyvar              
      | '(' type_list ')' 
      | '[' type ']'
      | '(' type ')'
      ;

type_list: type          
          | type ',' type_list 
          ;

gtycon : gtycon   
       | '('')'                
       | '['']'                
       | '('FUNCTYPE')'              
       | '(' '{' ',' '}' ')' 
       | CONSTRUCTOR_ID   
       ;

tyvar : FUNC_ID          
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
