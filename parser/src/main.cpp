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

#define RED "\033[31m"
#define RESET "\033[0m"

extern IndentedToken original_yylex();
extern std::string buffer;
extern FILE* yyin;
extern void yy_scan_string(const char* str);

extern json root;

bool syntaxError = false;
std::vector<IndentedToken>::iterator tokensIter;
std::vector<IndentedToken>::iterator tokensEnd;

std::vector<std::string> lines;

std::vector<std::string> readFileToLines(const std::string& fileName) {
    std::ifstream file(fileName);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + fileName);
    }

    std::vector<std::string> lines;
    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }
    return lines;
}

std::string getLineFromVector(const std::vector<std::string>& lines, int lineNumber) {
    if (lineNumber < 1 || lineNumber > static_cast<int>(lines.size())) {
        throw std::out_of_range("Line number out of range: " + std::to_string(lineNumber));
    }
    return lines[lineNumber - 1];
}

std::vector<IndentedToken> getTokens() {
    std::vector<IndentedToken> tokens;

    do {
        tokens.push_back(original_yylex());
    } while (tokens.back().type != EOF);

    return tokens;
}

int main(int argc, char* argv[]) {
    std::string filePath;
    FILE* input_file = nullptr;

    if (argc == 1) {
        filePath = "parser/resources/code_examples/sample.hs";
        lines = readFileToLines(filePath); 

        input_file = fopen(filePath.c_str(), "r");
        if (!input_file) {
            perror("Error opening default input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } 
    else if (argc == 2) {
        filePath = argv[1];
        lines = readFileToLines(filePath); 

        input_file = fopen(filePath.c_str(), "r");
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
    try {
        tokens = getTokens();
    } catch (LexerError& e) {
        std::cerr << RED << "Lexer error: " << e.what() << RESET << std::endl;
        if (!filePath.empty()) {
            std::string linePrefix = std::to_string(e.getLine()) + " | ";
            std::cerr << linePrefix << getLineFromVector(lines, e.getLine()) << std::endl;
            std::cerr << std::string(e.getColumn() + linePrefix.length(), ' ') << "^" << std::endl;
        }
        if (input_file) {
            fclose(input_file);  
        }
        return EXIT_FAILURE;
    }

    LayoutBuilder layoutBuilder = LayoutBuilder(); 
    tokens = layoutBuilder.withLayout(tokens);

    for (const auto& token : tokens) {
        std::cout << token.repr << " ";
    }
    std::cout << std::endl;

    tokensIter = tokens.begin();
    tokensEnd = tokens.end();

    yyparse();

    std::cout << "json: " << root;

    if (input_file) {
        fclose(input_file);  
    }

    return EXIT_FAILURE ? syntaxError : EXIT_SUCCESS;
}
