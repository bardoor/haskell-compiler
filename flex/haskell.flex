%option noyywrap
%option c++

%x CHAR
%x STRING

%%
%{
	string str;
	string ch;
%}

/* Ключевые слова и идентификаторы */
_        { printf("found lexem: _\n"); }
case     { printf("found lexem: case\n"); }
class    { printf("found lexem: class\n"); }
data     { printf("found lexem: data\n"); }
newtype  { printf("found lexem: newtype\n"); }
type     { printf("found lexem: type\n"); }
of       { printf("found lexem: of\n"); }
then     { printf("found lexem: then\n"); }
default  { printf("found lexem: default\n"); }
deriving { printf("found lexem: deriving\n"); }
do       { printf("found lexem: do\n"); }
if       { printf("found lexem: if\n"); }
else     { printf("found lexem: else\n"); }
where    { printf("found lexem: where\n"); }
let      { printf("found lexem: let\n"); }
foreign  { printf("found lexem: foreign\n"); }
infix    { printf("found lexem: infix\n"); }
infixl   { printf("found lexem: infixl\n"); }
infixr   { printf("found lexem: infixr\n"); }
instance { printf("found lexem: instance\n"); }
import   { printf("found lexem: import\n"); }
module   { printf("found lexem: module\n"); }
[a-z][\w']*  { printf("found function identifier: %s\n", yytext); }
[a-z][\w']*  { printf("found constructor identifier: %s\n", yytext); }
. { printf(""); }

/* Операции */


/* Строковые и символьные литералы */
\'             { BEGIN(CHAR); }
<CHAR> \\a	   { ch += "\a"; }
<CHAR> \\b	   { ch += "\b"; }
<CHAR> \\f	   { ch += "\f"; }
<CHAR> \\n	   { ch += "\n"; }
<CHAR> \\r	   { ch += "\r"; }
<CHAR> \\t	   { ch += "\t"; }
<CHAR> \\v	   { ch += "\v"; }
<CHAR> \\"	   { ch += "\""; }
<CHAR> \\'	   { ch += "\'"; }
<CHAR> .	   { ch += yytext; }
<CHAR> \'	   { 
	BEGIN(INITIAL);
	if (string.size() > 1) {
		printf("Too long char!")
	}
	printf("found char: %s", ch); 
}
<CHAR> <<EOF>> { printf("Error! \' was not closed!"); }


/* Комментарии */


