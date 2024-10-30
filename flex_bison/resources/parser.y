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

%start module

%type <expr> expr;
%type <module> module;
%type <param> param;
%type <funcDecl> funcDecl;
%type <paramList> paramList paramListE;

%token <intVal> INTC
%token <floatVal> FLOATC
%token <str> FUNC_ID CONSTRUCTOR_ID
%token DIVOP MODOP QUOTOP NEGATE STRICTAPPLY SEQOP NOT FMAPOP APPLYFUNCTOR REMOP INTPOW FRACPOW XOR EQ NEQ LE GE AND OR CONCAT RANGE FUNCTYPE MONADBINDING GUARDS INDEXING ASPATTERN TYPEANNOTATION TYPECONSTRAINT
%token UNDERSCORE CASEKW CLASSKW DATAKW NEWTYPEKW TYPEKW OFKW THENKW DEFAULTKW DERIVINGKW DOKW IFKW ELSEKW WHEREKW LETKW FOREIGNKW INFIXKW INFIXLKW INFIXRKW INSTANCEKW IMPORTKW MODULEKW

%%
module : funcDecl { $$ = root = new Module($1); LOG_PARSER("## PARSER ## made Module\n"); }
       ;

funcDecl : FUNC_ID paramListE '=' expr { $$ = new FuncDecl($1, $2, $4); LOG_PARSER("## PARSER ## made funcDecl\n"); }
         ;

param : FUNC_ID { $$ = new Param(std::string($1)); LOG_PARSER("## PARSER ## made param\n"); }
      ;

paramList : param            { $$ = new ParamList(); LOG_PARSER("## PARSER ## made paramList\n"); }
          | paramList param  { $1->add($2); $$ = $1; LOG_PARSER("## PARSER ## add to paramList\n"); }
          ;

paramListE : /* nothing */   { $$ = new ParamList(); LOG_PARSER("## PARSER ## made empty paramListE\n"); }
           | paramList       { $$ = $1; LOG_PARSER("## PARSER ## made not empty paramListE\n"); }
           ;

expr : INTC               { $$ = new IntLiteral($1); LOG_PARSER("## PARSER ## made IntLiteral\n"); }
     | FLOATC             { $$ = new FloatLiteral($1); LOG_PARSER("## PARSER ## made FloatLiteral\n"); }
     | FUNC_ID paramListE { $$ = new FuncApply($1, $2); LOG_PARSER("## PARSER ## made FuncCall\n"); }
     | expr '+' expr      { $$ = new AddExpr($1, $3); LOG_PARSER("## PARSER ## made AddExpr\n"); }
     | expr '-' expr      { $$ = new SubExpr($1, $3); LOG_PARSER("## PARSER ## made SubExpr\n"); }
     | expr '*' expr      { $$ = new MulExor($1, $3); LOG_PARSER("## PARSER ## made MulExor\n"); }
     | expr '/' expr      { $$ = new DivExpr($1, $3); LOG_PARSER("## PARSER ## made DivExpr\n"); }
     | '(' expr ')'       { $$ = $2; LOG_PARSER("## PARSER ## made expr in parentheses\n"); }
     | expr AND expr      { $$ = new AndExpr($1, $3); LOG_PARSER("## PARSER ## made &&\n"); }
     | expr OR expr       { $$ = new OrExpr($1, $3); LOG_PARSER("## PARSER ## made ||\n"); }
     | expr EQ expr       { $$ = new EqualExpr($1, $3); LOG_PARSER("## PARSER ## made ==\n"); }
     | expr NEQ expr      { $$ = new NotEqualExpr($1, $3); LOG_PARSER("## PARSER ## made  !=\n"); }
     | expr LE expr       { $$ = new LessThanExpr($1, $3); LOG_PARSER("## PARSER ## made <=\n"); }
     | expr GE expr       { $$ = new GreaterThanExpr($1, $3); LOG_PARSER("## PARSER ## made  >=\n"); }
     | expr '<' expr      { $$ = new LessExpr($1, $3); LOG_PARSER("## PARSER ## made <\n"); }
     | expr '>' expr      { $$ = new GreaterExpr($1, $3); LOG_PARSER("## PARSER ## made >\n"); }
     | NOT expr           { $$ = new NotExpr($2); LOG_PARSER("## PARSER ## made UnaryExpr for not\n"); }
     | NEGATE expr        { $$ = new NegateExpr($2); LOG_PARSER("## PARSER ## made UnaryExpr for negate\n"); }
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
