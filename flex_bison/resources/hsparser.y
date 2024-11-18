%require "3.2"
%locations

%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>

#include <json.hpp>

using json = nlohmann::json;

struct Node {
    json val; 
};

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


%type <node> literal expr oexpr dexpr kexpr fapply aexpr module body funlhs funid topDeclList topDecl declE var apatList

/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <str> STRINGC INTC FLOATC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE SYMS
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW CHARC 

%start module

%%

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { $$->val = { {"literal", { {"value", *$1}, {"type", "int"} }} }; LOG_PARSER("## PARSER ## make literal - INTC\n"); }
        | FLOATC    { LOG_PARSER("## PARSER ## make literal - FLOATC\n"); }
        | STRINGC   { LOG_PARSER("## PARSER ## make literal - STRINGC\n"); }
        | CHARC     { LOG_PARSER("## PARSER ## make literal - CHARC\n"); }
        ;

/* Любое выражение с аннотацией типа или без */
expr : oexpr DCOLON type DARROW type 
     | oexpr DCOLON type { LOG_PARSER("## PARSER ## make expr - oexpr with type annotation\n"); } 
     | oexpr             { $$ = $1; LOG_PARSER("## PARSER ## make expr - oexpr\n"); }
     ;

/* Применение инфиксного оператора */
oexpr : oexpr op oexpr %prec '+'   { LOG_PARSER("## PARSER ## make oexpr - oexpr op oexpr\n"); }
      | dexpr                      { $$ = $1; LOG_PARSER("## PARSER ## make oexpr - dexpr\n"); }
      ;

/* Денотированное выражение */
dexpr : '-' kexpr        { LOG_PARSER("## PARSER ## make dexpr - MINUS kexpr \n"); }
      | kexpr            { $$ = $1; LOG_PARSER("## PARSER ## make dexpr - kexpr\n"); }
      ;

/* Выражение с ключевым словом */
kexpr : '\\' lampats RARROW expr            { LOG_PARSER("## PARSER ## make kexpr - lambda\n"); }
      | LETKW '{' declList '}' INKW expr    { LOG_PARSER("## PARSER ## make kexpr - LET .. IN ..\n"); }
      | IFKW expr THENKW expr ELSEKW expr   { LOG_PARSER("## PARSER ## make kexpr - IF .. THEN .. ELSE ..\n"); }
      | CASEKW expr OFKW '{' altList '}'    { LOG_PARSER("## PARSER ## make kexpr - CASE .. OF .. \n"); }
      | fapply                              { $$ = $1; LOG_PARSER("## PARSER ## make kexpr - func apply\n"); }
      ;

/* Применение функции */
fapply : fapply aexpr        { LOG_PARSER("## PARSER ## made func apply - many exprs\n"); }
       | aexpr               { $$ = $1; LOG_PARSER("## PARSER ## make func apply - one expr\n"); }
       ;

/* Простое выражение */
aexpr : literal         { $$->val = { {"aexpr", $1->val} }; LOG_PARSER("## PARSER ## make expr - literal\n"); }
      | funid           { $$->val = { {"aexpr", $1->val} }; }
      | '(' expr ')'    
      | tuple           { LOG_PARSER("## PARSER ## make expr - tuple\n"); }
      | list            { LOG_PARSER("## PARSER ## make expr - list\n"); }
      | enumeration     { LOG_PARSER("## PARSER ## make expr - enumeration\n"); }
      | comprehension   { LOG_PARSER("## PARSER ## make expr - list comprehension\n"); }
      ;

/* Оператор */
op : symbols                { LOG_PARSER("## PARSER ## make op - symbols\n"); }
   | BQUOTE funid BQUOTE    { LOG_PARSER("## PARSER ## make op - `op`\n"); }
   | '+'                    { LOG_PARSER("## PARSER ## make op - plus\n"); }
   | '-'                    { LOG_PARSER("## PARSER ## make op - minus\n"); }
   ;

symbols : SYMS
        ;

funid : FUNC_ID   { $$->val = { {"funid", {"name", *$1}} }; }
      ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' commaSepExprs ')'  { LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); }
      | '(' ')'                         { LOG_PARSER("## PARSER ## make tuple - ( )\n"); }
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

lampats :  apat lampats	{ LOG_PARSER("## PARSER ## make lambda pattern - apat lampats\n"); }
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
apat : funid              { LOG_PARSER("## PARSER ## make apat - funid\n"); }
     | CONSTRUCTOR_ID     { LOG_PARSER("## PARSER ## make apat - CONSTRUCTOR_ID\n"); }
     | funid AS apat      { LOG_PARSER("## PARSER ## make apat - funid AS apat\n"); }
     | literal            { LOG_PARSER("## PARSER ## make apat - literal\n"); }
     | WILDCARD           { LOG_PARSER("## PARSER ## make apat - WILDCARD\n"); }
     | '(' ')'            { LOG_PARSER("## PARSER ## make apat - ()\n"); }
     | '(' opat ',' pats ')' { LOG_PARSER("## PARSER ## make apat - (opat, pats)\n"); }
     | '[' opat ']'       { LOG_PARSER("## PARSER ## make apat - [opat]\n"); }
     | '[' ']'            { LOG_PARSER("## PARSER ## make apat - []\n"); }
     | '~' apat           { LOG_PARSER("## PARSER ## make apat - ~apat\n"); }
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
var : funid                { LOG_PARSER("## PARSER ## make variable - funid\n"); }
    | '(' symbols ')'        { LOG_PARSER("## PARSER ## make variable - (symbols)\n"); }
    ;

/* Объявление */
declE : var '=' expr                    { $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} }; LOG_PARSER("## PARSER ## make declaration - var = expr\n"); }
      | funlhs '=' expr                 { $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} }; LOG_PARSER("## PARSER ## make declaration - funclhs = expr\n"); }
      | varList DCOLON type DARROW type { LOG_PARSER("## PARSER ## make declaration - varList :: type => type\n"); }
      | varList DCOLON type             { LOG_PARSER("## PARSER ## make declaration - varList :: type\n"); }
      | %empty                          { LOG_PARSER("## PARSER ## make declaration - nothing\n"); }
      ;

whereOpt : WHEREKW '{' declList '}' { LOG_PARSER("## PARSER ## make where option - WHERE declList\n"); }
         | %empty                   { LOG_PARSER("## PARSER ## make where option - nothing\n"); }
         ;

funlhs : var apatList               { $$->val = { {"funlhs", {{"name", $1->val}, {"params", $2->val}} } }; LOG_PARSER("## PARSER ## make funlhs - var apatList"); }
       ;

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

module : MODULEKW tycon WHEREKW body
       { LOG_PARSER("## PARSER ## make module - MODULE CONSTRUCTOR_ID WHERE body\n"); }
       | body
       { $$->val = { {"module", {"name", 0}, {"body", $1->val} } }; LOG_PARSER("## PARSER ## make module - body\n"); }
       ;

body : '{' topDeclList '}'
     { $$ = $2; LOG_PARSER("## PARSER ## make body - { topDeclList }\n"); }
     ;

topDeclList : topDecl
            { $$ = $1; LOG_PARSER("## PARSER ## make topDeclList - topDecl\n"); }
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
        { $$ = $1; LOG_PARSER("## PARSER ## make topDecl - declE\n"); }
        ;

/* ------------------------------- *
 *       Классы, instance          *
 * ------------------------------- */

classDecl : CLASSKW context DARROW class classBody
          { LOG_PARSER("## PARSER ## make classDecl - CLASS context => class classBody\n"); }
          | CLASSKW class classBody
          { LOG_PARSER("## PARSER ## make classDecl - CLASS class classBody\n"); }
          ;

classBody : %empty
          { LOG_PARSER("## PARSER ## make classBody - nothing\n"); }
          | WHEREKW '{' declList '}'
          { LOG_PARSER("## PARSER ## make classBody - WHERE { declList }\n"); }
          ;

instDecl : INSTANCEKW context DARROW tycon restrictInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE context => tycon restrictInst rinstOpt\n"); }
         | INSTANCEKW tycon generalInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE tycon generalInst rinstOpt\n"); }
         ;

rinstOpt : %empty
         { LOG_PARSER("## PARSER ## make rinstOpt - nothing\n"); }
         | WHEREKW '{' valDefList '}'
         { LOG_PARSER("## PARSER ## make rinstOpt - WHERE { valDefList }\n"); }
         ;

valDefList : %empty
            { LOG_PARSER("## PARSER ## make valDefList - nothing\n"); }
            | valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef\n"); }
            | valDef ';' valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef ; valDef\n"); }
            ;

valDef : opat valrhs
       { LOG_PARSER("## PARSER ## make valDef - opat valrhs\n"); }
       ;

/* Правосторонее значение */
valrhs : valrhs1 whereOpt
       { LOG_PARSER("## PARSER ## make valrhs - valrhs1 whereOpt\n"); }
       ;

valrhs1 : guardrhs
        { LOG_PARSER("## PARSER ## make valrhs1 - guardrhs\n"); }
        | '=' expr
        { LOG_PARSER("## PARSER ## make valrhs1 - = expr\n"); }
        ;

guardrhs : guard '=' expr
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr\n"); }
         | guard '=' expr guardrhs
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr guardrhs\n"); }
         ;

restrictInst : tycon
             { LOG_PARSER("## PARSER ## make restrictInst - tycon\n"); }
             | '(' tycon tyvarList ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tycon tyvarList)\n"); }
             | '(' tyvar ',' tyvarListComma ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar, tyvarListComma)\n"); }
             | '(' ')'
             { LOG_PARSER("## PARSER ## make restrictInst - ()\n"); }
             | '[' tyvar ']'
             { LOG_PARSER("## PARSER ## make restrictInst - [tyvar]\n"); }
             | '(' tyvar RARROW tyvar ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar => tyvar)\n"); }
             ;

generalInst : tycon
            { LOG_PARSER("## PARSER ## make generalInst - tycon\n"); }
            | '(' tycon atypeList ')'
            { LOG_PARSER("## PARSER ## make generalInst - (tycon atypeList)\n"); }
            | '(' type ',' typeListComma ')'
            { LOG_PARSER("## PARSER ## make generalInst - (type, typeListComma)\n"); }
            | '(' ')'
            { LOG_PARSER("## PARSER ## make generalInst - ()\n"); }
            | '[' type ']'
            { LOG_PARSER("## PARSER ## make generalInst - [type]\n"); }
            | '(' btype RARROW type ')'
            { LOG_PARSER("## PARSER ## make generalInst - (btype => type)\n"); }
            ;

context : '(' contextList ')'
        { LOG_PARSER("## PARSER ## make context - (contextList)\n"); }
        | class
        { LOG_PARSER("## PARSER ## make context - class\n"); }
        ;

contextList : class
            { LOG_PARSER("## PARSER ## make contextList - class\n"); }
            | contextList ',' class
            { LOG_PARSER("## PARSER ## make contextList - contextList, class\n"); }
            ;

class : tycon tyvar
      { LOG_PARSER("## PARSER ## make class - tycon tyvar\n"); }
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
