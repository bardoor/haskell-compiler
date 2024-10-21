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
	std::ifstream in;
	in.open("flex/resources/code_examples/sample.hs");

	if (!in.is_open()) {
		std::filesystem::path currentPath = std::filesystem::current_path();
    	std::cout << "Current Directory: " << currentPath << std::endl;
		throw std::runtime_error("Can't open file!");
	}

	yyFlexLexer* lex = new yyFlexLexer(in, std::cout);
	lex->yylex();
	delete lex;
}
