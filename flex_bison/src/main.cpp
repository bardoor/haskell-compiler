
#include <iostream>
#include <fstream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <vector>

#include <JsonBuild.hpp>
#include <Parser.hpp>
#include <Token.hpp>
#include <LayoutBuild.hpp>

extern IndentedToken original_yylex();
extern std::string buffer;
extern FILE* yyin;
extern void yy_scan_string(const char* str);

extern json root;

std::vector<IndentedToken>::iterator tokensIter;

int main(int argc, char* argv[]) {
    const char* default_file = "flex_bison/resources/code_examples/sample.hs";
    FILE* input_file = nullptr;

    if (argc == 1) {
        input_file = fopen(default_file, "r");
        if (!input_file) {
            perror("Error opening default input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } 
    else if (argc == 2) {
        input_file = fopen(argv[1], "r");
        if (!input_file) {
            perror("Error opening input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } 
    else if (argc == 3 && strcmp(argv[1], "-c") == 0) {
        yy_scan_string(argv[2]);
    } 
    else {
        std::cerr << "Usage: " << argv[0] << " [filename] or " << argv[0] << " -c \"input string\"" << std::endl;
        return EXIT_FAILURE;
    }

    std::vector<IndentedToken> tokens;
    do {
        tokens.push_back(original_yylex());
        //std::cout << tokens.back().toString() << std::endl;
    } while (tokens.back().type != EOF);

    std::cout << "Create layout builder" << std::endl;
    LayoutBuilder layoutBuilder = LayoutBuilder(); 
    tokens = layoutBuilder.withLayout(tokens);

    for (auto token : tokens) {
        std::cout << token.toString() << std::endl;
    }

    // tokensIter = tokens.begin();
    // yyparse();
    std::cout << "json: " << root;

    if (input_file) {
        fclose(input_file);  
    }
    
    return EXIT_SUCCESS;
}
