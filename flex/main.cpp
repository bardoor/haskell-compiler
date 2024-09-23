#include <stdio.h>
#include <fstream>
#include <FlexLexer.h>

void main() {
	std::ifstream in;
	in.open("./code_examples/sample.hs");
	yyFlexLexer* lex = new yyFlexLexer(in, std::cout);
	printf("%d\n", lex->yylex());
	delete lex;
}