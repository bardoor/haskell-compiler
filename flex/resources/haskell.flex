%option noyywrap
%option c++

%{
	#include <string>
	#include <cstring>
	#include <memory>
	#include <algorithm>
	#include "FlexUtils.h"

	static bool check_prefix(const std::string& input_string, int base) {
        int len = input_string.length();
        if (base == 8) {
            if (len < 3 || !(input_string[0] == '0' && (input_string[1] == 'o' || input_string[1] == 'O'))) {
                std::cerr << "Error: invalid prefix for octal number\n";
                return false;
            }
        } else if (base == 16) {
            if (len < 3 || !(input_string[0] == '0' && (input_string[1] == 'x' || input_string[1] == 'X'))) {
                std::cerr << "Error: invalid prefix for hexadecimal number\n";
                return false;
            }
        }
        return true; // Префикс корректен
    }

	static int clean_integer(const std::string& input_string, std::string& cleaned, int base) {
		int len = input_string.length();
        bool has_valid_digits = false;

		// Проверка на подчеркивания в начале и конце
	 	if (input_string.front() == '_' || input_string.back() == '_') {
            std::cerr << "Error: underscores cannot be at the beginning or end of the number\n";
            return 0;
        }

		// Проверка на префиксы для восьмеричных и шестнадцатеричных чисел
		if (!check_prefix(input_string, base)) {
            return 0;
        }

		// Пропускаем префикс для восьмеричных и шестнадцатеричных чисел
		int start_idx = (base == 10) ? 0 : 2;

		// Обрабатываем символы числа после префикса
		for (int i = start_idx; i < len; i++) {
			if (input_string[i] == '_') {
				// Пропускаем подчеркивания
				continue;
			}

			// Добавляем валидный символ в cleaned
			cleaned += input_string[i];
			has_valid_digits = true;
		}

		// Проверка, остались ли валидные цифры после удаления подчеркиваний
		if (!has_valid_digits) {
			std::cerr << "Error: no valid digits left after removing underscores\n";
			return 0;
		}

		return 1; 
	}

	std::string replaceComma(const std::string& str) {
		std::string result = str;
		size_t start_pos = 0;

		while ((start_pos = result.find('.', start_pos)) != std::string::npos) {
			result.replace(start_pos, 1, ","); 
			start_pos++;  
		}

		return result; 
	}

	unsigned occurencesCount(std::string str, std::string substr) {
		unsigned occurences = 0;
		size_t pos = 0;

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

UNDERSCORE  (_+)

INT_8    	{UNDERSCORE}?0{UNDERSCORE}?[oO]({UNDERSCORE}?{D8})+{UNDERSCORE}?
INT_10      {UNDERSCORE}?({D10}+{UNDERSCORE}?)+{UNDERSCORE}?
INT_16      {UNDERSCORE}?0{UNDERSCORE}?[xX]({UNDERSCORE}?{D16})+{UNDERSCORE}?
      
EXPONENT    [eE][+-]?{D10}+
FLOAT       ({D10}+[\.]{D10}+{EXPONENT}?|{D10}+{EXPONENT})

%x STRING
%x CHAR
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%%
%{
	int var;
	long double var_float;
	unsigned lineno = 1;
	unsigned opened_line;
	std::string buffer;

	std::unique_ptr<LayoutBuilder> layoutBuilder = std::make_unique<LayoutBuilder>();

	#define LOOKAHEAD(res) \
		res = ""; \
		char next_char; \
		do { \
			next_char = yyinput(); \
			if (std::isspace(next_char)) { \
				unput(next_char); \
			} else { \
				res += next_char; \
			} \
		} while (!std::isspace(next_char));

	#define EMIT_LEXEM \
	{ \
		switch(layoutBuilder->emitLexem()) { \
			case Lexem::OPEN_BRACE: \
            	unput('{'); \
				break; \
			case Lexem::CLOSING_BRACE: \
				unput('}'); \
				break; \
			case Lexem::SEMICOLON: \
				unput(';'); \
				break; \
			case Lexem::NONE: \
				break; \
		} \
    }

	#define YY_USER_ACTION EMIT_LEXEM
    
%}

_         { printf("found lexem: _\n"); layoutBuilder->addLexem(std::string(yytext));}
case      { printf("found lexem: case\n"); layoutBuilder->addLexem(std::string(yytext));}
class     { printf("found lexem: class\n"); layoutBuilder->addLexem(std::string(yytext));}
data      { printf("found lexem: data\n"); layoutBuilder->addLexem(std::string(yytext));}
newtype   { printf("found lexem: newtype\n"); layoutBuilder->addLexem(std::string(yytext));}
type      { printf("found lexem: type\n"); layoutBuilder->addLexem(std::string(yytext));}
of        { printf("found lexem: of\n"); layoutBuilder->addLexem(std::string(yytext));}
then      { printf("found lexem: then\n"); layoutBuilder->addLexem(std::string(yytext));}
default   { printf("found lexem: default\n"); layoutBuilder->addLexem(std::string(yytext));}
deriving  { printf("found lexem: deriving\n"); layoutBuilder->addLexem(std::string(yytext));}
do        { printf("found lexem: do\n"); layoutBuilder->addLexem(std::string(yytext));}
if        { printf("found lexem: if\n"); layoutBuilder->addLexem(std::string(yytext));}
else      { printf("found lexem: else\n"); layoutBuilder->addLexem(std::string(yytext));}
where     { printf("found lexem: where\n"); layoutBuilder->addLexem(std::string(yytext));}
where\n     { printf("found lexem: where\n"); layoutBuilder->addLexem(std::string(yytext));}
let       { printf("found lexem: let\n"); layoutBuilder->addLexem(std::string(yytext));}
foreign   { printf("found lexem: foreign\n"); layoutBuilder->addLexem(std::string(yytext));}
infix     { printf("found lexem: infix\n"); layoutBuilder->addLexem(std::string(yytext));}
infixl    { printf("found lexem: infixl\n"); layoutBuilder->addLexem(std::string(yytext));}
infixr    { printf("found lexem: infixr\n"); layoutBuilder->addLexem(std::string(yytext));}
instance  { printf("found lexem: instance\n"); layoutBuilder->addLexem(std::string(yytext));}
import    { printf("found lexem: import\n"); layoutBuilder->addLexem(std::string(yytext));}
module    { printf("found lexem: module\n"); layoutBuilder->addLexem(std::string(yytext));}
	
\(      { printf("found opening parenthesis\n"); layoutBuilder->addLexem(std::string(yytext));}
\)      { printf("found closing parenthesis\n"); layoutBuilder->addLexem(std::string(yytext));}
\{      { printf("found opening curly brace\n"); layoutBuilder->addLexem(std::string(yytext));}
\}      { printf("found closing curly brace\n"); layoutBuilder->addLexem(std::string(yytext));}
\[      { printf("found opening square bracket\n"); layoutBuilder->addLexem(std::string(yytext));}
\]      { printf("found closing square bracket\n"); layoutBuilder->addLexem(std::string(yytext));}
\;		{ printf("found semicolon\n"); layoutBuilder->addLexem(std::string(yytext));}

\+      { printf("found operator: +\n"); layoutBuilder->addLexem(std::string(yytext));}
\-      { printf("found operator: -\n"); layoutBuilder->addLexem(std::string(yytext));}
\*      { printf("found operator: *\n"); layoutBuilder->addLexem(std::string(yytext));}
\/      { printf("found operator: /\n"); layoutBuilder->addLexem(std::string(yytext));}
div     { printf("found operation: div\n"); layoutBuilder->addLexem(std::string(yytext));}
mod     { printf("found operation: mod\n"); layoutBuilder->addLexem(std::string(yytext));}
negate  { printf("found operation: negate\n"); layoutBuilder->addLexem(std::string(yytext));}
not     { printf("found operation: not\n"); layoutBuilder->addLexem(std::string(yytext));}
xor     { printf("found operation: xor\n"); layoutBuilder->addLexem(std::string(yytext));}
==      { printf("found operator: ==\n"); layoutBuilder->addLexem(std::string(yytext));}
"/="    { printf("found operator: /=\n"); layoutBuilder->addLexem(std::string(yytext));}
"<"		{ printf("found operator: <\n"); layoutBuilder->addLexem(std::string(yytext));}
">"		{ printf("found operator: >\n");layoutBuilder->addLexem(std::string(yytext));}
"<="	{ printf("found operator: <=\n"); layoutBuilder->addLexem(std::string(yytext));}
">="	{ printf("found operator: >=\n"); layoutBuilder->addLexem(std::string(yytext));}
&&		{ printf("found operator: &&\n"); layoutBuilder->addLexem(std::string(yytext));}
"||"    { printf("found operator: ||\n"); layoutBuilder->addLexem(std::string(yytext));}
"="		{ printf("found operator: = (assignment or pattern matching)\n"); layoutBuilder->addLexem(std::string(yytext));}
:		{ printf("found operator: : (cons)\n"); layoutBuilder->addLexem(std::string(yytext));}
"++"    { printf("found operator: ++ (list concatenation)\n"); layoutBuilder->addLexem(std::string(yytext));}
"."     { printf("found operator: . (function composition)\n"); layoutBuilder->addLexem(std::string(yytext));}
"->"	{ printf("found operator: -> (function type)\n"); layoutBuilder->addLexem(std::string(yytext));}
"<-"	{ printf("found operator: <- (monad binding)\n"); layoutBuilder->addLexem(std::string(yytext));}
"|"     { printf("found operator: | (guards)\n"); layoutBuilder->addLexem(std::string(yytext));}
!!		{ printf("found operator: !! (list indexing)\n"); layoutBuilder->addLexem(std::string(yytext));}
\\      { printf("found operator: \\ (lambda)\n"); layoutBuilder->addLexem(std::string(yytext));}
%		{ printf("found operator: % (modulus)\n"); layoutBuilder->addLexem(std::string(yytext));}
"^"     { printf("found operator: ^ (exponentiation)\n"); layoutBuilder->addLexem(std::string(yytext));}
"$"     { printf("found operator: $ (function application)\n"); layoutBuilder->addLexem(std::string(yytext));}
".."    { printf("found operator: range (..)\n"); layoutBuilder->addLexem(std::string(yytext));}
::		{ printf("found operator: type annotation (::)\n"); layoutBuilder->addLexem(std::string(yytext));}
@       { printf("found operator: as-pattern (@)\n"); layoutBuilder->addLexem(std::string(yytext));}
~       { printf("found operator: lazy pattern matching (~)\n"); layoutBuilder->addLexem(std::string(yytext));}
=>      { printf("found operator: type constraint (=>)\n"); layoutBuilder->addLexem(std::string(yytext));}
	
{SMALL}({WORD}|')*  { 
	layoutBuilder->addLexem(std::string(yytext)); 
	if (layoutBuilder->canEmit()) {
		yyless(0);
		EMIT_LEXEM
	} 
	else {
		printf("found function identifier: %s\n", yytext); 
	}
}
{LARGE}({WORD}|')*  { printf("found constructor identifier: %s\n", yytext); layoutBuilder->addLexem(std::string(yytext));}

{INT_8}  { 
  	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 8)) {
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0) {
		std::cerr << "Error! Incorrect literal: " << cleaned + after_literal << std::endl;
		return -1;
	} 

	long var = strtol(cleaned.c_str(), NULL, 8);

	printf("found octal integer literal: %ld\n", var);
}

{INT_10} {
	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 10)) {
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0) {
		std::cerr << "Error! Incorrect decimal literal: " << cleaned + after_literal << std::endl;
		return -1;
	} 

	long var = strtol(cleaned.c_str(), NULL, 0); 
	printf("found decimal integer literal: %ld\n", var);
}

{INT_16} { 
	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 16)) {
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0) {
		std::cerr << "Error! Incorrect decimal literal: " << cleaned + after_literal << std::endl;
		return -1;
	} 
	
	long var = strtol(cleaned.c_str(), NULL, 16); 
	printf("found hexadecimal integer literal: %ld\n", var);
}

{FLOAT}  { var_float = std::stold(replaceComma(yytext)); printf("found float literal: %Lf\n", var_float); }

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
<STRING>\\({INT_8}|{INT_10}|{INT_16}) { buffer += (char) strtol(yytext + 1, NULL, 0); }
<STRING,CHAR>\\		{ buffer += "\\"; }
<STRING>\\&			{ }
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
<STRING>[^\"\\] 		{ buffer += yytext; }
<STRING>\"				{ BEGIN(INITIAL); printf("found string: %s\n", buffer.c_str()); }
<STRING><<EOF>>			{ printf("ERROR: end of file in string literal opened in %d line\n", opened_line); return -1; }

\n { yylineno++; layoutBuilder->addLexem(std::string(yytext)); }
[[:space:]] { layoutBuilder->addOffset(std::string(yytext).length()); }

<*><<EOF>> { 
	layoutBuilder->eof();  
	if(!layoutBuilder->canEmit()) {
		return 0;
	}
	else {
		EMIT_LEXEM;
	}
}

%%
