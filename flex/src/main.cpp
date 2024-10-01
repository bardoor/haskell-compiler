#include <stdio.h>
#include <iostream>
#include <fstream>
#include <FlexLexer.h>
#include <filesystem>

void main() {
	setlocale(LC_ALL, "Russian");
	std::ifstream in;
	in.open("flex/resources/code_examples/sample.hs");
	yyFlexLexer* lex = new yyFlexLexer(in, std::cout);
	lex->yylex();
	delete lex;
}
