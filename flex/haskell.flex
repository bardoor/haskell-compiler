%option noyywrap
%option c++

%{
	#include <string>
	#include <cstring>

	unsigned occurencesCount(std::string str, std::string substr) {
		unsigned occurences = 0;
		int pos = 0;

		while ((pos = str.find(substr, pos)) != std::string::npos) {
			pos += substr.length();
			occurences++;
		}

		return occurences;
	}

%}

ASCSYMBOL	[!#$%&*+.\/<=>?@\\\^|\-~:]
SPECIAL		[|,;\[\]'{}]|["']
SMALL		[a-z]
LARGE		[A-Z]
WORD		[a-zA-Z0-9_]

D8			[0-7]
D10			[0-9]
D16			[0-9a-fA-F]

INT_8		0[oO]{D8}+
INT_10      {D10}+
INT_16      0[xX]{D16}+
      
EXPONENT    [eE][+-]?{D10}+
FLOAT       ({D10}+[\.]{D10}+{EXPONENT}?|{D10}+{EXPONENT})

%x STRING
%x CHAR
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%%
%{
	int var;
	double var_float;
	unsigned lineno = 1;
	unsigned opened_line;
	std::string buffer;
%}

  // Identifiers and reserved words
_         { printf("found lexem: _\n"); }
case      { printf("found lexem: case\n"); }
class     { printf("found lexem: class\n"); }
data      { printf("found lexem: data\n"); }
newtype   { printf("found lexem: newtype\n"); }
type      { printf("found lexem: type\n"); }
of        { printf("found lexem: of\n"); }
then      { printf("found lexem: then\n"); }
default   { printf("found lexem: default\n"); }
deriving  { printf("found lexem: deriving\n"); }
do        { printf("found lexem: do\n"); }
if        { printf("found lexem: if\n"); }
else      { printf("found lexem: else\n"); }
where     { printf("found lexem: where\n"); }
let       { printf("found lexem: let\n"); }
foreign   { printf("found lexem: foreign\n"); }
infix     { printf("found lexem: infix\n"); }
infixl    { printf("found lexem: infixl\n"); }
infixr    { printf("found lexem: infixr\n"); }
instance  { printf("found lexem: instance\n"); }
import    { printf("found lexem: import\n"); }
module    { printf("found lexem: module\n"); }
{SMALL}({WORD}|')*  { printf("found function identifier: %s\n", yytext); }
{LARGE}({WORD}|')*  { printf("found constructor identifier: %s\n", yytext); }

\(      { printf("found opening parenthesis"); }
\)      { printf("found closing parenthesis"); }
\{      { printf("found opening curly brace"); }
\}      { printf("found closing curly brace"); }
\[      { printf("found opening square bracket"); }
\]      { printf("found closing square bracket"); }
	
\+      { printf("found operator: +\n"); }
\-      { printf("found operator: -\n"); }
\*      { printf("found operator: *\n"); }
\/      { printf("found operator: /\n"); }
div     { printf("found operation: div\n"); }
mod     { printf("found operation: mod\n"); }
negate  { printf("found operation: negate\n"); }
not     { printf("found operation: not\n"); }
xor     { printf("found operation: xor\n"); }
==      { printf("found operator: ==\n"); }
\/=     { printf("found operator: /=\n"); }
<		{ printf("found operator: <\n"); }
>		{ printf("found operator: >\n");}
<=		{ printf("found operator: <=\n"); }
>=		{ printf("found operator: >=\n"); }
&&		{ printf("found operator: &&\n"); }
\|\|    { printf("found operator: ||\n"); }
=		{ printf("found operator: = (assignment or pattern matching)\n"); }
:		{ printf("found operator: : (cons)\n"); }
\+\+    { printf("found operator: ++ (list concatenation)\n"); }
\.      { printf("found operator: . (function composition)\n"); }
->		{ printf("found operator: -> (function type)\n"); }
<-		{ printf("found operator: <- (monad binding)\n"); }
\|      { printf("found operator: | (guards)\n"); }
!!		{ printf("found operator: !! (list indexing)\n"); }
\\      { printf("found operator: \\ (lambda)\n"); }
%		{ printf("found operator: % (modulus)\n"); }
\^      { printf("found operator: ^ (exponentiation)\n"); }
\$      { printf("found operator: $ (function application)\n"); }
\.\.    { printf("found operator: range (..)\n"); }
::		{ printf("found operator: type annotation (::)\n"); }
@       { printf("found operator: as-pattern (@)\n"); }
~       { printf("found operator: lazy pattern matching (~)\n"); }
=>      { printf("found operator: type constraint (=>)\n"); }
	
{INT_8}  { var = strtol(yytext, NULL, 0); printf("found octal integer literal: %ld\n", var); }
{INT_10} { var = strtol(yytext, NULL, 0); printf("found decimal integer literal: %ld\n", var); }
{INT_16} { var = strtol(yytext, NULL, 0); printf("found hexadecimal integer literal: %ld\n", var); }
{FLOAT}  { var_float = strtod(yytext, NULL); printf("found float literal: %f\n", var_float); }


"--"						{ BEGIN(SINGLE_LINE_COMMENT); }
<SINGLE_LINE_COMMENT>[^\n]			
<SINGLE_LINE_COMMENT>\n		{ printf("found a single line comment\n"); BEGIN(INITIAL); }


"{-"                        { BEGIN(MULTI_LINE_COMMENT); opened_line = yylineno; }
<MULTI_LINE_COMMENT>[^-]+   
<MULTI_LINE_COMMENT>"-"[^}]  
<MULTI_LINE_COMMENT>"-}"    { BEGIN(INITIAL); printf("found a multi line comment\n"); }
<MULTI_LINE_COMMENT><<EOF>> { printf("ERROR: end of file before end of comment opened in %d line", opened_line); return -1; }


\'					{ BEGIN(CHAR); buffer = ""; opened_line = yylineno; }
<STRING,CHAR>\\a	{ buffer += "\a"; }
<STRING,CHAR>\\b	{ buffer += "\b"; }
<STRING,CHAR>\\f	{ buffer += "\f"; }
<STRING,CHAR>\\n	{ buffer += "\n"; }
<STRING,CHAR>\\r	{ buffer +=	"\r"; }
<STRING,CHAR>\\v	{ buffer += "\v"; }
<STRING,CHAR>\\t	{ buffer += "\t"; }
<STRING,CHAR>\\		{ buffer += "\\"; }
<CHAR>[^\'\\]		{ buffer += yytext; }
<CHAR>\' { 
	BEGIN(INITIAL);
	if (buffer.size() > 1) {
		printf("ERROR: char literal opened in %d line can't be longer than 1 symbol!\n", opened_line);
	}
	else {
		printf("found char: %s\n", buffer.c_str()); 
	}
}
<CHAR><<EOF>>			{ printf("ERROR: end of file in char literal opened in %d line\n", opened_line); return -1; }


\"						{ BEGIN(STRING); buffer = ""; opened_line = yylineno; }
<STRING>\\[ \n\t]*\\	{ yylineno += occurencesCount(yytext, "\n"); /* Multiline string separator */ }
<STRING>[^\"\\]			{ buffer += yytext; }
<STRING>\"				{ BEGIN(INITIAL); printf("found string: %s\n", buffer.c_str()); }
<STRING><<EOF>>			{ printf("ERROR: end of file in string literal opened in %d line\n", opened_line); return -1; }


\n { yylineno++; }
