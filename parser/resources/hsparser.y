%require "3.2"
%locations
%define parse.error custom

%{

#include <JsonBuild.hpp>
#include <Token.hpp>

#define RED "\033[31m"
#define RESET "\033[0m"

extern std::vector<IndentedToken>::iterator tokensIter;
extern std::vector<IndentedToken>::iterator tokensEnd;
extern std::vector<std::string> lines;
extern int yylineno;
int column = 0;

void yyerror(const char* err);

int yylex();

json root;

%}

%union {
      struct Node* node;
      std::string* str;
}


/* ------------------------------- *
 *           Приоритеты            *
 * ------------------------------- */

%nonassoc LOWER_THAN_TYPED_EXPR

%right APPLICATION

%right OR

%right AND

%nonassoc LOG_EQ NEQ LT GT LEQ GEQ

%right CONCAT COLON

%left PLUS MINUS

%left MUL DIV

%right POWER

%left INDEX

%right COMPOSE

%left	CASE		LET	IN		LAMBDA
  	IF		ELSE

%left BQUOTE

%left DCOLON

%left SEMICOL COMMA

%left OPAREN OBRACKET OCURLY VOCURLY

%left EQ

%right DARROW
%right RARROW

%type <node> literal expr oexpr dexpr kexpr fapply aexpr module body funlhs topDeclList topDecl declE var apatList commaSepExprs
             tuple list comprehension altList declList range lampats apat opat pats fpat dpat
             classDecl classBody context class instDecl restrictInst rinstOpt generalInst valDefList valDef varList
             valrhs valrhs1 whereOpt guardrhs guard tyvar tyvarList tyvarListComma type atype btype ttype ntatype typeListComma atypeList contextList
             dataDecl simpleType constrList constr tyClassList conop tyClassListComma tyClass typeDecl defaultDecl defaultTypes stmt stmts commaSepStmts

%type <str> funid symbols tycon

/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <str> STRINGC SYMS CHARC INTC FLOATC FUNC_ID CONSTRUCTOR_ID
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE PLUS MINUS COMMA EQ
%token LOG_EQ NEQ LT GT LEQ GEQ OR AND INDEX POWER MUL DIV COMPOSE APPLICATION CONCAT COLON DOT
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW VARKW VOCURLY VCCURLY OPAREN CPAREN OBRACKET CBRACKET OCURLY CCURLY LAZY BACKSLASH

%start module

%%

/*
TODO
    1. case
*/

/* ------------------------------- *
 *            Выражения            *
 * ------------------------------- */

literal : INTC      { $$ = mk_literal("int", *$1); }
        | FLOATC    { $$ = mk_literal("float", *$1); }
        | STRINGC   { $$ = mk_literal("str", *$1); }
        | CHARC     { $$ = mk_literal("char", *$1); }
        ;

/* 
      Типизированные выражения:
      1 + 2 :: Int 

      Выражения без типа:
      1 + 2

      TODO выражение с типом и контекстом
      1 + 2 :: (Integer a) => a
*/
expr : oexpr DCOLON type { $$ = mk_typed_expr($1, $3); }
     | oexpr             { $$ = $1; } %prec LOWER_THAN_TYPED_EXPR
     ;

/*
      Бинарное выражение с оператором
      a + b
      a `fun` b
*/
oexpr : oexpr BQUOTE funid BQUOTE oexpr { $$ = mk_bin_expr($1, mk_operator("quoted", $3->substr()), $5); }
      | oexpr LOG_EQ oexpr  { $$ = mk_bin_expr($1, mk_operator("eq", "=="), $3); }
      | oexpr NEQ oexpr     { $$ = mk_bin_expr($1, mk_operator("neq", "/="), $3); }
      | oexpr LT oexpr      { $$ = mk_bin_expr($1, mk_operator("lt", "<"), $3); }
      | oexpr GT oexpr      { $$ = mk_bin_expr($1, mk_operator("gt", ">"), $3); }
      | oexpr LEQ oexpr     { $$ = mk_bin_expr($1, mk_operator("leq", ">="), $3); }
      | oexpr GEQ oexpr     { $$ = mk_bin_expr($1, mk_operator("geq", "<="), $3); }
      | oexpr OR oexpr      { $$ = mk_bin_expr($1, mk_operator("or", "||"), $3); }
      | oexpr AND oexpr     { $$ = mk_bin_expr($1, mk_operator("and", "&&"), $3); }
      | oexpr PLUS oexpr    { $$ = mk_bin_expr($1, mk_operator("plus", "+"), $3); }
      | oexpr MINUS oexpr   { $$ = mk_bin_expr($1, mk_operator("minus", "-"), $3); }
      | oexpr CONCAT oexpr  { $$ = mk_bin_expr($1, mk_operator("concat", "++"), $3); }
      | oexpr COLON oexpr   { $$ = mk_bin_expr($1, mk_operator("cons", ":"), $3); }
      | oexpr POWER oexpr   { $$ = mk_bin_expr($1, mk_operator("power", "**"), $3); }
      | oexpr MUL oexpr     { $$ = mk_bin_expr($1, mk_operator("mul", "*"), $3); }
      | oexpr DIV oexpr     { $$ = mk_bin_expr($1, mk_operator("div", "/"), $3); }
      | oexpr DOT oexpr     { $$ = mk_bin_expr($1, mk_operator("dot", "."), $3); }
      | oexpr INDEX oexpr   { $$ = mk_bin_expr($1, mk_operator("index", "["), $3); }
      | oexpr APPLICATION oexpr { $$ = mk_bin_expr($1, mk_operator("application", "$"), $3); }
      | dexpr               { $$ = $1; }
      ;

/*
      Унарный минус (других унарных выражений просто нет... (да, даже унарного плюса))
*/
dexpr : MINUS kexpr      { $$ = mk_negate_expr($2); }
      | kexpr            { $$ = $1; }
      ;

/*
      Выражения с ключевым словом
      1. лямбда-абстракция: \x y -> x + y
      2. let-выражение: let x = 1 in x
      3. if-выражение: if a > b then 2 else 3
      4. do-выражение: do { x = 1; print 5; x }
      5. case-выражение: case x of { 1 -> Just 2; _ -> Nothing }
*/
kexpr : BACKSLASH lampats RARROW expr             { $$ = mk_lambda($2, $4); }
      | LETKW OCURLY declList CCURLY INKW expr    { $$ = mk_let_in($3, $6); }
      | LETKW VOCURLY declList VCCURLY INKW expr  { $$ = mk_let_in($3, $6); }
      | IFKW expr THENKW expr ELSEKW expr         { $$ = mk_if_else($2, $4, $6); }
      | DOKW OCURLY stmts CCURLY                  { $$ = mk_do($3); }
      | DOKW VOCURLY stmts VCCURLY                { $$ = mk_do($3); }
      | CASEKW expr OFKW OCURLY altList CCURLY    { $$ = mk_case($2, $5); }
      | CASEKW expr OFKW VOCURLY altList VCCURLY  { $$ = mk_case($2, $5); }
      | fapply                                    { $$ = $1; }
      ;

/*
      Применение функции
*/
fapply : fapply aexpr        { $$ = mk_fapply($1, $2); }
       | aexpr               { $$ = mk_fapply($1, NULL); }
       ;

/*
      Атомарное выражение

      Также включает в себя часть паттернов для решения r/r конфликтов:
      (a,b,c) <- (1,2,3)
      Пока мы не дошли до стрелки, невозможно сказать - выражение это или паттерн
*/
aexpr : literal               { $$ = mk_expr($1); }
      | funid                 { $$ = mk_expr($1->substr()); }
      | OPAREN expr CPAREN    { $$ = $2; }
      | tuple                 { $$ = mk_expr($1); }
      | list                  { $$ = mk_expr($1); }
      | range                 { $$ = mk_expr($1); }
      | comprehension         { $$ = mk_expr($1); }
      | WILDCARD              { $$ = mk_simple_pat("wildcard"); }
      ;

symbols : SYMS    { $$ = $1; }
        ;

funid : FUNC_ID   { $$ = $1; }
      ;

stmts : stmt                { $$ = mk_stmts($1, NULL); }
      | stmts SEMICOL stmt  { $$ = mk_stmts($3, $1); }
      ;

/*
      Стейтменты в do выражении
      1. Биндинг: (a,b,c) <- (1,2,3)
            Примечание: По левую сторону на этапе парсинга невозможно понять - выражение это или паттерн
      2. Любое выражение
*/
stmt : expr LARROW expr    { $$ = mk_binding_stmt($1, $3); }
     | expr                { $$ = $1; }
     | %empty              { $$ = new Node(); }
     ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

/*
      Кортеж
      Либо пуст, либо 2 и более элементов
*/
tuple : OPAREN expr COMMA commaSepExprs CPAREN  { $$ = mk_tuple($2, $4); }
      | OPAREN CPAREN                           { $$ = mk_tuple(NULL, NULL); }
      ;

/*
      Списковое включение
      [x * x | x <- [1..10], even x]
*/
comprehension : OBRACKET expr VBAR commaSepStmts CBRACKET  { $$ = mk_comprehension($2, $4); }
              ;

list : OBRACKET CBRACKET                          { $$ = mk_list(NULL); }
     | OBRACKET commaSepExprs CBRACKET            { $$ = mk_list($2); }
     ;

commaSepExprs : expr                      { $$ = mk_comma_sep_exprs($1, NULL); }
              | expr COMMA commaSepExprs  { $$ = mk_comma_sep_exprs($1, $3); }
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 ... и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

commaSepStmts : stmt                      { $$ = mk_comma_sep_stmts($1, NULL); }
              | stmt COMMA commaSepStmts  { $$ = mk_comma_sep_stmts($1, $3); }
              ;

/*
      Диапазон
      [1..]       - от 1 до бесконечности
      [1..10]     - от 1 до 10
      [1,3..10]   - от 1 до 10 с шагом 2 
      [1,3..]     - от 1 до бесконечности с шагом 2
*/
range : OBRACKET expr DOTDOT CBRACKET                 { $$ = mk_range($2, NULL, NULL); }
      | OBRACKET expr DOTDOT expr CBRACKET            { $$ = mk_range($2, NULL, $4); }
      | OBRACKET expr COMMA expr DOTDOT expr CBRACKET { $$ = mk_range($2, $4, $6); }
      | OBRACKET expr COMMA expr DOTDOT CBRACKET      { $$ = mk_range($2, $4, NULL); }
      ;



/* ------------------------------- *
 *            Паттерны             *
 * ------------------------------- */

lampats :  apat lampats	 { $$ = mk_lambda_pats($1, $2); }
	  |  apat          { $$ = $1; }
	  ;

/* 
      Список паттернов
*/
pats : pats COMMA opat    { $$ = mk_pats($3, $1); }
     | opat               { $$ = $1; }
     ;

/*
      Паттерн с оператором
      x:xs = lst
*/
opat : dpat                    { $$ = $1; }
//     | opat op opat %prec PLUS { $$ = mk_bin_pat($1, $2, $3); }
     ;

/*
      Специально для мистера унарного минуса
*/
dpat : MINUS fpat   { $$ = mk_negate($2); }
     | fpat         { $$ = $1; }
     ;

/*
      Применение функции в паттерне
      case func x y of {...}
*/
fpat : fpat apat  { $$ = mk_fpat($1, $2); }
     | apat       { $$ = $1; }
     ;

/*
      Атомарный паттерн
      1. Идентификатор функции
      2. Конструктор типа
      3. Литерал
      4. _
      5. Списки, кортежи
      6. Ленивый паттерн
      7. TODO: AS-паттерн
*/
apat : funid                          { $$ = mk_simple_pat($1->substr()); }
     | tycon                          { $$ = mk_simple_pat($1->substr()); }
     | literal                        { $$ = mk_simple_pat($1); }
     | WILDCARD                       { $$ = mk_simple_pat("wildcard"); }
     | OPAREN CPAREN                  { $$ = mk_tuple_pat(NULL, NULL); }
     | OPAREN opat COMMA pats CPAREN  { $$ = mk_tuple_pat($2, $4); }
     ;

apatList : apat               { $$ = mk_pat_list(NULL, $1); }
         | apatList apat      { $$ = mk_pat_list($1, $2); }
         ;
/* 
      Альтернативы для case 
*/
altList : altList SEMICOL altE  { LOG_PARSER("## PARSER ## make alternative list - altList ; altE\n"); }
        | altE                  { LOG_PARSER("## PARSER ## make alternative list - altE\n"); }
        ;

altE : opat altRest         { LOG_PARSER("## PARSER ## make alternative - opat altRest\n"); }
     | %empty               { LOG_PARSER("## PARSER ## make alternative - nothing\n"); }
     ;

altRest : guardPat whereOpt    { LOG_PARSER("## PARSER ## make alternative rest - guardPat whereOpt\n"); }
        | RARROW expr whereOpt { LOG_PARSER("## PARSER ## make alternative rest - RARROW expr whereOpt\n"); }
        ;

guardPat : guard RARROW expr guardPat { LOG_PARSER("## PARSER ## make guard pattern - guard RARROW expr guardPat\n"); }
         | guard RARROW expr          { LOG_PARSER("## PARSER ## make guard pattern - guard RARROW expr\n"); }
         ;

guard : VBAR oexpr          { LOG_PARSER("## PARSER ## make guard - VBAR oexpr\n"); }
      ;

/* ------------------------------- *
 *           Объявления            *
 * ------------------------------- */

declList : declE                    { $$ = $1; }
         | declList SEMICOL declE   { $$ = mk_decl_list($1, $3); }
         ;

varList : varList COMMA var  { $$ = mk_var_list($1, $3); }
        | var                { $$ = $1; }
        ;

/* 
      Оператор в префиксной форме или идентификатор функции 
*/
var : funid                  { $$ = mk_var("funid", $1->substr()); }
    | OPAREN symbols CPAREN  { $$ = mk_var("symbols", *$2); }
    ;

/* 
      Объявление
      1. Биндинг функции
      2. Список функций с типом
*/
declE : var valrhs                      { $$ = mk_fun_decl($1, $2); }
      | funlhs valrhs                   { $$ = mk_fun_decl($1, $2); }
      | varList DCOLON type DARROW type { $$ = mk_typed_var_list($1, $3, $5); }
      | varList DCOLON type             { $$ = mk_typed_var_list($1, $3); }
      | %empty                          { $$ = mk_empty_decl(); }
      ;

whereOpt : WHEREKW OCURLY declList CCURLY   { $$ = mk_where($3); }
         | WHEREKW VOCURLY declList VCCURLY { $$ = mk_where($3); }
         | %empty                           { $$ = mk_where(NULL); }
         ;

funlhs : var apatList               { $$ = mk_funlhs($1, $2); }
       ;

/* ------------------------------- *
 *             Модуль              *
 * ------------------------------- */

module : MODULEKW tycon WHEREKW body
       { $$ = mk_module($2->substr(), $4); root = $$->val;  }
       | body
       { $$ = mk_module($1); root = $$->val; }
       ;

body : OCURLY topDeclList CCURLY
     { $$ = $2; }
     | VOCURLY topDeclList VCCURLY
     { $$ = $2; }
     ;

topDeclList : topDecl
            { $$ = $1; }
            | topDeclList SEMICOL topDecl
            { $$ = mk_top_decl_list($1, $3); }
            ;

topDecl : typeDecl
        { LOG_PARSER("## PARSER ## make topDecl - typeDecl\n"); $$ = $1; }
        | dataDecl
        { LOG_PARSER("## PARSER ## make topDecl - dataDecl\n"); $$ = $1; }
        | classDecl
        { LOG_PARSER("## PARSER ## make topDecl - classDecl\n"); $$ = $1; }
        | instDecl
        { LOG_PARSER("## PARSER ## make topDecl - instDecl\n"); $$ = $1; }
        | defaultDecl
        { LOG_PARSER("## PARSER ## make topDecl - defaultDecl\n"); $$ = $1; }
        | declE
        { $$ = $1; }
        ;

/* ------------------------------- *
 *       Классы, instance          *
 * ------------------------------- */

classDecl : CLASSKW context DARROW class classBody
          { $$ = mk_class_decl($2, $4, $5); }
          | CLASSKW class classBody
          { $$ = mk_class_decl(NULL, $2, $3); }
          ;

classBody : %empty
          { $$ = mk_class_body_empty(); }          
          | WHEREKW OCURLY declList CCURLY
          { $$ = mk_class_body_declList($3); }
          | WHEREKW VOCURLY declList VCCURLY
          { $$ = mk_class_body_declList($3); }
          ;

instDecl : INSTANCEKW context DARROW tycon restrictInst rinstOpt
         { $$ = mk_inst_decl_restrict($2, $4->substr(), $5, $6); }
         | INSTANCEKW tycon generalInst rinstOpt
         { $$ = mk_inst_decl_general($2->substr(), $3, $4); }
         ;

rinstOpt : %empty
         { $$ = mk_rinst_opt_empty(); }
         | WHEREKW OCURLY valDefList CCURLY
         { $$ = mk_rinst_opt($3); }
         | WHEREKW VOCURLY valDefList VCCURLY
         { $$ = mk_rinst_opt($3); }
         ;

valDefList : %empty
            { LOG_PARSER("## PARSER ## make valDefList - nothing\n"); $$ = new Node(); $$->val = {{"valDefList", json::array()}}; }
            | valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef\n"); $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val})}}; }
            | valDef SEMICOL valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef ; valDef\n"); $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val, $3->val})}}; }
            ;

valDef : opat valrhs
       { $$ = mk_val_def($1, $2); }
       ;


/* Правосторонее значение */
valrhs : valrhs1 whereOpt
       { $$ = mk_val_rhs($1, $2); } 
       ;

valrhs1 : guardrhs
        { LOG_PARSER("## PARSER ## make valrhs1 - guardrhs\n"); $$ = new Node(); $$->val = {{"valrhs1", {{"guardrhs", $1->val}}}}; }
        | EQ expr
        { LOG_PARSER("## PARSER ## make valrhs1 - = expr\n"); $$ = new Node(); $$->val = {{"valrhs1", $2->val}}; }
        ;

guardrhs : guard EQ expr
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr\n"); $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val}}}}; }
         | guard EQ expr guardrhs
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr guardrhs\n"); $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val},{"guardrhs", $4->val}}}}; }
         ;

restrictInst : tycon
             { LOG_PARSER("## PARSER ## make restrictInst - tycon\n"); $$ = new Node(); $$->val = {{"restrictInst", $1->substr()}}; }
             | OPAREN tycon tyvarList CPAREN
             { LOG_PARSER("## PARSER ## make restrictInst - (tycon tyvarList)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tycon", $2->substr()}, {"tyvarList", $3->val}}}}; }
             | OPAREN tyvar COMMA tyvarListComma CPAREN
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar, tyvarListComma)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}, {"tyvarListComma", $4->val}}}}; }
             | OPAREN CPAREN
             { LOG_PARSER("## PARSER ## make restrictInst - ()\n"); $$ = new Node(); $$->val = {{"restrictInst", json::array()}}; }
             | OBRACKET tyvar CBRACKET
             { LOG_PARSER("## PARSER ## make restrictInst - [tyvar]\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"tyvar", $2->val}}}}; }
             | OPAREN tyvar RARROW tyvar CPAREN
             { LOG_PARSER("## PARSER ## make restrictInst - (tyvar => tyvar)\n"); $$ = new Node(); $$->val = {{"restrictInst", {{"from", $2->val}, {"to", $4->val}}}}; }
             ;

generalInst : tycon
            { LOG_PARSER("## PARSER ## make generalInst - tycon\n"); $$ = new Node(); $$->val = {{"generalInst", $1->substr()}}; }
            | OPAREN tycon atypeList CPAREN
            { LOG_PARSER("## PARSER ## make generalInst - (tycon atypeList)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"tycon", $2->substr()}, {"atypeList", $3->val}}}}; }
            | OPAREN type COMMA typeListComma CPAREN
            { LOG_PARSER("## PARSER ## make generalInst - (type, typeListComma)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}, {"typeListComma", $4->val}}}}; }
            | OPAREN CPAREN
            { LOG_PARSER("## PARSER ## make generalInst - ()\n"); $$ = new Node(); $$->val = {{"generalInst", json::array()}}; }
            | OBRACKET type CBRACKET
            { LOG_PARSER("## PARSER ## make generalInst - [type]\n"); $$ = new Node(); $$->val = {{"generalInst", {{"type", $2->val}}}}; }
            | OPAREN btype RARROW type CPAREN
            { LOG_PARSER("## PARSER ## make generalInst - (btype => type)\n"); $$ = new Node(); $$->val = {{"generalInst", {{"from", $2->val},{"to", $4->val}}}}; }
            ;

context : OPAREN contextList CPAREN
        { $$ = mk_context_list($2); }
        | class
        { $$ = mk_context_class($1); }
        ;

contextList : class
            { LOG_PARSER("## PARSER ## make contextList - class\n"); $$ = new Node(); $$->val = {{"contextList", { $1->val }}}; }
            | contextList COMMA class
            { LOG_PARSER("## PARSER ## make contextList - contextList, class\n"); $$ = new Node(); $$->val = $1->val; $$->val["contextList"].push_back($3->val); }
            ;

class : tycon tyvar
      { $$ = mk_class($1->substr(), $2); }
      ;

/* ------------------------------- *
 *              data               *
 * ------------------------------- */

dataDecl : DATAKW context DARROW simpleType EQ constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}}}}; }
         | DATAKW simpleType EQ constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}}}}; }
         | DATAKW context DARROW simpleType EQ constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}, {"deriving", $8->val}}}}; }
         | DATAKW simpleType EQ constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}, {"deriving", $6->val}}}}; }
         ;

constrList : constr
           { $$ = mk_constr_list(NULL, $1); }
           | constrList VBAR constr
           { $$ = mk_constr_list($1, $3); }
           ;

constr : tycon atypeList
           { LOG_PARSER("## PARSER ## make constr - tycon atypeList\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()}, {"atypeList", $2->val}};  }
           | OPAREN SYMS CPAREN atypeList
           { LOG_PARSER("## PARSER ## make constr - (SYMS) atypeList\n"); $$ = new Node(); $$->val = {{"syms", $2->substr()}, {"atypeList", $4->val}}; }
           | OPAREN SYMS CPAREN
           { LOG_PARSER("## PARSER ## make constr - (SYMS)\n"); $$ = new Node(); $$->val = {{"syms", $2->substr()}}; }
           | tycon
           { LOG_PARSER("## PARSER ## make constr - tycon\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()}}; }
           | btype conop btype
           { LOG_PARSER("## PARSER ## make constr - btype conop btype\n"); $$ = new Node(); $$->val = {{"btype1", $1->val}, {"conop", $2->val}, {"btype2", $3->val}}; }
           ;

conop : SYMS
      { LOG_PARSER("## PARSER ## make conop - SYMS\n"); $$ = new Node(); $$->val = {{"conop", $1->substr()}}; }
      | BQUOTE CONSTRUCTOR_ID BQUOTE
      { LOG_PARSER("## PARSER ## make conop - `CONSTRUCTOR_ID`\n"); $$ = new Node(); $$->val = {{"conop", $2->substr()}}; }
      ;

tyClassList : OPAREN tyClassListComma CPAREN
            { LOG_PARSER("## PARSER ## make tyClassList - (tyClassListComma)\n"); $$ = new Node(); $$->val = {{"tyClassList", $2->val}}; }
            | OPAREN CPAREN
            { LOG_PARSER("## PARSER ## make tyClassList - ()\n"); $$ = new Node(); $$->val = {{"tyClassList", json::array()}}; }
            | tyClass
            { LOG_PARSER("## PARSER ## make tyClassList - tyClass\n"); $$ = new Node(); $$->val = {{"tyClassList", $1->val}}; }
            ;

tyClassListComma : tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClass\n"); $$ = new Node(); $$->val = {{"tyClassListComma", {$1->val}}}; }
                 | tyClassListComma COMMA tyClass
                 { LOG_PARSER("## PARSER ## make tyClassListComma - tyClassListComma, tyClass\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyClassListComma"].push_back($3->val); }
                 ;

tyClass : tycon
        { LOG_PARSER("## PARSER ## make tyClass - tycon\n"); $$ = new Node(); $$->val = {{"tyClass", $1->substr()}}; }
        ;

typeDecl : TYPEKW simpleType EQ type
         { LOG_PARSER("## PARSER ## make typeDecl - TYPE simpleType = type\n"); $$ = new Node(); $$->val = {{"typeDecl", {{"simpleType", $2->val}, {"type", $4->val}}}}; }
         ;

simpleType : tycon
           { LOG_PARSER("## PARSER ## make simpleType - tycon\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()}}; }
           | tycon tyvarList
           { LOG_PARSER("## PARSER ## make simpleType - tycon tyvarList\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()}, {"tyvarList", $2->val}}; }
           ;

tycon : CONSTRUCTOR_ID
      { $$ = $1; }
      ;

tyvarList : tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvar\n"); $$ = new Node(); $$->val = {{"tyvarList", {{"tyvar", $1->val}}}}; }
          | tyvarList tyvar
          { LOG_PARSER("## PARSER ## make tyvarList - tyvarList tyvar\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyvarList"].push_back($2->val); }
          ;

tyvarListComma : tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvar\n"); $$ = new Node(); $$->val = {{"tyvarListComma", {{"tyvar", $1->val}}}}; }
               | tyvarList COMMA tyvar
               { LOG_PARSER("## PARSER ## make tyvarListComma - tyvarList, tyvar\n"); $$ = new Node(); $$->val = $1->val; $$->val["tyvarListComma"].push_back($3->val); }
               ;

tyvar : funid
      { $$ = mk_tyvar($1->substr()); }
      ;

defaultDecl : DEFAULTKW defaultTypes
            { LOG_PARSER("## PARSER ## make defaultDecl - DEFAULT defaultTypes\n"); $$ = new Node(); $$->val = {{"defaultDecl", {{"defaultTypes", $2->val}}}}; }
            ;

defaultTypes : OPAREN type COMMA typeListComma CPAREN
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
     { LOG_PARSER("## PARSER ## make type - btype -> type\n"); $$ = $3; if ($$->val.is_array()) { $$->val.insert($$->val.begin(), $1->val); } else { $$ = new Node(); $$->val.push_back($1->val); $$->val.push_back($3->val); } }
     ;

btype : atype
      { LOG_PARSER("## PARSER ## make btype - atype\n"); $$ = $1; }
      | tycon atypeList
      { LOG_PARSER("## PARSER ## make btype - tycon atypeList\n"); $$ = new Node(); $$->val = { {"overlay", { {"constructor", $1->substr()}, {"type_list", $2->val} }} }; }
      ;

atype : ntatype
      { LOG_PARSER("## PARSER ## make atype - ntatype\n"); $$ = $1; }
      | OPAREN type COMMA typeListComma CPAREN
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
      { LOG_PARSER("## PARSER ## make ttype - tycon atypeList\n"); $$ = new Node(); $$->val = { {"overlay", { {"constructor", $1->substr()}, {"type_list", $2->val} }} }; }
      ;

ntatype : tyvar
        { LOG_PARSER("## PARSER ## make ntatype - tyvar\n"); $$ = $1; }
        | tycon
        { LOG_PARSER("## PARSER ## make ntatype - tycon\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()}}; }
        | OPAREN CPAREN
        { LOG_PARSER("## PARSER ## make ntatype - ()\n"); $$ = new Node(); $$->val = {{"tuple", json::array()}}; }
        | OPAREN type CPAREN
        { LOG_PARSER("## PARSER ## make ntatype - (type)\n"); $$ = new Node(); $$->val = {{"tuple", $2->val}}; }
        | OBRACKET type CBRACKET
        { LOG_PARSER("## PARSER ## make ntatype - [type]\n"); $$ = new Node(); $$->val = {{"list", $2->val}}; }
        ;

typeListComma : type
              { LOG_PARSER("## PARSER ## make typeListComma - type\n"); $$ = new Node(); $$->val.push_back($1->val); }
              | type COMMA typeListComma
              { LOG_PARSER("## PARSER ## make typeListComma - type, typeListComma\n"); $$ = $3; $$->val.push_back($1->val); }
              ;

%%

int yylex() {
    if (tokensIter == tokensEnd) {
        return YYEOF;
    }

    IndentedToken next = *tokensIter;
    yylval.str = new std::string(next.repr);
    yylineno = next.line;
    column = next.column;
    
    tokensIter++;
    return next.type;
}

void yyerror(const char* err) {
    std::cerr << RED << "error " << yylineno << ":" << column << ": " << err << RESET << std::endl;

    if (yylineno > 0 && yylineno <= static_cast<int>(lines.size())) {
        std::string linePrefix = std::to_string(yylineno) + " | ";
        
        std::cerr << linePrefix << lines[yylineno - 1] << std::endl;
        
        std::cerr << std::string(linePrefix.length(), ' ') 
                  << std::string(column - 1, ' ') << "^" << std::endl;
    } else {
        std::cerr << "Invalid line number: " << yylineno << std::endl;
    }
}

int
yyreport_syntax_error (const yypcontext_t *ctx)
{
  int res = 0;
  //YYLOCATION_PRINT (stderr, *yypcontext_location (ctx));
  fprintf (stderr, ": syntax error");
  // Report the tokens expected at this point.
  {
    enum { TOKENMAX = 10 };
    yysymbol_kind_t expected[TOKENMAX];
    int n = yypcontext_expected_tokens (ctx, expected, TOKENMAX);
    if (n < 0)
      // Forward errors to yyparse.
      res = n;
    else
      for (int i = 0; i < n; ++i)
        fprintf (stderr, "%s %s",
                 i == 0 ? ": expected" : " or", yysymbol_name (expected[i]));
  }
  // Report the unexpected token.
  {
    yysymbol_kind_t lookahead = yypcontext_token (ctx);
    if (lookahead != YYSYMBOL_YYEMPTY)
      fprintf (stderr, " before %s", yysymbol_name (lookahead));
  }
  fprintf (stderr, "\n");
  return res;
}