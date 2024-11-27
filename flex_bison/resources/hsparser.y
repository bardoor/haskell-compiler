%require "3.2"
%locations

%{

#include <BisonUtils.hpp>
#include <typeinfo>

extern int yylex();
extern int yylineno;

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

%nonassoc LOWER_THAN_TYPED_EXPR

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
             symbols tuple list op comprehension altList declList enumeration lampats apat tycon opat pats fpat dpat
             classDecl classBody context class instDecl restrictInst rinstOpt generalInst valDefList valDef 
             valrhs valrhs1 whereOpt guardrhs guard tyvar tyvarList tyvarListComma type atype btype ttype ntatype typeListComma atypeList contextList
             dataDecl simpleType constrList tyClassList conop tyClassListComma tyClass typeDecl defaultDecl defaultTypes stmt stmts

/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <str> STRINGC SYMS CHARC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token <intVal> INTC
%token <floatVal> FLOATC
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW  

%start module

%%


/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { mk_literal($$, "int", std::to_string($1)); }
        | FLOATC    { mk_literal($$, "float", std::to_string($1)); }
        | STRINGC   { mk_literal($$, "str", $1->substr()); }
        | CHARC     { mk_literal($$, "char", $1->substr()); }
        ;

expr : oexpr DCOLON type { mk_typed_expr($$, $1, $3); }
     | oexpr             { $$ = $1; } %prec LOWER_THAN_TYPED_EXPR
     ;

oexpr : oexpr op oexpr %prec '+'   { mk_bin_expr($$, $1, $2, $3); }
      | dexpr                      { $$ = $1; }
      ;

dexpr : '-' kexpr        { mk_negate_expr($$, $2); }
      | kexpr            { $$ = $1; }
      ;

kexpr : '\\' lampats RARROW expr            { mk_lambda($$, $2, $4); }
      | LETKW '{' declList '}' INKW expr    { mk_let_in($$, $3, $6); }
      | IFKW expr THENKW expr ELSEKW expr   { mk_if_else($$, $2, $4, $6); }
      | DOKW '{' stmts '}'                  { mk_do($$, $3); }
      | CASEKW expr OFKW '{' altList '}'    { mk_case($$, $2, $5); }
      | fapply                              { $$ = $1; }
      ;

fapply : fapply aexpr        { mk_fapply($$, $1, $2); }
       | aexpr               { mk_fapply($$, $1, NULL); }
       ;

aexpr : literal         { mk_expr($$, $1); }
      | funid           { mk_expr($$, $1); }
      | '(' expr ')'    { $$ = $2; }
      | tuple           { mk_expr($$, $1); }
      | list            { mk_expr($$, $1); }
      | enumeration     { mk_expr($$, $1); }
      | comprehension   { mk_expr($$, $1); }
      | WILDCARD        
      ;


/* Оператор */
op : symbols                { LOG_PARSER("## PARSER ## make op - symbols\n"); $$ = new Node(); $$->val = { {"type", "symbols"}, {"repr", $1->val} }; }
   | BQUOTE funid BQUOTE    { LOG_PARSER("## PARSER ## make op - `op`\n"); $$ = new Node(); $$->val = { {"type", "quoted"}, {"id", $2->val} }; }
   | '+'                    { LOG_PARSER("## PARSER ## make op - plus\n"); $$ = new Node(); $$->val = { {"type", "symbols"}, {"repr", "+"} }; }
   | '-'                    { LOG_PARSER("## PARSER ## make op - minus\n"); $$ = new Node(); $$->val = { {"type", "symbols"}, {"repr", "-"} }; }
   ;

symbols : SYMS    { LOG_PARSER("## PARSER ## make symbols\n"); $$ = new Node(); $$->val = { {"symbols", $1->substr()} }; }
        ;

funid : FUNC_ID   { LOG_PARSER("## PARSER ## make funid\n"); $$ = new Node(); $$->val = { {"funid",  $1->substr()} }; }
      ;

stmts : stmt        { LOG_PARSER("## PARSER ## make stmts - stmt\n"); $$ = new Node(); $$->val.push_back($1->val); }
      | stmts stmt  { LOG_PARSER("## PARSER ## make stmts - stmts stmt\n"); $$ = new Node(); $$->val = $1->val; $$->val.push_back($2->val); }
      ;

stmt : expr LARROW expr ';'   { LOG_PARSER("## PARSER ## make stmt - expr <- expr;\n"); $$ = new Node(); $$->val = { {"binding", { {"left", {$1->val}}, {"right", {$3->val}} }} }; }
     | expr ';'               { LOG_PARSER("## PARSER ## make stmt - expr;\n"); $$ = new Node(); $$->val.push_back($1->val); }
     | ';'                    { LOG_PARSER("## PARSER ## make stmt - ;\n"); $$ = new Node(); }
     ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

tuple : '(' expr ',' commaSepExprs ')'  { LOG_PARSER("## PARSER ## make tuple - (expr, expr, ...)\n"); $$ = new Node(); $$->val["tuple"] = $4->val; $$->val["tuple"].push_back($2->val); }
      | '(' ')'                         { LOG_PARSER("## PARSER ## make tuple - ( )\n"); $$ = new Node(); $$->val["tuple"] = json::array(); }
      ;

comprehension : '[' expr '|' commaSepExprs ']'
              ;

list : '[' ']'                          { LOG_PARSER("## PARSER ## make list - [ ]\n"); $$ = new Node(); $$->val["list"] = json::array(); }
     | '[' commaSepExprs ']'            { LOG_PARSER("## PARSER ## make list - [ commaSepExprs ]\n"); $$ = new Node(); $$->val["list"] = $2->val; }
     ;

commaSepExprs : expr                    { LOG_PARSER("## PARSER ## make commaSepExprs - expr\n"); $$ = new Node();  $$->val.push_back($1->val); }
              | expr ',' commaSepExprs  { LOG_PARSER("## PARSER ## make commaSepExprs - expr ',' commaSepExprs\n"); $$ = $3; $$->val.push_back($1->val); }
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 ... и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

enumeration : '[' expr DOTDOT ']'               { LOG_PARSER("## PARSER ## make enumeration - [ expr .. ]\n"); $$ = new Node(); $$->val = { {"range", { {"start", $2->val} }} }; }
            | '[' expr DOTDOT expr ']'          { LOG_PARSER("## PARSER ## make enumeration - [ expr .. expr ]\n"); $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"end", $4->val} }} }; }
            | '[' expr ',' expr DOTDOT expr ']' { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. expr ]\n"); $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"second", $4->val}, {"end", $6->val} }} }; }
            | '[' expr ',' expr DOTDOT ']'      { LOG_PARSER("## PARSER ## make enumeration - [ expr, expr .. ]\n"); $$ = new Node(); $$->val = { {"range", { {"start", $2->val}, {"second", $4->val} }} }; }  
            ;


/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

lampats :  apat lampats	 { LOG_PARSER("## PARSER ## make lambda pattern - apat lampats\n"); $$ = new Node(); $$->val = $2->val; $$->val.push_back($1->val); }
	  |  apat          { LOG_PARSER("## PARSER ## make lambda pattern - apat\n"); $$ = new Node(); $$->val.push_back($1->val); }
	  ;

/* Список паттернов */
pats : pats ',' opat      { LOG_PARSER("## PARSER ## make pattern list - pats, opat\n");  $$ = new Node(); $$->val = $1->val; $$->val.push_back($3->val); }
     | opat               { LOG_PARSER("## PARSER ## make pattern list - opat\n"); $$ = new Node(); $$->val.push_back($1->val); }
     ;

opat : dpat                   { LOG_PARSER("## PARSER ## make optional pattern - dpat\n"); $$ = new Node(); $$->val = $1->val; }
     | opat op opat %prec '+' { LOG_PARSER("## PARSER ## make optional pattern - opat op opat\n"); $$ = new Node(); $$->val = { {"left", {$1->val}, {"op", {$2->val}},{"right", {$3->val}}} }; }
     ;

dpat : '-' fpat           { LOG_PARSER("## PARSER ## make dpat - '-' fpat\n"); $$ = new Node(); $$->val = {{"uminus", {$2->val}}}; }
     | fpat               { LOG_PARSER("## PARSER ## make dpat - fpat\n"); $$ = new Node(); $$->val = $1->val; }
     ;

fpat : fpat apat  {
            if ($2->val.is_array()) {
                  $2->val["apats"].push_back($1->val);
                  $$ = new Node();
                  $$->val = $2->val;
            }
            else {
                  $$ = new Node();
                  $$->val["fpat"] = json::array();
                  $$->val["fpat"].push_back($1->val);
                  $$->val["fpat"].push_back($2->val);
            }
            LOG_PARSER("## PARSER ## make fpat - fpat apat\n");
     }
     | apat               { $$ = new Node(); $$->val = $1->val; LOG_PARSER("## PARSER ## make fpat - apat\n"); }
     ;

/* Примитивные паттерны */
apat : funid                  { LOG_PARSER("## PARSER ## make apat - funid\n"); $$ = new Node(); $$->val = { {"pattern", $1->val } }; }
     | tycon                  { LOG_PARSER("## PARSER ## make apat - CONSTRUCTOR_ID\n"); $$ = new Node(); $$->val = { {"pattern", $1->val } }; }
     | literal                { LOG_PARSER("## PARSER ## make apat - literal\n"); $$ = new Node(); $$->val = { {"pattern", $1->val } }; }
     | WILDCARD               { LOG_PARSER("## PARSER ## make apat - WILDCARD\n"); $$ = new Node(); $$->val = { {"pattern", "wildcard" } }; }
     | '(' ')'                { LOG_PARSER("## PARSER ## make apat - ()\n"); $$ = new Node(); $$->val = { {"pattern", {"tuple", json::array()} } }; }
     | '(' opat ',' pats ')'  { LOG_PARSER("## PARSER ## make apat - (opat, pats)\n"); $$ = new Node(); $$->val["pattern"]["tuple"] = $4->val; $$->val["pattern"]["tuple"].insert($$->val["pattern"]["tuple"].begin(), $2->val); }
     | '[' pats ']'           { LOG_PARSER("## PARSER ## make apat - [pats]\n"); $$ = new Node(); $$->val = { {"pattern", $2->val } }; }
     | '[' ']'                { LOG_PARSER("## PARSER ## make apat - []\n"); $$ = new Node(); $$->val = { {"pattern", {"list", json::array()} } }; }
     | '~' apat               { LOG_PARSER("## PARSER ## make apat - ~apat\n"); $$ = new Node(); $$->val = { {"pattern", $2->val } }; }
     ;

apatList : apat               { LOG_PARSER("## PARSER ## make apatList - apat\n"); $$ = new Node(); $$->val.push_back($1->val); }
         | apatList apat      { LOG_PARSER("## PARSER ## make apatList - apat\n"); $$ = new Node(); $$->val = $1->val; $$->val.push_back($2->val); }
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
var : funid                  { LOG_PARSER("## PARSER ## make variable - funid\n"); $$ = new Node(); $$->val = $1->val;  }
    | '(' symbols ')'        { LOG_PARSER("## PARSER ## make variable - (symbols)\n"); $$ = new Node(); $$->val = $2->val; }
    ;

/* Объявление */
declE : var '=' expr                    { LOG_PARSER("## PARSER ## make declaration - var = expr\n"); $$ = new Node(); $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} };  }
      | funlhs '=' expr                 { LOG_PARSER("## PARSER ## make declaration - funclhs = expr\n"); $$ = new Node(); $$->val = { {"decl", { {"left", $1->val}, {"right", $3->val} }} }; }
      | varList DCOLON type DARROW type { LOG_PARSER("## PARSER ## make declaration - varList :: type => type\n"); }
      | varList DCOLON type             { LOG_PARSER("## PARSER ## make declaration - varList :: type\n"); }
      | %empty                          { LOG_PARSER("## PARSER ## make declaration - nothing\n");  $$ = new Node(); $$->val = { {"decl", {}}}; }
      ;

whereOpt : WHEREKW '{' declList '}' { LOG_PARSER("## PARSER ## make where option - WHERE declList\n"); }
         | %empty                   { LOG_PARSER("## PARSER ## make where option - nothing\n"); }
         ;

funlhs : var apatList               { $$ = new Node(); $$->val = { {"funlhs", {{"name", $1->val}, {"params", $2->val}} } }; LOG_PARSER("## PARSER ## make funlhs - var apatList\n"); }
       ;

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

module : MODULEKW tycon WHEREKW body
       { LOG_PARSER("## PARSER ## make module - MODULE CONSTRUCTOR_ID WHERE body\n"); }
       | body
       { LOG_PARSER("## PARSER ## make module - body\n"); root = { {"module", { {"name", 0}, {"decls", $1->val} }} }; }
       ;

body : '{' topDeclList '}'
     { LOG_PARSER("## PARSER ## make body - { topDeclList }\n"); $$ = new Node(); $$->val = $2->val; }
     ;

topDeclList : topDecl
            { LOG_PARSER("## PARSER ## make topDeclList - topDecl\n"); $$ = new Node(); $$->val.push_back($1->val); }
            | topDeclList ';' topDecl
            { LOG_PARSER("## PARSER ## make topDeclList - topDeclList ; topDecl\n"); $$ = new Node(); $$->val = $1->val; $$->val.push_back($3->val); }
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
        { LOG_PARSER("## PARSER ## make topDecl - declE\n"); $$ = new Node(); $$->val = $1->val; }
        ;

/* ------------------------------- *
 *       Классы, instance          *
 * ------------------------------- */

classDecl : CLASSKW context DARROW class classBody
          { LOG_PARSER("## PARSER ## make classDecl - CLASS context => class classBody\n"); $$ = new Node(); $$->val = {{"class_decl", {{"context", $2->val}, {"class", $4->val},{"body", $5->val}}}}; }
          | CLASSKW class classBody
          { LOG_PARSER("## PARSER ## make classDecl - CLASS class classBody\n"); $$ = new Node(); $$->val = {{"class_decl", {{"class", $2->val},{"body", $3->val}}}}; }
          ;

classBody : %empty
          { LOG_PARSER("## PARSER ## make classBody - nothing\n"); $$ = new Node(); $$->val = nullptr; }
          | WHEREKW '{' declList '}'
          { LOG_PARSER("## PARSER ## make classBody - WHERE { declList }\n"); $$ = new Node(); $$->val =  $3->val; }
          ;

instDecl : INSTANCEKW context DARROW tycon restrictInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE context => tycon restrictInst rinstOpt\n"); $$ = new Node(); $$->val = {{"inst_decl", {{"context", $2->val}, {"tycon", $4->val}, {"restrictInst", $5->val}, {"rinstOpt", $6->val}}}}; }
         | INSTANCEKW tycon generalInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE tycon generalInst rinstOpt\n"); $$ = new Node(); $$->val = {{"inst_decl", {{"tycon", $2->val}, {"generalInst", $3->val}, {"rinstOpt", $4->val}}}}; }
         ;

rinstOpt : %empty
         { LOG_PARSER("## PARSER ## make rinstOpt - nothing\n"); $$ = new Node(); $$->val = {{"rinstOpt", nullptr}}; }
         | WHEREKW '{' valDefList '}'
         { LOG_PARSER("## PARSER ## make rinstOpt - WHERE { valDefList }\n"); $$ = new Node(); $$->val = {{"rinstOpt", $3->val}}; }
         ;

valDefList : %empty
            { LOG_PARSER("## PARSER ## make valDefList - nothing\n"); $$ = new Node(); $$->val = {{"valDefList", json::array()}}; }
            | valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef\n"); $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val})}}; }
            | valDef ';' valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef ; valDef\n"); $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val, $3->val})}}; }
            ;

valDef : opat valrhs
       { LOG_PARSER("## PARSER ## make valDef - opat valrhs\n"); $$ = new Node(); $$->val = {{"valDef", {{"opat", $1->val},{"valrhs", $2->val}}}}; }
       ;


/* Правосторонее значение */
valrhs : valrhs1 whereOpt
       { LOG_PARSER("## PARSER ## make valrhs - valrhs1 whereOpt\n"); $$ = new Node(); $$->val = {{"valrhs", {{"valrhs1", $1->val},{"whereOpt", $2->val}}}}; }
       ;

valrhs1 : guardrhs
        { LOG_PARSER("## PARSER ## make valrhs1 - guardrhs\n"); $$ = new Node(); $$->val = {{"valrhs1", {{"guardrhs", $1->val}}}}; }
        | '=' expr
        { LOG_PARSER("## PARSER ## make valrhs1 - = expr\n"); $$ = new Node(); $$->val = {{"valrhs1", {{"expr", $2->val}}}}; }
        ;

guardrhs : guard '=' expr
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr\n"); $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val}}}}; }
         | guard '=' expr guardrhs
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr guardrhs\n"); $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val},{"guardrhs", $4->val}}}}; }
         ;

restrictInst : tycon
             { LOG_PARSER("## PARSER ## make restrictInst - tycon\n"); $$ = new Node(); $$->val = {{"restrictInst", $1->val}}; }
             | '(' tycon tyvarList ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tycon tyvarList)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tycon", $2->val}, {"tyvarList", $3->val}}}}; }
             | '(' tyvar ',' tyvarListComma ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar, tyvarListComma)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}, {"tyvarListComma", $4->val}}}}; }
             | '(' ')'
             { LOG_PARSER("## PARSER ## make restrictInst - ()\n"); $$ = new Node(); $$->val = {{"restrictInst", json::array()}}; }
             | '[' tyvar ']'
             { LOG_PARSER("## PARSER ## make restrictInst - [tyvar]\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}}}}; }
             | '(' tyvar RARROW tyvar ')'
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar => tyvar)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"from", $2->val}, {"to", $4->val}}}}; }
             ;

generalInst : tycon
            { LOG_PARSER("## PARSER ## make generalInst - tycon\n"); $$ = new Node(); $$->val = {{"generalInst", $1->val}}; }
            | '(' tycon atypeList ')'
            { LOG_PARSER("## PARSER ## make generalInst - (tycon atypeList)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"tycon", $2->val}, {"atypeList", $3->val}}}}; }
            | '(' type ',' typeListComma ')'
            { LOG_PARSER("## PARSER ## make generalInst - (type, typeListComma)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}, {"typeListComma", $4->val}}}}; }
            | '(' ')'
            { LOG_PARSER("## PARSER ## make generalInst - ()\n"); $$ = new Node(); $$->val = {{"generalInst", json::array()}}; }
            | '[' type ']'
            { LOG_PARSER("## PARSER ## make generalInst - [type]\n"); $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}}}}; }
            | '(' btype RARROW type ')'
            { LOG_PARSER("## PARSER ## make generalInst - (btype => type)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"from", $2->val},{"to", $4->val}}}}; }
            ;

context : '(' contextList ')'
        { LOG_PARSER("## PARSER ## make context - (contextList)\n"); $$ = new Node(); $$->val = $2->val; }
        | class
        { LOG_PARSER("## PARSER ## make context - class\n"); $$ = new Node(); $$->val = $1->val; }
        ;

contextList : class
            { LOG_PARSER("## PARSER ## make contextList - class\n"); $$ = new Node(); $$->val = {{"contextList", { $1->val }}}; }
            | contextList ',' class
            { LOG_PARSER("## PARSER ## make contextList - contextList, class\n"); $$ = new Node(); $$->val = $1->val; $$->val["contextList"].push_back($3->val); }
            ;

class : tycon tyvar
      { LOG_PARSER("## PARSER ## make class - tycon tyvar\n"); $$ = new Node(); $$->val = {{"tycon", $1->val},{"tyvar", $2->val}}; }
      ;

/* ------------------------------- *
 *              data               *
 * ------------------------------- */

dataDecl : DATAKW context DARROW simpleType '=' constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}}}}; }
         | DATAKW simpleType '=' constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}}}}; }
         | DATAKW context DARROW simpleType '=' constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}, {"deriving", $8->val}}}}; }
         | DATAKW simpleType '=' constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}, {"deriving", $6->val}}}}; }
         ;

constrList : tycon atypeList
           { LOG_PARSER("## PARSER ## make constrList - tycon atypeList\n"); $$ = new Node(); $$->val = {{"constrList", {{"tycon", $1->val}, {"atypeList", $2->val}}}}; }
           | '(' SYMS ')' atypeList
           { LOG_PARSER("## PARSER ## make constrList - (SYMS) atypeList\n"); $$ = new Node(); $$->val = {{"constrList", {{"syms", $2->substr()}, {"atypeList", $4->val}}}}; }
           | '(' SYMS ')'
           { LOG_PARSER("## PARSER ## make constrList - (SYMS)\n"); $$ = new Node(); $$->val = {{"constrList", {{"syms", $2->substr()}}}}; }
           | tycon
           { LOG_PARSER("## PARSER ## make constrList - tycon\n"); $$ = new Node(); $$->val = {{"constrList", {{"tycon", $1->val}}}}; }
           | btype conop btype
           { LOG_PARSER("## PARSER ## make constrList - btype conop btype\n"); $$ = new Node(); $$->val = {{"constrList", {{"btype1", $1->val}, {"conop", $2->val}, {"btype2", $3->val}}}}; }
           ;

conop : SYMS
      { LOG_PARSER("## PARSER ## make conop - SYMS\n"); $$ = new Node(); $$->val = {{"conop", $1->substr()}}; }
      | BQUOTE CONSTRUCTOR_ID BQUOTE
      { LOG_PARSER("## PARSER ## make conop - `CONSTRUCTOR_ID`\n"); $$ = new Node(); $$->val = {{"conop", $2->substr()}}; }
      ;

tyClassList : '(' tyClassListComma ')'
            { LOG_PARSER("## PARSER ## make tyClassList - (tyClassListComma)\n"); $$ = new Node(); $$->val = {{"tyClassList", $2->val}}; }
            | '(' ')'
            { LOG_PARSER("## PARSER ## make tyClassList - ()\n"); $$ = new Node(); $$->val = {{"tyClassList", json::array()}}; }
            | tyClass
            { LOG_PARSER("## PARSER ## make tyClassList - tyClass\n"); $$ = new Node(); $$->val = {{"tyClassList", $1->val}}; }
            ;

tyClassListComma : tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClass\n"); $$ = new Node(); $$->val = {{"tyClassListComma", {$1->val}}}; }
                 | tyClassListComma ',' tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClassListComma, tyClass\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyClassListComma"].push_back($3->val); }
                 ;

tyClass : tycon
        { LOG_PARSER("## PARSER ## make tyClass - tycon\n"); $$ = new Node(); $$->val = {{"tyClass", $1->val}}; }
        ;

typeDecl : TYPEKW simpleType '=' type
         { LOG_PARSER("## PARSER ## make typeDecl - TYPE simpleType = type\n"); $$ = new Node(); $$->val = {{"typeDecl", {{"simpleType", $2->val}, {"type", $4->val}}}}; }
         ;

simpleType : tycon
           { LOG_PARSER("## PARSER ## make simpleType - tycon\n"); $$ = new Node(); $$->val = {{"simpleType", {{"tycon", $1->val}}}}; }
           | tycon tyvarList
           { LOG_PARSER("## PARSER ## make simpleType - tycon tyvarList\n"); $$ = new Node(); $$->val = {{"simpleType", {{"tycon", $1->val}, {"tyvarList", $2->val}}}}; }
           ;

tycon : CONSTRUCTOR_ID
      { LOG_PARSER("## PARSER ## make tycon - CONSTRUCTOR_ID\n"); $$ = new Node(); $$->val = $1->substr(); }
      ;

tyvarList : tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvar\n"); $$ = new Node(); $$->val = {{"tyvarList", {{"tyvar", $1->val}}}}; }
          | tyvarList tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvarList tyvar\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyvarList"].push_back($2->val); }
          ;

tyvarListComma : tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvar\n"); $$ = new Node(); $$->val = {{"tyvarListComma", {{"tyvar", $1->val}}}}; }
               | tyvarList ',' tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvarList, tyvar\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyvarListComma"].push_back($3->val); }
               ;

tyvar : funid
      { LOG_PARSER("## PARSER ## make tyvar - funid\n"); $$ = new Node();  $$->val = {{"funid", $1->val}}; }
      ;

defaultDecl : DEFAULTKW defaultTypes
            { LOG_PARSER("## PARSER ## make defaultDecl - DEFAULT defaultTypes\n"); $$ = new Node(); $$->val = {{"defaultDecl", {{"defaultTypes", $2->val}}}}; }
            ;

defaultTypes : '(' type ',' typeListComma ')'
             { LOG_PARSER("## PARSER ## make defaultTypes - (type, typeListComma)\n"); $$ = new Node(); $$->val = {{"defaultTypes", {{"type", $2->val}, {"typeListComma", $4->val}}}}; }
             | ttype
             { LOG_PARSER("## PARSER ## make defaultTypes - ttype\n"); $$ = new Node(); $$->val = {{"defaultTypes", $1->val}}; }
             ;


/* ------------------------------- *
 *              Типы               *
 * ------------------------------- */

type : btype
     { LOG_PARSER("## PARSER ## make type - btype\n"); $$ = new Node(); $$->val = $1->val; }
     | btype RARROW type
     { LOG_PARSER("## PARSER ## make type - btype -> type\n"); $$ = $3; $$->val.push_back($1->val); }
     ;

btype : atype
      { LOG_PARSER("## PARSER ## make btype - atype\n"); $$ = $1; }
      | tycon atypeList
      { LOG_PARSER("## PARSER ## make btype - tycon atypeList\n"); $$ = new Node(); $$->val = { {"overlay", { {"constructor", $1->val}, {"type_list", $2->val} }} }; }
      ;

atype : ntatype
      { LOG_PARSER("## PARSER ## make atype - ntatype\n"); $$ = $1; }
      | '(' type ',' typeListComma ')'
      { LOG_PARSER("## PARSER ## make atype - (type, typeListComma)\n"); $$ = $4; $$->val.push_back($2->val); }
      ;

atypeList : atypeList atype
          { LOG_PARSER("## PARSER ## make atypeList - atypeList atype\n"); $$ = $1; $$->val.push_back($2->val); }
          | atype
          { LOG_PARSER("## PARSER ## make atypeList - atype\n"); $$ = new Node(); $$->val.push_back($1->val); }
          ;

ttype : ntatype
      { LOG_PARSER("## PARSER ## make ttype - ntatype\n"); $$ = $1; }
      | btype RARROW type
      { LOG_PARSER("## PARSER ## make ttype - btype -> type\n"); $$ = $1; $$->val["to"] = $3->val; }
      | tycon atypeList
      { LOG_PARSER("## PARSER ## make ttype - tycon atypeList\n"); $$ = new Node(); $$->val = { {"overlay", { {"constructor", $1->val}, {"type_list", $2->val} }} }; }
      ;

ntatype : tyvar
        { LOG_PARSER("## PARSER ## make ntatype - tyvar\n"); $$ = $1; }
        | tycon
        { LOG_PARSER("## PARSER ## make ntatype - tycon\n"); $$ = $1; }
        | '(' ')'
        { LOG_PARSER("## PARSER ## make ntatype - ()\n"); $$ = new Node(); $$->val = {{"tuple", json::array()}}; }
        | '(' type ')'
        { LOG_PARSER("## PARSER ## make ntatype - (type)\n"); $$ = new Node(); $$->val = {{"tuple", $2->val}}; }
        | '[' type ']'
        { LOG_PARSER("## PARSER ## make ntatype - [type]\n"); $$ = new Node(); $$->val = {{"list", $2->val}}; }
        ;

typeListComma : type
              { LOG_PARSER("## PARSER ## make typeListComma - type\n"); $$ = new Node(); $$->val.push_back($1->val); }
              | type ',' typeListComma
              { LOG_PARSER("## PARSER ## make typeListComma - type, typeListComma\n"); $$ = $3; $$->val.push_back($1->val); }
              ;

%%

void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
