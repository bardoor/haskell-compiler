#include <stdio.h>
#include <stdlib.h>
#include <Parser.hpp>

extern int yylex();
extern FILE* yyin;

int main(int argc, char *argv[]) {
	const char* file = "flex_bison/resources/code_examples/sample.hs";

    FILE* input_file = fopen(file, "r");
    if (!input_file) {
        perror("Error opening input file");
        return EXIT_FAILURE;
    }

    yyin = input_file;

	while (yylex() != 0) {
		yyparse();
	}

	return EXIT_SUCCESS;
}

