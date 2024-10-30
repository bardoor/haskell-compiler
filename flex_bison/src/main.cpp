#include <stdio.h>
#include <stdlib.h>
#include <BisonUtils.h>
#include <Parser.hpp>

extern int yylex();
extern FILE* yyin;
extern Module* root;

int main(int argc, char *argv[]) {
	const char* file = "flex_bison/resources/code_examples/sample.hs";

    FILE* input_file = fopen(file, "r");
    if (!input_file) {
        perror("Error opening input file");
        return EXIT_FAILURE;
    }

    yyin = input_file;

	yyparse();

	std::cout << root << std::endl;

	return EXIT_SUCCESS;
}

