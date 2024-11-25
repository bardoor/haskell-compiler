%require "3.2"
%locations

%{

#include <BisonUtils.hpp>
#include <typeinfo>

extern int yylex();
extern int yylineno;

#define DEBUG_PARSER

#ifdef DEBUG_PARSER
    #define LOG_PARSER(msg, ...) printf(msg, ##__VA_ARGS__);
#else
    #define LOG_PARSER(msg, ...)
#endif

void yyerror(const char* s);

json root;

%}

%union {
      long long intVal;
      long double floatVal;
      struct Node* node;
      std::string* str;
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


%type <node> literal expr oexpr dexpr kexpr fapply aexpr module body funlhs funid topDeclList topDecl declE var apatList commaSepExprs
             type symbols tuple list op comprehension altList declList enumeration lampats apat tycon opat pats
             classDecl classBody context class instDecl restrictInst rinstOpt generalInst valDefList valDef 
             valrhs valrhs1 whereOpt guardrhs guard tyvar tyvarList tyvarListComma btype typeListComma atypeList contextList

/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <str> STRINGC FLOATC SYMS CHARC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token <intVal> INTC
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW  

%start module

%%


/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { $$ = new Node(); $$->val = { {"literal", { {"value", std::to_string($1)}, {"type", "int"} }} }; LOG_PARSER("## PARSER ## make literal - INTC\n"); }
        | FLOATC    { $$ = new Node(); $$->val = { {"literal", { {"value", $1->substr()}, {"type", "float"} }} }; LOG_PARSER("## PARSER ## make literal - FLOATC\n"); }
        | STRINGC   { $$ = new Node(); $$->val = { {"literal", { {"value", $1->substr()}, {"type", "str"} }} }; LOG_PARSER("## PARSER ## make literal - STRINGC\n"); }
        | CHARC     { $$ = new Node(); $$->val = { {"literal", { {"value", $1->substr()}, {"type", "char"} }} }; LOG_PARSER("## PARSER ## make literal - CHARC\n"); }
        ;

/* Любое выражение с аннотацией типа или без */
expr : oexpr DCOLON type DARROW type { $$ = new Node(); $$->val = { {"expr_type", { {"expr", $1->val}, {"context", $3->val}, {"type", $5->val} }} }; LOG_PARSER("## PARSER ## make expr - oexpr with type annotation and context\n"); }
     | oexpr DCOLON type { $$ = new Node(); $$->val = { {"expr_type", { {"expr", $1->val}, {"type", $3->val} }} }; LOG_PARSER("## PARSER ## make expr - oexpr with type annotation\n"); } 
     | oexpr             { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make expr - oexpr\n"); }
     ;

/* Применение инфиксного оператора */
oexpr : oexpr op oexpr %prec '+'   { $$ = new Node(); $$->val = { {"bin_expr", { {"left", $1->val}, {"right", $3->val} }} }; LOG_PARSER("## PARSER ## make oexpr - oexpr op oexpr\n"); }
      | dexpr                      { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make oexpr - dexpr\n"); }
      ;

/* Денотированное выражение */
dexpr : '-' kexpr        { $$ = new Node(); $$->val = { {"unary_expr", { {"type", "minus"}, {"expr", $2->val} }} }; LOG_PARSER("## PARSER ## make dexpr - MINUS kexpr \n"); }
      | kexpr            { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make dexpr - kexpr\n"); }
      ;

/* Выражение с ключевым словом */
kexpr : '\\' lampats RARROW expr            { $$ = new Node(); $$->val  = { {"lambda", { {"params", $2->val}, {"body", $4->val} }} }; LOG_PARSER("## PARSER ## make kexpr - lambda\n"); }
      | LETKW '{' declList '}' INKW expr    { $$ = new Node(); $$->val  = { {"let", { {"decls", $3->val}, {"body", $6->val} } } }; LOG_PARSER("## PARSER ## make kexpr - LET .. IN ..\n"); }
      | IFKW expr THENKW expr ELSEKW expr   { $$ = new Node(); $$->val  = { {"if_else", { {"cond", $2->val}, {"true_branch", $4->val}, {"false_branch", $6->val} }} }; LOG_PARSER("## PARSER ## make kexpr - IF .. THEN .. ELSE ..\n"); }
      | CASEKW expr OFKW '{' altList '}'    { $$ = new Node(); $$->val  = { {"case", { {"expr", $2->val}, {"alternatives", $5->val} }} }; LOG_PARSER("## PARSER ## make kexpr - CASE .. OF .. \n"); }
      | fapply                              { $$ = new Node(); $$->val  = $1->val; LOG_PARSER("## PARSER ## make kexpr - func apply\n"); }
      ;

/* Применение функции */
fapply : fapply aexpr        { $$ = new Node(); $$->val  = { {"fun_apply", {"param", $2->val}} }; LOG_PARSER("## PARSER ## made func apply - many exprs\n"); }
       | aexpr               { $$ = new Node(); $$->val  = $1->val; LOG_PARSER("## PARSER ## make func apply - one expr\n"); }
       ;

/* Простое выражение */
aexpr : literal         { $$ = new Node(); $$->val  = { {"expr", $1->val} }; LOG_PARSER("## PARSER ## make expr - literal\n"); }
      | funid           { $$ = new Node(); $$->val  = { {"expr", $1->val} }; }
      | '(' expr ')'    { $$ = new Node(); $$->val  = $2->val; }
      | tuple           { $$ = new Node(); $$->val  = { {"expr", $1->val} }; LOG_PARSER("## PARSER ## make expr - tuple\n"); }
      | list            { $$ = new Node(); $$->val  = { {"expr", $1->val} }; LOG_PARSER("## PARSER ## make expr - list\n"); }
      | enumeration     { $$ = new Node(); $$->val  = { {"expr", $1->val} }; LOG_PARSER("## PARSER ## make expr - enumeration\n"); }
      | comprehension   { $$ = new Node(); $$->val  = { {"expr", $1->val} }; LOG_PARSER("## PARSER ## make expr - list comprehension\n"); }
      ;

/* Оператор */
op : symbols                { $$ = new Node(); $$->val  = { {"op", $1->val} }; LOG_PARSER("## PARSER ## make op - symbols\n"); }
   | BQUOTE funid BQUOTE    { $$ = new Node(); $$->val  = { {"quoted_op", $2->val} }; LOG_PARSER("## PARSER ## make op - `op`\n"); }
   | '+'                    { $$ = new Node(); $$->val  = { {"op", {"symbols", "+"}} }; LOG_PARSER("## PARSER ## make op - plus\n"); }
   | '-'                    { $$ = new Node(); $$->val  = { {"op", {"symbols", "-"}} }; LOG_PARSER("## PARSER ## make op - minus\n"); }
   ;

symbols : SYMS    { $$ = new Node(); $$->val = { {"symbols", $1->substr()} }; }
        ;

funid : FUNC_ID   { $$ = new Node(); $$->val = { {"funid",  $1->substr()} }; }
      ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' commaSepExprs ')'  { $$ = new Node(); $$->val["tuple"] = $4->val; $$->val["tuple"].push_back($2->val); LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); }
      | '(' ')'                         { $$ = new Node(); $$->val["tuple"] = json::array(); LOG_PARSER("## PARSER ## make tuple - ( )\n"); }
      ;

comprehension : '[' expr '|' commaSepExprs ']'
              ;

list : '[' ']'                          { $$ = new Node(); $$->val["list"] = json::array(); LOG_PARSER("## PARSER ## make list - [ ]\n"); }
     | '[' commaSepExprs ']'            { $$ = new Node(); $$->val["list"] = $2->val; LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n"); }
     ;

commaSepExprs : expr                    { $$ = new Node();  $$->val.push_back($1->val); LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); }
              | expr ',' commaSepExprs  { $$ = $3; $$->val.push_back($1->val); LOG_PARSER("## PARSER ## make commaSepExprs - expr ',' commaSepExprs\n"); }
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 ... и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

enumeration : '[' expr DOTDOT ']'               { $$ = new Node(); $$->val = { {"range", { {"start", $2->val} }} }; LOG_PARSER("## PARSER ## make enumeration - [ expr .. ]\n"); }
            | '[' expr DOTDOT expr ']'          { $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"end", $4->val} }} }; LOG_PARSER("## PARSER ## make enumeration - [ expr .. expr ]\n"); }
            | '[' expr ',' expr DOTDOT expr ']' { $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"second", $4->val}, {"end", $6->val} }} }; LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. expr ]\n"); }
            | '[' expr ',' expr DOTDOT ']'      { $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"second", $4->val} }} }; LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. ]\n"); }  
            ;

/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

lampats :  apat lampats	 { LOG_PARSER("## PARSER ## make lambda pattern - apat lampats\n"); }
	  |  apat          { LOG_PARSER("## PARSER ## make lambda pattern - apat\n"); }
	  ;

/* Список паттернов */
pats : pats ',' opat      { LOG_PARSER("## PARSER ## make pattern list - pats, opat\n"); }
     | opat               { LOG_PARSER("## PARSER ## make pattern list - opat\n"); }
     ;

opat : dpat               { LOG_PARSER("## PARSER ## make optional pattern - dpat\n"); }
     | opat op opat %prec '+' { LOG_PARSER("## PARSER ## make optional pattern - opat op opat\n"); }
     ;

dpat : '-' fpat           { LOG_PARSER("## PARSER ## make dpat - '-' fpat\n"); }
     | fpat               { LOG_PARSER("## PARSER ## make dpat - fpat\n"); }
     ;

fpat : fpat apat          { LOG_PARSER("## PARSER ## make fpat - fpat apat\n"); }
     | apat               { LOG_PARSER("## PARSER ## make fpat - apat\n"); }
     ;

/* Примитивные паттерны */
apat : funid                  { $$ = new Node(); $$->val = { {"pattern", $1->val } }; LOG_PARSER("## PARSER ## make apat - funid\n"); }
     | tycon                  { $$ = new Node(); $$->val = { {"pattern", $1->val } }; LOG_PARSER("## PARSER ## make apat - CONSTRUCTOR_ID\n"); }
     | literal                { $$ = new Node(); $$->val = { {"pattern", $1->val } }; LOG_PARSER("## PARSER ## make apat - literal\n"); }
     | WILDCARD               { $$ = new Node(); $$->val = { {"pattern", "wildcard" } }; LOG_PARSER("## PARSER ## make apat - WILDCARD\n"); }
     | '(' ')'                { $$ = new Node(); $$->val = { {"pattern", {"tuple", json::array()} } }; LOG_PARSER("## PARSER ## make apat - ()\n"); }
     | '(' opat ',' pats ')'  { $$ = new Node(); $4->val.push_back($2->val); $$->val = { {"pattern", {"tuple", $4->val} } };  LOG_PARSER("## PARSER ## make apat - (opat, pats)\n"); }
     | '[' pats ']'           { $$ = new Node(); $$->val = { {"pattern", $2->val } }; LOG_PARSER("## PARSER ## make apat - [pats]\n"); }
     | '[' ']'                { $$ = new Node(); $$->val = { {"pattern", {"list", json::array()} } }; LOG_PARSER("## PARSER ## make apat - []\n"); }
     | '~' apat               { $$ = new Node(); $$->val = { {"pattern", $2->val } }; LOG_PARSER("## PARSER ## make apat - ~apat\n"); }
     ;

apatList : apat
         | apatList apat
         ;

/* Альтернативы в case */
altList : altList ';' altE  { LOG_PARSER("## PARSER ## make alternative list - altList ; altE\n"); }
        | altE              { LOG_PARSER("## PARSER ## make alternative list - altE\n"); }
        ;

altE : opat altRest         { LOG_PARSER("## PARSER ## make alternative - opat altRest\n"); }
     | %empty               { LOG_PARSER("## PARSER ## make alternative - nothing\n"); }
     ;

altRest : guardPat whereOpt { LOG_PARSER("## PARSER ## make alternative rest - guardPat whereOpt\n"); }
        | RARROW expr whereOpt { LOG_PARSER("## PARSER ## make alternative rest - RARROW expr whereOpt\n"); }
        ;

guardPat : guard RARROW expr guardPat { LOG_PARSER("## PARSER ## make guard pattern - guard RARROW expr guardPat\n"); }
         | guard RARROW expr { LOG_PARSER("## PARSER ## make guard pattern - guard RARROW expr\n"); }
         ;

guard : VBAR oexpr          { LOG_PARSER("## PARSER ## make guard - VBAR oexpr\n"); }
      ;

/* ------------------------------- *
 *           Объявления            *
 * ------------------------------- */

declList : declE              { LOG_PARSER("## PARSER ## make declaration list - declE\n"); }
         | declList ';' declE { LOG_PARSER("## PARSER ## make declaration list - declList ; declE\n"); }
         ;

con : tycon                  { LOG_PARSER("## PARSER ## make constructor - tycon\n"); }
    | '(' symbols ')'        { LOG_PARSER("## PARSER ## make constructor - (symbols)\n"); }
    ;

conList : con                { LOG_PARSER("## PARSER ## make constructor list - con\n"); }
        | conList ',' con    { LOG_PARSER("## PARSER ## make constructor list - conList , con\n"); }
        ;

varList : varList ',' var    { LOG_PARSER("## PARSER ## make variable list - varList , var\n"); }
        | var                { LOG_PARSER("## PARSER ## make variable list - var\n"); }
        ;

/* Оператор в префиксной форме или идентификатор функции */
var : funid                  { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make variable - funid\n"); }
    | '(' symbols ')'        { $$ = new Node(); $$->val = $2->val; LOG_PARSER("## PARSER ## make variable - (symbols)\n"); }
    ;

/* Объявление */
declE : var '=' expr                    { $$ = new Node(); $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} }; LOG_PARSER("## PARSER ## make declaration - var = expr\n"); }
      | funlhs '=' expr                 { $$ = new Node(); $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} }; LOG_PARSER("## PARSER ## make declaration - funclhs = expr\n"); }
      | varList DCOLON type DARROW type { LOG_PARSER("## PARSER ## make declaration - varList :: type => type\n"); }
      | varList DCOLON type             { LOG_PARSER("## PARSER ## make declaration - varList :: type\n"); }
      | %empty                          { LOG_PARSER("## PARSER ## make declaration - nothing\n"); }
      ;

whereOpt : WHEREKW '{' declList '}' { LOG_PARSER("## PARSER ## make where option - WHERE declList\n"); }
         | %empty                   { LOG_PARSER("## PARSER ## make where option - nothing\n"); }
         ;

funlhs : var apatList               { $$ = new Node(); $$->val  = { {"funlhs", {{"name", $1->val}, {"params", $2->val}} } }; LOG_PARSER("## PARSER ## make funlhs - var apatList"); }
       ;

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

module : MODULEKW tycon WHEREKW body
       { LOG_PARSER("## PARSER ## make module - MODULE CONSTRUCTOR_ID WHERE body\n"); }
       | body
       { root = { {"module", {"name", 0}, {"body", $1->val} } }; LOG_PARSER("## PARSER ## make module - body\n"); }
       ;

body : '{' topDeclList '}'
     {  $$ = new Node(); $$->val = $2->val; LOG_PARSER("## PARSER ## make body - { topDeclList }\n"); }
     ;

topDeclList : topDecl
            { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make topDeclList - topDecl\n"); }
            | topDeclList ';' topDecl
            { LOG_PARSER("## PARSER ## make topDeclList - topDeclList ; topDecl\n"); }
            ;

topDecl : typeDecl
        { LOG_PARSER("## PARSER ## make topDecl - typeDecl\n"); }
        | dataDecl
        { LOG_PARSER("## PARSER ## make topDecl - dataDecl\n"); }
        | classDecl
        { LOG_PARSER("## PARSER ## make topDecl - classDecl\n"); }
        | instDecl
        { LOG_PARSER("## PARSER ## make topDecl - instDecl\n"); }
        | defaultDecl
        { LOG_PARSER("## PARSER ## make topDecl - defaultDecl\n"); }
        | declE
        { $$ = new Node(); $$->val  = $1->val; LOG_PARSER("## PARSER ## make topDecl - declE\n"); }
        ;

/* ------------------------------- *
 *       Классы, instance          *
 * ------------------------------- */

classDecl : CLASSKW context DARROW class classBody
          { $$ = new Node(); $$->val = {{"class_decl", {{"context", $2->val}, {"class", $4->val},{"body", $5->val}}}}; LOG_PARSER("## PARSER ## make classDecl - CLASS context => class classBody\n"); }
          | CLASSKW class classBody
          { $$ = new Node(); $$->val = {{"class_decl", {{"class", $2->val},{"body", $3->val}}}}; LOG_PARSER("## PARSER ## make classDecl - CLASS class classBody\n"); }
          ;

classBody : %empty
          { $$ = new Node(); $$->val = {{"body", nullptr}}; LOG_PARSER("## PARSER ## make classBody - nothing\n"); }
          | WHEREKW '{' declList '}'
          { $$ = new Node(); $$->val = {{"body", $3->val}}; LOG_PARSER("## PARSER ## make classBody - WHERE { declList }\n"); }
          ;

instDecl : INSTANCEKW context DARROW tycon restrictInst rinstOpt
         { $$ = new Node(); $$->val = {{"inst_decl", {{"context", $2->val}, {"tycon", $4->val}, {"restrictInst", $5->val}, {"rinstOpt", $6->val}}}}; LOG_PARSER("## PARSER ## make instDecl - INSTANCE context => tycon restrictInst rinstOpt\n"); }
         | INSTANCEKW tycon generalInst rinstOpt
         { $$ = new Node(); $$->val = {{"inst_decl", {{"tycon", $2->val}, {"generalInst", $3->val}, {"rinstOpt", $4->val}}}}; LOG_PARSER("## PARSER ## make instDecl - INSTANCE tycon generalInst rinstOpt\n"); }
         ;

rinstOpt : %empty
         { $$ = new Node(); $$->val = {{"rinstOpt", nullptr}}; LOG_PARSER("## PARSER ## make rinstOpt - nothing\n"); }
         | WHEREKW '{' valDefList '}'
         { $$ = new Node(); $$->val = {{"rinstOpt", $3->val}}; LOG_PARSER("## PARSER ## make rinstOpt - WHERE { valDefList }\n"); }
         ;

valDefList : %empty
            { $$ = new Node(); $$->val = {{"valDefList", json::array()}}; LOG_PARSER("## PARSER ## make valDefList - nothing\n"); }
            | valDef
            { $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val})}}; LOG_PARSER("## PARSER ## make valDefList - valDef\n"); }
            | valDef ';' valDef
            { $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val, $3->val})}}; LOG_PARSER("## PARSER ## make valDefList - valDef ; valDef\n"); }
            ;

valDef : opat valrhs
       { $$ = new Node(); $$->val = {{"valDef", {{"opat", $1->val},{"valrhs", $2->val}}}}; LOG_PARSER("## PARSER ## make valDef - opat valrhs\n"); }
       ;

/* Правосторонее значение */
valrhs : valrhs1 whereOpt
       { $$ = new Node(); $$->val = {{"valrhs", {{"valrhs1", $1->val},{"whereOpt", $2->val}}}}; LOG_PARSER("## PARSER ## make valrhs - valrhs1 whereOpt\n"); }
       ;

valrhs1 : guardrhs
        { $$ = new Node(); $$->val = {{"valrhs1", {{"guardrhs", $1->val}}}}; LOG_PARSER("## PARSER ## make valrhs1 - guardrhs\n"); }
        | '=' expr
        { $$ = new Node(); $$->val = {{"valrhs1", {{"expr", $2->val}}}}; LOG_PARSER("## PARSER ## make valrhs1 - = expr\n"); }
        ;

guardrhs : guard '=' expr
         { $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val}}}}; LOG_PARSER("## PARSER ## make guardrhs - guard = expr\n"); }
         | guard '=' expr guardrhs
         { $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val},{"guardrhs", $4->val}}}}; LOG_PARSER("## PARSER ## make guardrhs - guard = expr guardrhs\n"); }
         ;

restrictInst : tycon
             { $$ = new Node(); $$->val = {{"restrictInst", $1->val}}; LOG_PARSER("## PARSER ## make restrictInst - tycon\n"); }
             | '(' tycon tyvarList ')'
             { $$ = new Node(); $$->val = {{"restrictInst", {{"tycon", $2->val}, {"tyvarList", $3->val}}}}; LOG_PARSER("## PARSER ## make restrictInst - (tycon tyvarList)\n"); }
             | '(' tyvar ',' tyvarListComma ')'
             { $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}, {"tyvarListComma", $4->val}}}}; LOG_PARSER("## PARSER ## make restrictInst - (tyvar, tyvarListComma)\n"); }
             | '(' ')'
             { $$ = new Node(); $$->val = {{"restrictInst", json::array()}}; LOG_PARSER("## PARSER ## make restrictInst - ()\n"); }
             | '[' tyvar ']'
             { $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}}}}; LOG_PARSER("## PARSER ## make restrictInst - [tyvar]\n"); }
             | '(' tyvar RARROW tyvar ')'
             { $$ = new Node(); $$->val = {{"restrictInst", {{"from", $2->val}, {"to", $4->val}}}}; LOG_PARSER("## PARSER ## make restrictInst - (tyvar => tyvar)\n"); }
             ;

generalInst : tycon
            { $$ = new Node(); $$->val = {{"generalInst", $1->val}}; LOG_PARSER("## PARSER ## make generalInst - tycon\n"); }
            | '(' tycon atypeList ')'
            { $$ = new Node();  $$->val = {{"generalInst", {{"tycon", $2->val}, {"atypeList", $3->val}}}}; LOG_PARSER("## PARSER ## make generalInst - (tycon atypeList)\n"); }
            | '(' type ',' typeListComma ')'
            { $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}, {"typeListComma", $4->val}}}}; LOG_PARSER("## PARSER ## make generalInst - (type, typeListComma)\n"); }
            | '(' ')'
            { $$ = new Node(); $$->val = {{"generalInst", json::array()}}; LOG_PARSER("## PARSER ## make generalInst - ()\n"); }
            | '[' type ']'
            { $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}}}}; LOG_PARSER("## PARSER ## make generalInst - [type]\n"); }
            | '(' btype RARROW type ')'
            { $$ = new Node(); $$->val = {{"generalInst", {{"from", $2->val},{"to", $4->val}}}}; LOG_PARSER("## PARSER ## make generalInst - (btype => type)\n"); }
            ;

context : '(' contextList ')'
        { $$ = new Node(); $$->val = {{"context", $2->val}}; LOG_PARSER("## PARSER ## make context - (contextList)\n"); }
        | class
        { $$ = new Node(); $$->val = { {"context", $1->val} }; LOG_PARSER("## PARSER ## make context - class\n"); }
        ;

contextList : class
            { $$ = new Node(); $$->val = {{"contextList", { $1->val }}}; LOG_PARSER("## PARSER ## make contextList - class\n"); }
            | contextList ',' class
            { $$ = new Node(); $$->val = $1->val; $$->val["contextList"].push_back($3->val); LOG_PARSER("## PARSER ## make contextList - contextList, class\n"); }
            ;

class : tycon tyvar
      { $$ = new Node(); $$->val = {{"class", {{"tycon", $1->val},{"tyvar", $2->val}}}}; LOG_PARSER("## PARSER ## make class - tycon tyvar\n"); }
      ;

/* ------------------------------- *
 *              data               *
 * ------------------------------- */

dataDecl : DATAKW context DARROW simpleType '=' constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList\n"); }
         | DATAKW simpleType '=' constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList\n"); }
         | DATAKW context DARROW simpleType '=' constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList DERIVING tyClassList\n"); }
         | DATAKW simpleType '=' constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList DERIVING tyClassList\n"); }
         ;

constrList : tycon atypeList
           { LOG_PARSER("## PARSER ## make constrList - tycon atypeList\n"); }
           | '(' SYMS ')' atypeList
           { LOG_PARSER("## PARSER ## make constrList - (SYMS) atypeList\n"); }
           | '(' SYMS ')'
           { LOG_PARSER("## PARSER ## make constrList - (SYMS)\n"); }
           | tycon
           { LOG_PARSER("## PARSER ## make constrList - tycon\n"); }
           | btype conop btype
           { LOG_PARSER("## PARSER ## make constrList - btype conop btype\n"); }
           ;

conop : SYMS
      { LOG_PARSER("## PARSER ## make conop - SYMS\n"); }
      | BQUOTE CONSTRUCTOR_ID BQUOTE
      { LOG_PARSER("## PARSER ## make conop - `CONSTRUCTOR_ID`\n"); }
      ;

tyClassList : '(' tyClassListComma ')'
            { LOG_PARSER("## PARSER ## make tyClassList - (tyClassListComma)\n"); }
            | '(' ')'
            { LOG_PARSER("## PARSER ## make tyClassList - ()\n"); }
            | tyClass
            { LOG_PARSER("## PARSER ## make tyClassList - tyClass\n"); }
            ;

tyClassListComma : tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClass\n"); }
                 | tyClassListComma ',' tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClassListComma, tyClass\n"); }
                 ;

tyClass : tycon
        { LOG_PARSER("## PARSER ## make tyClass - tycon\n"); }
        ;

typeDecl : TYPEKW simpleType '=' type
         { LOG_PARSER("## PARSER ## make typeDecl - TYPE simpleType = type\n"); }
         ;

simpleType : tycon
           { LOG_PARSER("## PARSER ## make simpleType - tycon\n"); }
           | tycon tyvarList
           { LOG_PARSER("## PARSER ## make simpleType - tycon tyvarList\n"); }
           ;

tycon : CONSTRUCTOR_ID
      { LOG_PARSER("## PARSER ## make tycon - CONSTRUCTOR_ID\n"); }
      ;

tyvarList : tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvar\n"); }
          | tyvarList tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvarList tyvar\n"); }
          ;

tyvarListComma : tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvar\n"); }
               | tyvarList ',' tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvarList, tyvar\n"); }
               ;

tyvar : funid
      { LOG_PARSER("## PARSER ## make tyvar - funid\n"); }
      ;

defaultDecl : DEFAULTKW defaultTypes
            { LOG_PARSER("## PARSER ## make defaultDecl - DEFAULT defaultTypes\n"); }
            ;

defaultTypes : '(' type ',' typeListComma ')'
             { LOG_PARSER("## PARSER ## make defaultTypes - (type, typeListComma)\n"); }
             | ttype
             { LOG_PARSER("## PARSER ## make defaultTypes - ttype\n"); }
             ;

/* ------------------------------- *
 *              Типы               *
 * ------------------------------- */

type : btype
     { LOG_PARSER("## PARSER ## make type - btype\n"); }
     | btype RARROW type
     { LOG_PARSER("## PARSER ## make type - btype => type\n"); }
     ;

btype : atype
      { LOG_PARSER("## PARSER ## make btype - atype\n"); }
      | tycon atypeList
      { LOG_PARSER("## PARSER ## make btype - tycon atypeList\n"); }
      ;

atype : ntatype
      { LOG_PARSER("## PARSER ## make atype - ntatype\n"); }
      | '(' type ',' typeListComma ')'
      { LOG_PARSER("## PARSER ## make atype - (type, typeListComma)\n"); }
      ;

atypeList : atypeList atype
          { LOG_PARSER("## PARSER ## make atypeList - atypeList atype\n"); }
          | atype
          { LOG_PARSER("## PARSER ## make atypeList - atype\n"); }
          ;

ttype : ntatype
      { LOG_PARSER("## PARSER ## make ttype - ntatype\n"); }
      | btype RARROW type
      { LOG_PARSER("## PARSER ## make ttype - btype => type\n"); }
      | tycon atypeList
      { LOG_PARSER("## PARSER ## make ttype - tycon atypeList\n"); }
      ;

ntatype : tyvar
        { LOG_PARSER("## PARSER ## make ntatype - tyvar\n"); }
        | tycon
        { LOG_PARSER("## PARSER ## make ntatype - tycon\n"); }
        | '(' ')'
        { LOG_PARSER("## PARSER ## make ntatype - ()\n"); }
        | '(' type ')'
        { LOG_PARSER("## PARSER ## make ntatype - (type)\n"); }
        | '[' type ']'
        { LOG_PARSER("## PARSER ## make ntatype - [type]\n"); }
        ;

typeListComma : type
              { LOG_PARSER("## PARSER ## make typeListComma - type\n"); }
              | type ',' typeListComma
              { LOG_PARSER("## PARSER ## make typeListComma - type, typeListComma\n"); }
              ;

%%

void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
