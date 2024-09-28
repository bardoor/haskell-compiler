%option noyywrap
%option c++

%{
	#include <string>
	#include <cstring>
%}

ASCSYMBOL	[!#$%&*+.\/<=>?@\\\^|\-~:]
SPECIAL		[|,;\[\]'{}]|["']
SMALL		[a-z]
LARGE		[A-Z]
WORD		[a-zA-Z0-9_]

%x STRING
%x CHAR

%%
%{
	std::string str;
	std::string ch;
	unsigned lineno = 1;
	unsigned opening_quote_line;
%}
	// Identifiers and reserved words
_			{ printf("found lexem: _\n"); }
case		{ printf("found lexem: case\n"); }
class		{ printf("found lexem: class\n"); }
data		{ printf("found lexem: data\n"); }
newtype		{ printf("found lexem: newtype\n"); }
type		{ printf("found lexem: type\n"); }
of			{ printf("found lexem: of\n"); }
then		{ printf("found lexem: then\n"); }
default		{ printf("found lexem: default\n"); }
deriving	{ printf("found lexem: deriving\n"); }
do			{ printf("found lexem: do\n"); }
if			{ printf("found lexem: if\n"); }
else		{ printf("found lexem: else\n"); }
where		{ printf("found lexem: where\n"); }
let			{ printf("found lexem: let\n"); }
foreign		{ printf("found lexem: foreign\n"); }
infix		{ printf("found lexem: infix\n"); }
infixl		{ printf("found lexem: infixl\n"); }
infixr		{ printf("found lexem: infixr\n"); }
instance	{ printf("found lexem: instance\n"); }
import		{ printf("found lexem: import\n"); }
module		{ printf("found lexem: module\n"); }
{SMALL}({WORD}|')*  { printf("found function identifier: %s\n", yytext); }
{LARGE}({WORD}|')*  { printf("found constructor identifier: %s\n", yytext); }

\(			{ printf("found opening parenthesis"); }
\)			{ printf("found closing parenthesis"); }
\{			{ printf("found opening curly brace"); }
\}			{ printf("found closing curly brace"); }
\[			{ printf("found opening square bracket"); }
\]			{ printf("found closing square bracket"); }

\'				{ BEGIN(CHAR); ch = ""; opening_quote_line = yylineno; }
<CHAR>\\a		{ ch += "\a"; }
<CHAR>\\b		{ ch += "\b"; }
<CHAR>\\f		{ ch += "\f"; }
<CHAR>\\n		{ ch += "\n"; }
<CHAR>\\r		{ ch += "\r"; }
<CHAR>\\t		{ ch += "\t"; }
<CHAR>\\v		{ ch += "\v"; }
<CHAR>\\		{ ch += "\\"; }
<CHAR>[^\'\\]	{ ch += yytext; }
<CHAR>\'		{ 
	BEGIN(INITIAL);
	if (ch.size() > 1) {
		printf("ERROR: char literal opened in %d line can't be longer than 1 symbol!\n", opening_quote_line);
	}
	else {
		printf("found char: %s\n", ch.c_str()); 
	}
}
<CHAR><<EOF>>	{ printf("ERROR: end of file in char literal\n"); }
	
\"						{ BEGIN(STRING); str = ""; opening_quote_line = yylineno; }
<STRING>\\a				{ str += "\a"; }
<STRING>\\b				{ str += "\b"; }
<STRING>\\f				{ str += "\f"; }
<STRING>\\n				{ str += "\n"; }
<STRING>\\r				{ str += "\r"; }
<STRING>\\f				{ str += "\f"; }
<STRING>\\v				{ str += "\v"; }
<STRING>\\t				{ str += "\t"; }
<STRING>\\				{ str += "\\"; }
<STRING>\\[ \n\t]*\\	{ yylineno += occurencesCount(yytext, "\n"); /* Multiline string separator */ }
<STRING>[^\"\\]			{ str += yytext; }
<STRING>\"				{ BEGIN(INITIAL); printf("found string: %s\n", str.c_str()); }
<STRING><<EOF>>			{ printf("ERROR: end of file in string literal!"); }

\n { yylineno++; }
