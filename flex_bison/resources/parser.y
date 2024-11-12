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
%token DIVOP MODOP QUOTOP NEGATE STRICTAPPLY SEQOP NOT FMAPOP APPLYFUNCTOR REMOP INTPOW FRACPOW XOR EQ DARROW
%token NEQ LE GE AND OR CONCAT DOTDOT RARROW LARROW GUARDS INDEXING ASPATTERN DCOLON TYPECONSTRAINT BQUOTE SYMS VBAR
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW CHARC 

%start expr

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { LOG_PARSER("## PARSER ## make literal - INTC\n"); }
        | FLOATC    { LOG_PARSER("## PARSER ## make literal - FLOATC\n"); }
        | STRINGC   { LOG_PARSER("## PARSER ## make literal - STRINGC\n"); }
        | CHARC     { LOG_PARSER("## PARSER ## make literal - CHARC\n"); }
        ;

/* Любое выражение с аннотацией типа или без */
expr : oexpr DCOLON type { LOG_PARSER("## PARSER ## make expr - oexpr with type annotation\n"); }
     | oexpr             { LOG_PARSER("## PARSER ## make expr - oexpr\n"); }
     ;

/* Применение инфиксного оператора */
oexpr : oexpr op oexpr   { LOG_PARSER("## PARSER ## make oexpr - oexpr op oexpr\n"); }
      | dexpr            { LOG_PARSER("## PARSER ## make oexpr - dexpr\n"); }
      ;

/* Денотированное выражение */
dexpr : '-' kexpr        { LOG_PARSER("## PARSER ## make dexpr - MINUS kexpr \n"); }
      | kexpr            { LOG_PARSER("## PARSER ## make dexpr - kexpr\n"); }
      ;

/* Выражение с ключевым словом */
kexpr : '\\' lampats RARROW expr            { LOG_PARSER("## PARSER ## make kexpr - lambda\n"); }
      | LETKW '{' decls '}' INKW expr       { LOG_PARSER("## PARSER ## make kexpr - LET .. IN ..\n"); }
      | IFKW expr THENKW expr ELSEKW expr   { LOG_PARSER("## PARSER ## make kexpr - IF .. THEN .. ELSE ..\n"); }
      | CASEKW expr OFKW '{' alts '}'       { LOG_PARSER("## PARSER ## make kexpr - CASE .. OF .. \n"); }
      | fapply                              { LOG_PARSER("## PARSER ## make kexpr - func apply\n"); }
      ;

/* Применение функции */
fapply : fapply expr        { LOG_PARSER("## PARSER ## made func apply - many exprs\n"); }
       | expr               { LOG_PARSER("## PARSER ## make func apply - one expr\n"); }
       ;

/* Простое выражение */
aexpr : literal         { LOG_PARSER("## PARSER ## make expr - literal\n"); }
      | FUNC_ID
      | '(' expr ')'    
      | tuple           { LOG_PARSER("## PARSER ## make expr - tuple\n"); }
      | list            { LOG_PARSER("## PARSER ## make expr - list\n"); }
      | enumeration     { LOG_PARSER("## PARSER ## make expr - enumeration\n"); }
      | comprehension   { LOG_PARSER("## PARSER ## make expr - list comprehension\n"); }
      ;

/* Оператор */
op : SYMS                   { LOG_PARSER("## PARSER ## make op - symbols\n"); }
   | BQUOTE FUNC_ID BQUOTE  { LOG_PARSER("## PARSER ## make op - `op`\n"); }
   | '+'                    { LOG_PARSER("## PARSER ## make op - plus\n"); }
   | '-'                    { LOG_PARSER("## PARSER ## make op - minus\n"); }
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

enumeration : '[' expr DOTDOT ']'               { LOG_PARSER("## PARSER ## make enumeration - [ expr .. ]\n"); }
            | '[' expr DOTDOT expr ']'          { LOG_PARSER("## PARSER ## make enumeration - [ expr .. expr ]\n"); }
            | '[' expr ',' expr DOTDOT expr ']' { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. expr ]\n"); }
            | '[' expr ',' expr DOTDOT ']'      { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. ]\n"); }  
            ;

/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

/* Паттерн в параметрах лямбда функции */
lampats	:  apat lampats			
	    |  apat				
	    ;

/* Список паттернов */
pats : apat ',' pats
     | apat
     ;

/* Примитивные паттерны */
apat : FUNC_ID
     | CONSTRUCTOR_ID
     | FUNC_ID ASPATTERN apat
     | literal
     | WILDCARD
     | '(' ')'
     | '(' opat ',' pats ')'
     | '[' opat ']'
     | '[' ']'
     | '~' apat
     ;

/* Альтернативы в case */
alts : alts ';' altE
     | altE
     ;

altE : pat altRest
     | /* nothing */
     ;

altRest : guardPat whereOpt
        | RARROW expr whereOpt
        ;

guardPat : guard RARROW expr guardPat
         | guard RARROW expr
         ;

guard : VBAR oexpr
      ;

/* ------------------------------- *
 *           Объявления            *
 * ------------------------------- */

/* Список объявлений */
declList : decl
         | decl ';' decls
         ;

/* Список var */
varList : var ',' var
        | var
        ;

/* Оператор в префиксной форме или идентификатор функции */
var : FUNC_ID
    | '(' symbols ')'
    ;

/* Объявление */
declE : varList DCOLON type DARROW type 
      | varList DCOLON type
      | /* nothing */
      ;

whereOpt : WHEREKW '{' decls '}'
         | /* nothing */
         ;

/* ------------------------------- *
 *              Типы               *
 * ------------------------------- */

typeDecl : TYPEKW simpleType '=' type      
         ;

simpleType : tycon
           | tycon tyvars
           ;

tycon : CONSTRUCTOR_ID
      ;

tyvars : tyvar
       | tyvars tyvar
       ;

tyvar : FUNC_ID
      ;

type : btype                
     | btype RARROW type        
     ;

btype : '[' btype ']' atype     
      | atype              
      ;

atype : gtycon             
      | tyvar              
      | '(' typeList ')' 
      | '[' type ']'
      | '(' type ')'
      ;

typeList: type          
          | type ',' typeList 
          ;

gtycon : gtycon   
       | '('')'                
       | '['']'                
       | '('RARROW')'              
       | '(' '{' ',' '}' ')' 
       | CONSTRUCTOR_ID   
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
