%option noyywrap

%{
	#include <string>
	#include <cstring>
	#include <memory>
	#include <algorithm>
	#include <charconv>

	#include "FlexUtils.h"
	#include "BisonUtils.h"

	#ifdef DEBUG_LEXEMS
		 #define LOG_LEXEM(msg, ...) printf(msg, ##__VA_ARGS__);
	#else
		#define LOG_LEXEM(msg, ...)
	#endif

	#define UNPUT_STR(str) \
		for (auto it = str.end(); it >= str.begin(); it--) { \
			unput(*it); \
		}

	#define LOOKAHEAD(res) \
		res = ""; \
		char next_char; \
		do { \
			next_char = yyinput(); \
			if (next_char == EOF || next_char == '\0') { \
				unput(next_char); \
			} else { \
				res += next_char; \
			} \
		} while (next_char != EOF && next_char != '\0' || std::isalpha(next_char));

	#define EMIT_LEXEM \
	{ \
		switch(layoutBuilder->emitLexem()) { \
			case Lexem::OPEN_BRACE: \
				layoutBuilder->addLexem("{"); \
				printf("{\n"); \
				break; \
			case Lexem::CLOSING_BRACE: \
				layoutBuilder->addLexem("}"); \
				printf("}\n"); \
				break; \
			case Lexem::SEMICOLON: \
				layoutBuilder->addLexem(";"); \
				printf(";\n"); \
				break; \
			case Lexem::NONE: \
				break; \
		} \
    }

	#define YY_USER_ACTION EMIT_LEXEM

	static bool check_prefix(const std::string& input_string, int base);
	static int clean_integer(const std::string& input_string, std::string& cleaned, int base);
	static int clean_float(const std::string& input_string, std::string& cleaned);
	std::string replaceComma(const std::string& str);
	unsigned occurencesCount(std::string str, std::string substr);

	long long intc;
	long double var_float;
	unsigned lineno = 1;
	unsigned opened_line;
	std::string buffer;

	std::unique_ptr<LayoutBuilder> layoutBuilder = std::make_unique<LayoutBuilder>();
%}

SMALL		[a-z]
LARGE		[A-Z]
WORD		[a-zA-Z0-9_]

D8			[0-7]
D10			[0-9]
D16			[0-9a-fA-F]

INT_8    	(_+)?0(_+)?[oO]((_+)?{D8})+(_+)?
INT_10      (_+)?({D10}+(_+)?)+(_+)?
INT_16      (_+)?0(_+)?[xX]((_+)?{D16})+(_+)?
      
EXPONENT    (_+)?[eE](_+)?[+-]?(_+)?({D10}+(_+)?)+(_+)?
FLOAT       ((_+)?({D10}+(_+)?)+(_+)?[\.](_+)?({D10}+(_+)?)+{EXPONENT}?(_+)?|(_+)?({D10}+(_+)?)+{EXPONENT})

%x STRING
%x CHAR
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%%
%{
	// Если вставить сюда локальные переменные, то они будут пересоздаваться каждый раз при вызове yylex
	// Поэтому вынес отсюда всё что можно во избежание потери значений переменных между вызовами yylex
%}

_         { LOG_LEXEM("found lexem: _\n"); layoutBuilder->addLexem(std::string(yytext)); return UNDERSCORE; }
case      { LOG_LEXEM("found lexem: case\n"); layoutBuilder->addLexem(std::string(yytext)); return CASEKW; }
class     { LOG_LEXEM("found lexem: class\n"); layoutBuilder->addLexem(std::string(yytext)); return CLASSKW; }
data      { LOG_LEXEM("found lexem: data\n"); layoutBuilder->addLexem(std::string(yytext)); return DATAKW; }
newtype   { LOG_LEXEM("found lexem: newtype\n"); layoutBuilder->addLexem(std::string(yytext)); return NEWTYPEKW; }
type      { LOG_LEXEM("found lexem: type\n"); layoutBuilder->addLexem(std::string(yytext)); return TYPEKW; }
of        { LOG_LEXEM("found lexem: of\n"); layoutBuilder->addLexem(std::string(yytext)); return OFKW; }
then      { LOG_LEXEM("found lexem: then\n"); layoutBuilder->addLexem(std::string(yytext)); return THENKW; }
default   { LOG_LEXEM("found lexem: default\n"); layoutBuilder->addLexem(std::string(yytext)); return DEFAULTKW; }
deriving  { LOG_LEXEM("found lexem: deriving\n"); layoutBuilder->addLexem(std::string(yytext)); return DERIVINGKW; }
do        { LOG_LEXEM("found lexem: do\n"); layoutBuilder->addLexem(std::string(yytext)); return DOKW; }
if        { LOG_LEXEM("found lexem: if\n"); layoutBuilder->addLexem(std::string(yytext)); return IFKW; }
else      { LOG_LEXEM("found lexem: else\n"); layoutBuilder->addLexem(std::string(yytext)); return ELSEKW; }
where     { LOG_LEXEM("found lexem: where\n"); layoutBuilder->addLexem(std::string(yytext)); return WHEREKW; }
let       { LOG_LEXEM("found lexem: let\n"); layoutBuilder->addLexem(std::string(yytext)); return LETKW; }
foreign   { LOG_LEXEM("found lexem: foreign\n"); layoutBuilder->addLexem(std::string(yytext)); return FOREIGNKW; }
infix     { LOG_LEXEM("found lexem: infix\n"); layoutBuilder->addLexem(std::string(yytext)); return INFIXKW; }
infixl    { LOG_LEXEM("found lexem: infixl\n"); layoutBuilder->addLexem(std::string(yytext)); return INFIXLKW; }
infixr    { LOG_LEXEM("found lexem: infixr\n"); layoutBuilder->addLexem(std::string(yytext)); return INFIXRKW; }
instance  { LOG_LEXEM("found lexem: instance\n"); layoutBuilder->addLexem(std::string(yytext)); return INSTANCEKW; }
import    { LOG_LEXEM("found lexem: import\n"); layoutBuilder->addLexem(std::string(yytext)); return IMPORTKW; }
module    { LOG_LEXEM("found lexem: module\n"); layoutBuilder->addLexem(std::string(yytext)); return MODULEKW; }

"("     |
")"     |
"{"     |
"}"     |
"["     |
"]"     |
";"		{ LOG_LEXEM("found %s\n", yytext); layoutBuilder->addLexem(std::string(yytext)); return yytext[0]; }

"+"     |
"-"     |
"*"     |
"/"     |
"~"     |
\\      |
"%"		|
"^"     |
"$"     |
"<"		|
">"		|
"="		|
":"		| 
"."     { LOG_LEXEM("found operator: %s\n", yytext); layoutBuilder->addLexem(std::string(yytext)); return yytext[0]; }
","		{ LOG_LEXEM("found tuple values separator: ,\n"); layoutBuilder->addLexem(std::string(yytext)); return yytext[0]; }
`rem`   { LOG_LEXEM("found operation: rem\n"); layoutBuilder->addLexem(std::string(yytext)); return REMOP; }
`div`   { LOG_LEXEM("found operation: div\n"); layoutBuilder->addLexem(std::string(yytext)); return DIVOP; }
`mod`   { LOG_LEXEM("found operation: mod\n"); layoutBuilder->addLexem(std::string(yytext)); return MODOP; }
`quot`  { LOG_LEXEM("found operation: quot\n"); layoutBuilder->addLexem(std::string(yytext)); return QUOTOP; }
`seq`   { LOG_LEXEM("found operation: seq\n"); layoutBuilder->addLexem(std::string(yytext)); return SEQOP; }
negate  { LOG_LEXEM("found operation: negate\n"); layoutBuilder->addLexem(std::string(yytext)); return NEGATE; }
not     { LOG_LEXEM("found operation: not\n"); layoutBuilder->addLexem(std::string(yytext)); return NOT; }
xor     { LOG_LEXEM("found operation: xor\n"); layoutBuilder->addLexem(std::string(yytext)); return XOR; }
"^^"    { LOG_LEXEM("found operator: ^^\n"); layoutBuilder->addLexem(std::string(yytext)); return INTPOW; }
"**"    { LOG_LEXEM("found operator: **\n"); layoutBuilder->addLexem(std::string(yytext)); return FRACPOW; }
"=="    { LOG_LEXEM("found operator: ==\n"); layoutBuilder->addLexem(std::string(yytext)); return EQ; }
"/="    { LOG_LEXEM("found operator: /=\n"); layoutBuilder->addLexem(std::string(yytext)); return NEQ; }
"<="    { LOG_LEXEM("found operator: <=\n"); layoutBuilder->addLexem(std::string(yytext)); return LE; }
">="    { LOG_LEXEM("found operator: >=\n"); layoutBuilder->addLexem(std::string(yytext)); return GE; }
"&&"    { LOG_LEXEM("found operator: &&\n"); layoutBuilder->addLexem(std::string(yytext)); return AND; }
"||"    { LOG_LEXEM("found operator: ||\n"); layoutBuilder->addLexem(std::string(yytext)); return OR; }
"++"    { LOG_LEXEM("found operator: ++ (list concatenation)\n"); layoutBuilder->addLexem(std::string(yytext)); return CONCAT; }
".."    { LOG_LEXEM("found operator: range (..)\n"); layoutBuilder->addLexem(std::string(yytext)); return RANGE; }
"->"    { LOG_LEXEM("found operator: -> (function type)\n"); layoutBuilder->addLexem(std::string(yytext)); return RARROW; }
"<-"    { LOG_LEXEM("found operator: <- (monad binding)\n"); layoutBuilder->addLexem(std::string(yytext)); return LARROW; }
"!!"    { LOG_LEXEM("found operator: !! (list indexing)\n"); layoutBuilder->addLexem(std::string(yytext)); return INDEXING; }
"@"     { LOG_LEXEM("found operator: as-pattern (@)\n"); layoutBuilder->addLexem(std::string(yytext)); return ASPATTERN; }
"::"    { LOG_LEXEM("found operator: type annotation (::)\n"); layoutBuilder->addLexem(std::string(yytext)); return DCOLON; }
"=>"    { LOG_LEXEM("found operator: type constraint (=>)\n"); layoutBuilder->addLexem(std::string(yytext)); return DARROW; }
"<*>"   { LOG_LEXEM("found operator: <*>\n"); layoutBuilder->addLexem(std::string(yytext)); return APPLYFUNCTOR; }
"<$>"   { LOG_LEXEM("found operator: <$>\n"); layoutBuilder->addLexem(std::string(yytext)); return FMAPOP; }
"$!"    { LOG_LEXEM("found operator: $!\n"); layoutBuilder->addLexem(std::string(yytext)); return STRICTAPPLY; }
"|"     { LOG_LEXEM("found operator: | (guards)\n"); layoutBuilder->addLexem(std::string(yytext)); return GUARDS; }

	
{SMALL}({WORD}|')*  { 
	layoutBuilder->addLexem(std::string(yytext)); 
	if (layoutBuilder->canEmit()) {
		yyless(0);
		EMIT_LEXEM
	} 
	else {
		LOG_LEXEM("found function identifier: %s\n", yytext);
		yylval.str = yytext;
		return FUNC_ID;
	}
}
{LARGE}({WORD}|')*  { 
	LOG_LEXEM("found constructor identifier: %s\n", yytext); 
	layoutBuilder->addLexem(std::string(yytext));
	return CONSTRUCTOR_ID;
}

{INT_8}  { 
  	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 8)) {
		std::cerr << "Error! Incorrect octal literal: " << yytext << std::endl;
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return c == '8' || c == '9' || std::isalpha(c); })) {
		yylval.intVal = strtoll(cleaned.c_str(), NULL, 8);
		LOG_LEXEM("found octal integer literal: %ld\n", yylval.intVal);
		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}
		return INTC;
	}

	std::cerr << "Error! Incorrect octal integer literal: " << cleaned + after_literal << std::endl;
	return -1;
}

{INT_10} {
	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 10)) {
		std::cerr << "Error! Incorrect decimal literal: " << yytext << std::endl;
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return std::isalpha(c); })) {
		yylval.intVal = strtoll(cleaned.c_str(), NULL, 0); 
		LOG_LEXEM("found decimal integer literal: %ld\n", yylval.intVal);
		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}
		return INTC;
	}

	std::cerr << "Error! Incorrect decimal integer literal: " << cleaned + after_literal << std::endl;
	return -1;
}

{INT_16} { 
	std::string cleaned;
  	if (!clean_integer(yytext, cleaned, 16)) {
		std::cerr << "Error! Incorrect hexadecimal integer literal: " << yytext << std::endl;
		return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return std::isalpha(c); })) {
		cleaned = replaceComma(cleaned);
		yylval.intVal = strtoll(cleaned.c_str(), NULL, 16); 
		LOG_LEXEM("found hexadecimal integer literal: %ld\n", yylval.intVal);
		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}
		return INTC;
	}

	std::cerr << "Error! Incorrect hexadecimal integer literal: " << cleaned + after_literal << std::endl;
	return -1;
}

{FLOAT}  {
  	std::string cleaned;
    if (!clean_float(yytext, cleaned)) {
      std::cerr << "Error! Incorrect float literal: " << yytext << std::endl;
      return -1;
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
    if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
                           [](char c) {return std::isalpha(c); })) {
		// cleaned = replaceComma(cleaned);
		yylval.floatVal = std::stold(cleaned);

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}		
		LOG_LEXEM("found float literal: %Lf\n", yylval.floatVal);	
		return FLOATC;
	}  
    std::cerr << "Error! Incorrect float literal: " << cleaned + after_literal << std::endl;
    return -1;
}

"--"						{ BEGIN(SINGLE_LINE_COMMENT); }
<SINGLE_LINE_COMMENT>[^\n]			
<SINGLE_LINE_COMMENT>\n		{ LOG_LEXEM("found a single line comment\n"); BEGIN(INITIAL); yyless(0); }

"{-"                        { BEGIN(MULTI_LINE_COMMENT); opened_line = yylineno; }
<MULTI_LINE_COMMENT>[^-]+   
<MULTI_LINE_COMMENT>"-"[^}]  
<MULTI_LINE_COMMENT>"-}"    { BEGIN(INITIAL); LOG_LEXEM("found a multi line comment\n"); }
<MULTI_LINE_COMMENT><<EOF>> { LOG_LEXEM("ERROR: end of file before end of comment opened in %d line", opened_line); return -1; }

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
		LOG_LEXEM("ERROR: char literal opened in %d line can't be longer than 1 symbol!\n", opened_line);
	}
	else {
		LOG_LEXEM("found char: %s\n", buffer.c_str());
	}
}
<CHAR><<EOF>>			{ LOG_LEXEM("ERROR: end of file in char literal opened in %d line\n", opened_line); return -1; }

\"						{ BEGIN(STRING); buffer = ""; opened_line = yylineno; }
<STRING>\\[ \n\t]*\\	{ yylineno += occurencesCount(yytext, "\n"); /* Multiline string separator */ }
<STRING>[^\"\\] 		{ buffer += yytext; }
<STRING>\"				{ BEGIN(INITIAL); LOG_LEXEM("found string: %s\n", buffer.c_str()); }
<STRING><<EOF>>			{ LOG_LEXEM("ERROR: end of file in string literal opened in %d line\n", opened_line); return -1; }

[\n\t ] { if (yytext[0] == '\n') { yylineno++; } layoutBuilder->addSpace(yytext[0]); }

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

static int clean_float(const std::string& input_string, std::string& cleaned) {
    int len = input_string.length();
    
    // Проверка на подчеркивания в конце числа
    if (input_string.back() == '_') {
        std::cerr << "Error: underscores cannot be at the end of the number\n";
        return 0;
    }

    for (int i = 0; i < len; i++) {
        char c = input_string[i];
        
        if (c == '_') {
            // Проверка, что подчеркивание не идет перед или сразу после точки
            if ((i > 0 && input_string[i - 1] == '.') || (i < len - 1 && input_string[i + 1] == '.')) {
                std::cerr << "Error: underscore cannot be adjacent to the decimal point\n";
                return 0;
            }
            // Пропускаем подчеркивания
            continue;
        } else if (c == '.') {
            cleaned += c;
        } else if (c == 'e' || c == 'E') {
            cleaned += 'e';
            i++; // Переход к следующему символу после 'e'/'E'

            // Проверка на знак после экспоненты
            if (i < len && (input_string[i] == '+' || input_string[i] == '-')) {
                cleaned += input_string[i];
                i++;
            }

            // Если после 'e'/'E' сразу подчеркивание или отсутствуют цифры
            if (i >= len || input_string[i] == '_' || !std::isdigit(input_string[i])) {
                std::cerr << "Error: invalid exponent format\n";
                return 0;
            }

            // После экспоненты ожидаем цифры
            
            cleaned += input_string[i];
            continue;

        } else if (std::isdigit(c)) {
            cleaned += c;
            
        }
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

