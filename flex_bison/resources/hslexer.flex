%option noyywrap

%{
	#include <string>
	#include <cstring>
	#include <memory>
	#include <algorithm>
	#include <charconv>
	#include <iostream>

	#include "LexerError.hpp"
	#include "LayoutBuild.hpp"
	#include "Parser.hpp"
	#include "Token.hpp"
	#include "LexerError.hpp"

	#define DEBUG_LEXEMS

	#define YY_DECL IndentedToken original_yylex()
	#define YY_NULL IndentedToken()

	#ifdef DEBUG_LEXEMS
		 #define LOG_LEXEM(msg, ...) printf("Offset is %d\n", offset); printf(msg, ##__VA_ARGS__);
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

	unsigned offset = 0;
	unsigned lineno = 1;
	unsigned opened_line;

	IndentedToken bufferToken;
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

_         { IndentedToken token(WILDCARD, std::string(yytext), offset);   LOG_LEXEM("found lexem: _\n");        offset += strlen(yytext); return token; }
case      { IndentedToken token(CASEKW, std::string(yytext), offset);     LOG_LEXEM("found lexem: case\n");     offset += strlen(yytext); return token; }
class     { IndentedToken token(CLASSKW, std::string(yytext), offset);    LOG_LEXEM("found lexem: class\n");    offset += strlen(yytext); return token; }
data      { IndentedToken token(DATAKW, std::string(yytext), offset);     LOG_LEXEM("found lexem: data\n");     offset += strlen(yytext); return token; }
newtype   { IndentedToken token(NEWTYPEKW, std::string(yytext), offset);  LOG_LEXEM("found lexem: newtype\n");  offset += strlen(yytext); return token; }
type      { IndentedToken token(TYPEKW, std::string(yytext), offset);     LOG_LEXEM("found lexem: type\n");     offset += strlen(yytext); return token; }
of        { IndentedToken token(OFKW, std::string(yytext), offset);       LOG_LEXEM("found lexem: of\n");       offset += strlen(yytext); return token; }
then      { IndentedToken token(THENKW, std::string(yytext), offset);     LOG_LEXEM("found lexem: then\n");     offset += strlen(yytext); return token; }
default   { IndentedToken token(DEFAULTKW, std::string(yytext), offset);  LOG_LEXEM("found lexem: default\n");  offset += strlen(yytext); return token; }
deriving  { IndentedToken token(DERIVINGKW, std::string(yytext), offset); LOG_LEXEM("found lexem: deriving\n"); offset += strlen(yytext); return token; }
do        { IndentedToken token(DOKW, std::string(yytext), offset);       LOG_LEXEM("found lexem: do\n");       offset += strlen(yytext); return token; }
if        { IndentedToken token(IFKW, std::string(yytext), offset);       LOG_LEXEM("found lexem: if\n");       offset += strlen(yytext); return token; }
else      { IndentedToken token(ELSEKW, std::string(yytext), offset);     LOG_LEXEM("found lexem: else\n"); 	offset += strlen(yytext); return token; }
where     { IndentedToken token(WHEREKW, std::string(yytext), offset);    LOG_LEXEM("found lexem: where\n");    offset += strlen(yytext); return token; }
let       { IndentedToken token(LETKW, std::string(yytext), offset);   	  LOG_LEXEM("found lexem: let\n");      offset += strlen(yytext); return token; }
in        { IndentedToken token(INKW, std::string(yytext), offset); 	  LOG_LEXEM("found lexem: in\n");  	    offset += strlen(yytext); return token; }
foreign   { IndentedToken token(FOREIGNKW, std::string(yytext), offset);  LOG_LEXEM("found lexem: foreign\n");  offset += strlen(yytext); return token; }
infix     { IndentedToken token(INFIXKW, std::string(yytext), offset);    LOG_LEXEM("found lexem: infix\n");    offset += strlen(yytext); return token; }
infixl    { IndentedToken token(INFIXLKW, std::string(yytext), offset);   LOG_LEXEM("found lexem: infixl\n");   offset += strlen(yytext); return token; }
infixr    { IndentedToken token(INFIXRKW, std::string(yytext), offset);   LOG_LEXEM("found lexem: infixr\n");   offset += strlen(yytext); return token; }
instance  { IndentedToken token(INSTANCEKW, std::string(yytext), offset); LOG_LEXEM("found lexem: instance\n"); offset += strlen(yytext); return token; }
import    { IndentedToken token(IMPORTKW, std::string(yytext), offset);   LOG_LEXEM("found lexem: import\n");   offset += strlen(yytext); return token; }
module    { IndentedToken token(MODULEKW, std::string(yytext), offset);   LOG_LEXEM("found lexem: module\n");   offset += strlen(yytext); return token; }


"("     { IndentedToken token(OPAREN, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
")"     { IndentedToken token(CPAREN, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"{"     { IndentedToken token(OCURLY, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"}"     { IndentedToken token(CCURLY, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"["     { IndentedToken token(OBRACKET, std::string(yytext), offset);  LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"]"     { IndentedToken token(CBRACKET, std::string(yytext), offset);  LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"+"     { IndentedToken token(PLUS, std::string(yytext), offset);      LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"-"     { IndentedToken token(MINUS, std::string(yytext), offset);     LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"~"     { IndentedToken token(LAZY, std::string(yytext), offset);      LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
\\      { IndentedToken token(BACKSLASH, std::string(yytext), offset); LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
":"		{ IndentedToken token(COLON, std::string(yytext), offset);     LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"="		{ IndentedToken token(EQ, std::string(yytext), offset);        LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
","		{ IndentedToken token(COMMA, std::string(yytext), offset); 	   LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
";"		{ IndentedToken token(SEMICOL, std::string(yytext), offset);   LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"`"     { IndentedToken token(BQUOTE, std::string(yytext), offset);    LOG_LEXEM("found BQUOTE\n");         offset += strlen(yytext); return token; }
".."    { IndentedToken token(DOTDOT, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"->"    { IndentedToken token(RARROW, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"<-"    { IndentedToken token(LARROW, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"@"     { IndentedToken token(AS, std::string(yytext), offset);        LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"::"    { IndentedToken token(DCOLON, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"=>"    { IndentedToken token(DARROW, std::string(yytext), offset);    LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }
"|"     { IndentedToken token(VBAR, std::string(yytext), offset);      LOG_LEXEM("found: '%s'\n", yytext);  offset += strlen(yytext); return token; }

{SYMBOL}+ { 
	IndentedToken token(SYMS, std::string(yytext), offset); 
	LOG_LEXEM("found symbol: %s\n", yytext); 
	offset += strlen(yytext); 
	return token; 
}

{SMALL}({WORD}|'|_)*  { 
	IndentedToken token(FUNC_ID, std::string(yytext), offset); 
	LOG_LEXEM("found function identifier: %s\n", yytext);
	offset += strlen(yytext); 
	return token;
}
{LARGE}({WORD}|')*  { 
	IndentedToken token(CONSTRUCTOR_ID, std::string(yytext), offset); 
	LOG_LEXEM("found constructor identifier: %s\n", yytext); 
	offset += strlen(yytext); 
	return token;
}

{INT_8}  { 
  	std::string cleaned;
	std::string original = std::string(yytext);
	std::string errorMessage = "Error! Incorrect octal integer literal: ";

  	if (!clean_integer(yytext, cleaned, 8)) {
		throw LexerError(errorMessage + yytext);
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return c == '8' || c == '9' || std::isalpha(c); })) {
		IndentedToken token(INTC, cleaned, offset); 
		LOG_LEXEM("found octal integer literal: %s\n", cleaned.c_str());

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}

		offset += original.length(); 
		return token;
	}

	throw LexerError(errorMessage + cleaned + after_literal);
}

{INT_10} {
	std::string cleaned;
	std::string original = std::string(yytext);
	std::string errorMessage = "Error! Incorrect decimal integer literal: ";

  	if (!clean_integer(yytext, cleaned, 10)) {
		throw LexerError(errorMessage + yytext);
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return std::isalpha(c); })) {
		IndentedToken token(INTC, cleaned, offset); 
		LOG_LEXEM("found decimal integer literal: %s\n", buffer.c_str());

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}

		offset += original.length();
		return token;
	}

	throw LexerError(errorMessage + cleaned + after_literal);
}

{INT_16} { 
	std::string cleaned;
	std::string original = std::string(yytext);
	std::string errorMessage = "Error! Incorrect hexadecimal integer literal: ";

  	if (!clean_integer(yytext, cleaned, 16)) {
		throw LexerError(errorMessage + yytext);
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
	if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
												   [](char c) {return std::isalpha(c); })) {
		IndentedToken token(INTC, cleaned, offset); 
		LOG_LEXEM("found hexadecimal integer literal: %s\n", cleaned.c_str());

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}

		offset += original.length(); 
		return token;
	}

	throw LexerError(errorMessage + cleaned + after_literal);
}

{FLOAT}  {
  	std::string cleaned;
	std::string original = std::string(yytext);
	std::string errorMessage = "Error! Incorrect float literal: ";

    if (!clean_float(yytext, cleaned)) {
		throw LexerError(errorMessage + yytext);
    }

	std::string after_literal;
	// записать в after_literal последовательность непробельных символов после сматченного числового литерала
	LOOKAHEAD(after_literal);
	
    if (after_literal.length() > 0 || std::none_of(after_literal.begin(), after_literal.end(), 
                           [](char c) {return std::isalpha(c); })) {
		// cleaned = replaceComma(cleaned);
		IndentedToken token(INTC, cleaned, offset); 
		LOG_LEXEM("found float literal: %s\n", cleaned.c_str());	

		if (after_literal.length() > 0) {
			UNPUT_STR(after_literal);
		}		

		offset += original.length(); 
		return token;
	}  

	throw LexerError(errorMessage + cleaned + after_literal);
}

"--"						{ BEGIN(SINGLE_LINE_COMMENT); }
<SINGLE_LINE_COMMENT>[^\n]			
<SINGLE_LINE_COMMENT>\n		{ LOG_LEXEM("found a single line comment\n"); BEGIN(INITIAL); yyless(0); }

"{-"                        { BEGIN(MULTI_LINE_COMMENT); opened_line = yylineno; }
<MULTI_LINE_COMMENT>[^-]+   
<MULTI_LINE_COMMENT>"-"[^}]  
<MULTI_LINE_COMMENT>"-}"    { BEGIN(INITIAL); LOG_LEXEM("found a multi line comment\n"); }
<MULTI_LINE_COMMENT><<EOF>> { throw LexerError(std::string("Unexpected end of the file after opening char literal! Line: ") + std::to_string(opened_line)); }

\'					{ BEGIN(CHAR); bufferToken = IndentedToken(CHARC, offset); offset += 1; buffer = ""; opened_line = yylineno; }
<STRING,CHAR>\\a	{ buffer += "\a"; offset += 2; }
<STRING,CHAR>\\b	{ buffer += "\b"; offset += 2; }
<STRING,CHAR>\\f	{ buffer += "\f"; offset += 2; }
<STRING,CHAR>\\n	{ buffer += "\n"; offset += 2; }
<STRING,CHAR>\\r	{ buffer +=	"\r"; offset += 2; }
<STRING,CHAR>\\v	{ buffer += "\v"; offset += 2; }
<STRING,CHAR>\\t	{ buffer += "\t"; offset += 2; }
<STRING>\\({INT_8}|{INT_10}|{INT_16}) { buffer += (char) strtol(yytext + 1, NULL, 0); offset += strlen(yytext); }
<STRING,CHAR>\\		{ buffer += "\\"; offset += 1; }
<STRING>\\&			{ offset += 2; }
<CHAR>[^\'\\]		{ buffer += yytext; offset += 1; }
<CHAR>\' { 
	BEGIN(INITIAL);

	if (buffer.size() > 1) {
		throw LexerError(std::string("Char literal can't be longer than 1 character! Line: ") + std::to_string(opened_line));
	} 

	bufferToken.repr = buffer;
	LOG_LEXEM("found char: %s\n", buffer.c_str());
	offset += 1;

	return bufferToken;
}
<CHAR><<EOF>>			{ throw LexerError(std::string("Unexpected end of the file after opening char literal! Line: ") + std::to_string(opened_line)); }

\" { 
	BEGIN(STRING); 
	bufferToken = IndentedToken(STRINGC, offset); 
	buffer = ""; 
	offset += 1; 
	opened_line = yylineno;
}
<STRING>\\[ \n\t]*\\ { 
	yylineno += occurencesCount(yytext, "\n"); 
	offset += strlen(yytext);  
}
<STRING>[^\"\\] { 
	buffer += yytext; 
	offset += strlen(yytext);
}
<STRING>\" { 
	BEGIN(INITIAL); 
	LOG_LEXEM("found string: %s\n", buffer.c_str()); 
	offset += 1; 
	bufferToken.repr = buffer; 
	return bufferToken; 
}
<STRING><<EOF>>			{ throw LexerError(std::string("Unexpected end of the file after opening string literal! Line: ") + std::to_string(opened_line)); }

\n 		{ yylineno++; offset = 0; }
\t 		{ offset += 4; }
" "	    { offset += 1; }

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
