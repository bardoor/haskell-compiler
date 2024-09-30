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

%x STRING
%x CHAR

%%
%{
	std::string buffer;
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

\'					{ BEGIN(CHAR); buffer = ""; opening_quote_line = yylineno; }
<STRING,CHAR>\\a	{ buffer += "\a"; }
<STRING,CHAR>\\b	{ buffer += "\b"; }
<STRING,CHAR>\\f	{ buffer += "\f"; }
<STRING,CHAR>\\n	{ buffer += "\n"; }
<STRING,CHAR>\\r	{ buffer += "\r"; }
<STRING,CHAR>\\v	{ buffer += "\v"; }
<STRING,CHAR>\\t	{ buffer += "\t"; }
<STRING,CHAR>\\		{ buffer += "\\"; }
<CHAR>[^\'\\]		{ buffer += yytext; }
<CHAR>\'		{ 
	BEGIN(INITIAL);
	if (buffer.size() > 1) {
		printf("ERROR: char literal opened in %d line can't be longer than 1 symbol!\n", opening_quote_line);
	}
	else {
		printf("found char: %s\n", buffer.c_str()); 
	}
}
<CHAR><<EOF>>	{ printf("ERROR: end of file in char literal opened in %d line\n", opening_quote_line); }
	
\"						{ BEGIN(STRING); buffer = ""; opening_quote_line = yylineno; }
<STRING>\\[ \n\t]*\\	{ yylineno += occurencesCount(yytext, "\n"); /* Multiline string separator */ }
<STRING>[^\"\\]			{ buffer += yytext; }
<STRING>\"				{ BEGIN(INITIAL); printf("found string: %s\n", buffer.c_str()); }
<STRING><<EOF>>			{ printf("ERROR: end of file in string literal opened in %d line\n", opening_quote_line); }

\n { yylineno++; }
