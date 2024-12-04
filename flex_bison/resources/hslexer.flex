%option noyywrap

%{
	#include <string>
	#include <cstring>
	#include <memory>
	#include <algorithm>
	#include <charconv>

	#include "LayoutBuild.hpp"
	#include "Parser.hpp"

	#define YY_DECL int original_yylex()

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

	static bool check_prefix(const std::string& input_string, int base);
	static int clean_integer(const std::string& input_string, std::string& cleaned, int base);
	static int clean_float(const std::string& input_string, std::string& cleaned);
	std::string replaceComma(const std::string& str);
	unsigned occurencesCount(std::string str, std::string substr);

	unsigned lineno = 1;
	unsigned opened_line;
	std::string buffer;
%}

SYMBOL 		[!#$%&*+./<=>?@\\^|~:]

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

_         { LOG_LEXEM("found lexem: _\n");  return WILDCARD; }
case      { LOG_LEXEM("found lexem: case\n");  return CASEKW; }
class     { LOG_LEXEM("found lexem: class\n");  return CLASSKW; }
data      { LOG_LEXEM("found lexem: data\n");  return DATAKW; }
newtype   { LOG_LEXEM("found lexem: newtype\n");  return NEWTYPEKW; }
type      { LOG_LEXEM("found lexem: type\n");  return TYPEKW; }
of        { LOG_LEXEM("found lexem: of\n");  return OFKW; }
then      { LOG_LEXEM("found lexem: then\n");  return THENKW; }
default   { LOG_LEXEM("found lexem: default\n");  return DEFAULTKW; }
deriving  { LOG_LEXEM("found lexem: deriving\n");  return DERIVINGKW; }
do        { LOG_LEXEM("found lexem: do\n");  return DOKW; }
if        { LOG_LEXEM("found lexem: if\n");  return IFKW; }
else      { LOG_LEXEM("found lexem: else\n");  return ELSEKW; }
where     { LOG_LEXEM("found lexem: where\n");  return WHEREKW; }
let       { LOG_LEXEM("found lexem: let\n");  return LETKW; }
in 		  { LOG_LEXEM("found lexem: in\n");  return INKW; }
foreign   { LOG_LEXEM("found lexem: foreign\n");  return FOREIGNKW; }
infix     { LOG_LEXEM("found lexem: infix\n");  return INFIXKW; }
infixl    { LOG_LEXEM("found lexem: infixl\n");  return INFIXLKW; }
infixr    { LOG_LEXEM("found lexem: infixr\n");  return INFIXRKW; }
instance  { LOG_LEXEM("found lexem: instance\n");  return INSTANCEKW; }
import    { LOG_LEXEM("found lexem: import\n");  return IMPORTKW; }
module    { LOG_LEXEM("found lexem: module\n");  return MODULEKW; }

"("     |
")"     |
"{"     |
"}"     |
"["     |
"]"     |
";"		|
"+"     |
"-"     |
"~"     |
\\      |
":"		| 
"="		|
","		{ LOG_LEXEM("found: %s\n", yytext);  return yytext[0]; }
"`"     { LOG_LEXEM("found BQUOTE\n");  return BQUOTE; }
".."    { LOG_LEXEM("found operator: range (..)\n");  return DOTDOT; }
"->"    { LOG_LEXEM("found operator: -> (function type)\n");  return RARROW; }
"<-"    { LOG_LEXEM("found operator: <- (monad binding)\n");  return LARROW; }
"@"     { LOG_LEXEM("found operator: as-pattern (@)\n");  return AS; }
"::"    { LOG_LEXEM("found operator: type annotation (::)\n");  return DCOLON; }
"=>"    { LOG_LEXEM("found operator: type constraint (=>)\n");  return DARROW; }
"|"     { LOG_LEXEM("found operator: | (guards)\n");  return VBAR; }

{SYMBOL}+ { std::string syms = std::string(yytext); buffer = syms; LOG_LEXEM("found symbol: %s\n", yytext);  return SYMS; }

{SMALL}({WORD}|')*  { 
	buffer = std::string(yytext);
	LOG_LEXEM("found function identifier: %s\n", yytext);
	return FUNC_ID;
}
{LARGE}({WORD}|')*  { 
	buffer = std::string(yytext);
	LOG_LEXEM("found constructor identifier: %s\n", yytext); 
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
		buffer = cleaned; 
		LOG_LEXEM("found octal integer literal: %s\n", buffer.c_str());
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
		buffer = cleaned; 
		LOG_LEXEM("found decimal integer literal: %s\n", buffer.c_str());
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
		buffer = cleaned; 
		LOG_LEXEM("found hexadecimal integer literal: %s\n", buffer.c_str());
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
		buffer = cleaned;

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}		
		LOG_LEXEM("found float literal: %s\n", buffer.c_str());	
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
		return -1;
	}
	LOG_LEXEM("found char: %s\n", buffer.c_str());
	buffer = buffer;
	return CHARC;
}
<CHAR><<EOF>>			{ LOG_LEXEM("ERROR: end of file in char literal opened in %d line\n", opened_line); return -1; }

\"						{ BEGIN(STRING); buffer = ""; opened_line = yylineno; }
<STRING>\\[ \n\t]*\\	{ yylineno += occurencesCount(yytext, "\n"); /* Multiline string separator */ }
<STRING>[^\"\\] 		{ buffer += yytext; }
<STRING>\"				{ BEGIN(INITIAL); LOG_LEXEM("found string: %s\n", buffer.c_str()); return STRINGC; }
<STRING><<EOF>>			{ LOG_LEXEM("ERROR: end of file in string literal opened in %d line\n", opened_line); return -1; }

[\n\t ] { if (yytext[0] == '\n') { yylineno++; } }

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

