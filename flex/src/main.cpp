#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <cstdio>

#include <FlexLexer.h>

int main(void) {
	setlocale(LC_ALL, "Russian");
	std::ifstream in;
	in.open("flex/resources/code_examples/sample.hs");

	if (!in.is_open()) {
		throw std::runtime_error("Can't open file!");
	}

	yyFlexLexer* lex = new yyFlexLexer(in, std::cout);
	lex->yylex();
	delete lex;
}
