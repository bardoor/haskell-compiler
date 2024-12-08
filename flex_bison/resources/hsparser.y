%require "3.2"
%locations

%{

#include <JsonBuild.hpp>
#include <Token.hpp>

// extern std::vector<Token>::iterator tokensIter;
extern int original_yylex();
extern int yylineno;

void yyerror(const char* s);

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

%left	CASE		LET	IN		LAMBDA
  	IF		ELSE

%left SYMS PLUS MINUS BQUOTE

%left DCOLON

%left SEMICOL COMMA

%left OPAREN OBRACKET OCURLY

%left EQ

%right DARROW
%right RARROW


%type <node> literal expr oexpr dexpr kexpr fapply aexpr module body funlhs topDeclList topDecl declE var apatList commaSepExprs
             tuple list op comprehension altList declList range lampats apat opat pats fpat dpat
             classDecl classBody context class instDecl restrictInst rinstOpt generalInst valDefList valDef con conList varList
             valrhs valrhs1 whereOpt guardrhs guard tyvar tyvarList tyvarListComma type atype btype ttype ntatype typeListComma atypeList contextList
             dataDecl simpleType constrList tyClassList conop tyClassListComma tyClass typeDecl defaultDecl defaultTypes stmt stmts

%type <str> funid symbols tycon

/* ------------------------------- *
 *      Терминальные символы       *
 * ------------------------------- */
%token <str> STRINGC SYMS CHARC INTC FLOATC FUNC_ID CONSTRUCTOR_ID
%token DARROW DOTDOT RARROW LARROW DCOLON VBAR AS BQUOTE PLUS MINUS COMMA EQ
%token WILDCARD CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW 
%token LETKW INKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW VARKW VOCURLY VCCURLY OPAREN CPAREN OBRACKET CBRACKET OCURLY CCURLY LAZY BACKSLASH COLON

%start module

%%


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
oexpr : oexpr op oexpr %prec PLUS   { $$ = mk_bin_expr($1, $2, $3); }
      | dexpr                      { $$ = $1; }
      ;

/*
      Унарный минус (других унарных выражений просто нет... (да, даже унарного плюса))
*/
dexpr : MINUS kexpr        { $$ = mk_negate_expr($2); }
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
kexpr : BACKSLASH lampats RARROW expr            { $$ = mk_lambda($2, $4); }
      | LETKW OCURLY declList CCURLY INKW expr    { $$ = mk_let_in($3, $6); }
      | IFKW expr THENKW expr ELSEKW expr   { $$ = mk_if_else($2, $4, $6); }
      | DOKW OCURLY stmts CCURLY                  { $$ = mk_do($3); }
      | CASEKW expr OFKW OCURLY altList CCURLY    { $$ = mk_case($2, $5); }
      | fapply                              { $$ = $1; }
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
aexpr : literal         { $$ = mk_expr($1); }
      | funid           { $$ = mk_expr($1->substr()); }
      | OPAREN expr CPAREN    { $$ = $2; }
      | tuple           { $$ = mk_expr($1); }
      | list            { $$ = mk_expr($1); }
      | range           { $$ = mk_expr($1); }
      | comprehension   { $$ = mk_expr($1); }
      | WILDCARD        { $$ = mk_simple_pat("wildcard"); }
      ;

/* 
      Оператор
      1. Последовательность символов
      2. - ква-ква оператор, иначе говоря идентификатор функции в обратных кавычках: `fun`
      3. Плюс или минус
*/
op : symbols                { $$ = mk_operator("symbols", $1->substr()); }
   | BQUOTE funid BQUOTE    { $$ = mk_operator("quoted", $2->substr()); }
   | PLUS                    { $$ = mk_operator("symbols", "+"); }
   | MINUS                    { $$ = mk_operator("symbols", "-"); }
   ;

symbols : SYMS    { $$ = $1; }
        ;

funid : FUNC_ID   { $$ = $1; }
      ;

stmts : stmt        { $$ = mk_stmts($1, NULL); }
      | stmts stmt  { $$ = mk_stmts($2, $1); }
      ;

/*
      Стейтменты в do выражении
      1. Биндинг: (a,b,c) <- (1,2,3)
            Примечание: По левую сторону на этапе парсинга невозможно понять - выражение это или паттерн
      2. Любое выражение
*/
stmt : expr LARROW expr SEMICOL   { $$ = mk_binding_stmt($1, $3); }
     | expr SEMICOL               { $$ = $1; }
     | SEMICOL                    { $$ = new Node(); }
     ;

/* ------------------------------- *
 *         Кортежи, списки         *
 * ------------------------------- */

/*
      Кортеж
      Либо пуст, либо 2 и более элементов
*/
tuple : OPAREN expr COMMA commaSepExprs CPAREN  { $$ = mk_tuple($2, $4); }
      | OPAREN CPAREN                         { $$ = mk_tuple(NULL, NULL); }
      ;

/*
      Списковое включение
      [x * x | x <- [1..10], even x]
*/
comprehension : OBRACKET expr VBAR commaSepExprs CBRACKET
              ;

list : OBRACKET CBRACKET                          { $$ = mk_list(NULL); }
     | OBRACKET commaSepExprs CBRACKET            { $$ = mk_list($2); }
     ;

commaSepExprs : expr                    { $$ = mk_comma_sep_exprs($1, NULL); }
              | expr COMMA commaSepExprs  { $$ = mk_comma_sep_exprs($1, $3); }
              /*
                    Правая рекурсия используется чтоб избежать конфликта:
                    [1, 3 ..]  - range типа 1, 3, 6, 9 ... и до бесконечности
                    [1, 2, 3]  - конструктор списка
              */  
              ;

/*
      Диапазон
      [1..]       - от 1 до бесконечности
      [1..10]     - от 1 до 10
      [1,3..10]   - от 1 до 10 с шагом 2 
      [1,3..]     - от 1 до бесконечности с шагом 2
*/
range : OBRACKET expr DOTDOT CBRACKET               { $$ = mk_range($2, NULL, NULL); }
      | OBRACKET expr DOTDOT expr CBRACKET          { $$ = mk_range($2, NULL, $4); }
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
pats : pats COMMA opat      { $$ = mk_pats($3, $1); }
     | opat               { $$ = $1; }
     ;

/*
      Паттерн с оператором
      x:xs = lst
*/
opat : dpat                   { $$ = $1; }
     | opat op opat %prec PLUS { $$ = mk_bin_pat($1, $2, $3); }
     ;

/*
      Специально для мистера унарного минуса
*/
dpat : MINUS fpat           { $$ = mk_negate($2); }
     | fpat               { $$ = $1; }
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
apat : funid                  { $$ = mk_simple_pat($1->substr()); }
     | tycon                  { $$ = mk_simple_pat($1->substr()); }
     | literal                { $$ = mk_simple_pat($1); }
     | WILDCARD               { $$ = mk_simple_pat("wildcard"); }
     | OPAREN CPAREN                { $$ = mk_tuple_pat(NULL, NULL); }
     | OPAREN opat COMMA pats CPAREN  { $$ = mk_tuple_pat($2, $4); }
     ;

apatList : apat               { $$ = mk_pat_list(NULL, $1); }
         | apatList apat      { $$ = mk_pat_list($1, $2); }
         ;
/* 
      Альтернативы для case 
*/
altList : altList SEMICOL altE  { LOG_PARSER("## PARSER ## make alternative list - altList ; altE\n"); }
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

declList : declE              { $$ = $1; }
         | declList SEMICOL declE { $$ = mk_decl_list($1, $3); }
         ;

con : tycon                  { $$ = mk_con($1->substr()); }
    | OPAREN symbols CPAREN        { $$ = mk_con($2); }
    ;

conList : con                { $$ = $1; }
        | conList COMMA con    { $$ = mk_con_list($1, $3); }
        ;

varList : varList COMMA var    { $$ = mk_var_list($1, $3); }
        | var                { $$ = $1; }
        ;

/* 
      Оператор в префиксной форме или идентификатор функции 
*/
var : funid                  { std::cout << $1 << std::endl; std::cout << $1->substr() << std::endl; $$ = mk_var("funid", $1->substr()); }
    | OPAREN symbols CPAREN        { $$ = mk_var("symbols", *$2); }
    ;

/* 
      Объявление
      1. Биндинг функции
      2. Список функций с типом
*/
declE : var MINUS expr                    { $$ = mk_fun_decl($1, $3); }
      | funlhs MINUS expr                 { $$ = mk_fun_decl($1, $3); }
      | varList DCOLON type DARROW type { $$ = mk_typed_var_list($1, $3, $5); }
      | varList DCOLON type             { $$ = mk_typed_var_list($1, $3); }
      | %empty                          { $$ = mk_empty_decl(); }
      ;

whereOpt : WHEREKW OCURLY declList CCURLY { $$ = mk_where($3); }
         | %empty                   { $$ = mk_where(NULL); }
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
     ;

topDeclList : topDecl
            { $$ = $1; }
            | topDeclList SEMICOL topDecl
            { $$ = mk_top_decl_list($1, $3); }
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
        { $$ = $1; }
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
          | WHEREKW OCURLY declList CCURLY
          { LOG_PARSER("## PARSER ## make classBody - WHERE { declList }\n"); $$ = new Node(); $$->val =  $3->val; }
          ;

instDecl : INSTANCEKW context DARROW tycon restrictInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE context => tycon restrictInst rinstOpt\n"); $$ = new Node(); $$->val = {{"inst_decl", {{"context", $2->val}, {"tycon", $4->substr()}, {"restrictInst", $5->val}, {"rinstOpt", $6->val}}}}; }
         | INSTANCEKW tycon generalInst rinstOpt
         { LOG_PARSER("## PARSER ## make instDecl - INSTANCE tycon generalInst rinstOpt\n"); $$ = new Node(); $$->val = {{"inst_decl", {{"tycon", $2->substr()}, {"generalInst", $3->val}, {"rinstOpt", $4->val}}}}; }
         ;

rinstOpt : %empty
         { LOG_PARSER("## PARSER ## make rinstOpt - nothing\n"); $$ = new Node(); $$->val = {{"rinstOpt", nullptr}}; }
         | WHEREKW OCURLY valDefList CCURLY
         { LOG_PARSER("## PARSER ## make rinstOpt - WHERE { valDefList }\n"); $$ = new Node(); $$->val = {{"rinstOpt", $3->val}}; }
         ;

valDefList : %empty
            { LOG_PARSER("## PARSER ## make valDefList - nothing\n"); $$ = new Node(); $$->val = {{"valDefList", json::array()}}; }
            | valDef
            { LOG_PARSER("## PARSER ## make valDefList - valDef\n"); $$ = new Node(); $$->val = {{"valDefList", json::array({$1->val})}}; }
            | valDef SEMICOL valDef
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
        | MINUS expr
        { LOG_PARSER("## PARSER ## make valrhs1 - = expr\n"); $$ = new Node(); $$->val = {{"valrhs1", {{"expr", $2->val}}}}; }
        ;

guardrhs : guard MINUS expr
         { LOG_PARSER("## PARSER ## make guardrhs - guard = expr\n"); $$ = new Node(); $$->val = {{"guardrhs", {{"guard", $1->val}, {"expr", $3->val}}}}; }
         | guard MINUS expr guardrhs
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
        { LOG_PARSER("## PARSER ## make context - (contextList)\n"); $$ = new Node(); $$->val = $2->val; }
        | class
        { LOG_PARSER("## PARSER ## make context - class\n"); $$ = new Node(); $$->val = $1->val; }
        ;

contextList : class
            { LOG_PARSER("## PARSER ## make contextList - class\n"); $$ = new Node(); $$->val = {{"contextList", { $1->val }}}; }
            | contextList COMMA class
            { LOG_PARSER("## PARSER ## make contextList - contextList, class\n"); $$ = new Node(); $$->val = $1->val; $$->val["contextList"].push_back($3->val); }
            ;

class : tycon tyvar
      { LOG_PARSER("## PARSER ## make class - tycon tyvar\n"); $$ = new Node(); $$->val = {{"tycon", $1->substr()},{"tyvar", $2->val}}; }
      ;

/* ------------------------------- *
 *              data               *
 * ------------------------------- */

dataDecl : DATAKW context DARROW simpleType MINUS constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}}}}; }
         | DATAKW simpleType MINUS constrList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}}}}; }
         | DATAKW context DARROW simpleType MINUS constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA context => simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"context", $2->val}, {"simpleType", $4->val}, {"constrList", $6->val}, {"deriving", $8->val}}}}; }
         | DATAKW simpleType MINUS constrList DERIVINGKW tyClassList
         { LOG_PARSER("## PARSER ## make dataDecl - DATA simpleType = constrList DERIVING tyClassList\n"); $$ = new Node(); $$->val = {{"dataDecl", {{"simpleType", $2->val}, {"constrList", $4->val}, {"deriving", $6->val}}}}; }
         ;

constrList : tycon atypeList
           { LOG_PARSER("## PARSER ## make constrList - tycon atypeList\n"); $$ = new Node(); $$->val = {{"constrList", {{"tycon", $1->substr()}, {"atypeList", $2->val}}}}; }
           | OPAREN SYMS CPAREN atypeList
           { LOG_PARSER("## PARSER ## make constrList - (SYMS) atypeList\n"); $$ = new Node(); $$->val = {{"constrList", {{"syms", $2->substr()}, {"atypeList", $4->val}}}}; }
           | OPAREN SYMS CPAREN
           { LOG_PARSER("## PARSER ## make constrList - (SYMS)\n"); $$ = new Node(); $$->val = {{"constrList", {{"syms", $2->substr()}}}}; }
           | tycon
           { LOG_PARSER("## PARSER ## make constrList - tycon\n"); $$ = new Node(); $$->val = {{"constrList", {{"tycon", $1->substr()}}}}; }
           | btype conop btype
           { LOG_PARSER("## PARSER ## make constrList - btype conop btype\n"); $$ = new Node(); $$->val = {{"constrList", {{"btype1", $1->val}, {"conop", $2->val}, {"btype2", $3->val}}}}; }
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

typeDecl : TYPEKW simpleType MINUS type
         { LOG_PARSER("## PARSER ## make typeDecl - TYPE simpleType = type\n"); $$ = new Node(); $$->val = {{"typeDecl", {{"simpleType", $2->val}, {"type", $4->val}}}}; }
         ;

simpleType : tycon
           { LOG_PARSER("## PARSER ## make simpleType - tycon\n"); $$ = new Node(); $$->val = {{"simpleType", {{"tycon", $1->substr()}}}}; }
           | tycon tyvarList
           { LOG_PARSER("## PARSER ## make simpleType - tycon tyvarList\n"); $$ = new Node(); $$->val = {{"simpleType", {{"tycon", $1->substr()}, {"tyvarList", $2->val}}}}; }
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
      { LOG_PARSER("## PARSER ## make tyvar - funid\n"); $$ = new Node();  $$->val = {{"funid", $1->substr()}}; }
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
     { LOG_PARSER("## PARSER ## make type - btype -> type\n"); $$ = $3; $$->val.push_back($1->val); }
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
    // Token next = *tokensIter;
    // 
    // yylval.str = new std::string(next.value);
    //   
    // tokensIter++;
    return 1;
}

void yyerror(const char* s) {
    std::cerr << "Error: " << s << " on line " << yylineno << std::endl;
}
