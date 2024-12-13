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

std::vector<IndentedToken>::iterator tokensIter;
std::vector<IndentedToken>::iterator tokensEnd;

std::string getLineFromFile(const std::string& fileName, int lineNumber) {
    std::ifstream file(fileName); // Открываем файл
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + fileName);
    }

    std::string line;
    int currentLine = 1;

    // Читаем файл построчно
    while (std::getline(file, line)) {
        if (currentLine == lineNumber) {
            return line; // Возвращаем нужную строку
        }
        currentLine++;
    }

    throw std::out_of_range("Line number out of range: " + std::to_string(lineNumber));
}

std::vector<IndentedToken> getTokens() {
    std::vector<IndentedToken> tokens;

    do {
        tokens.push_back(original_yylex());
    } while (tokens.back().type != EOF);

    return tokens;
}

int main(int argc, char* argv[]) {
    const char* default_file = "flex_bison/resources/code_examples/sample.hs";
    FILE* input_file = nullptr;
    std::string filePath;

    if (argc == 1) {
        input_file = fopen(default_file, "r");
        filePath = default_file;
        if (!input_file) {
            perror("Error opening default input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } 
    else if (argc == 2) {
        input_file = fopen(argv[1], "r");
        filePath = argv[1];
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
            if (input_file) {
                fclose(input_file);  
            }

            std::string line = std::to_string(e.getLine()) + " | ";
            std::cerr << line << getLineFromFile(filePath, e.getLine()) << std::endl;
            std::cerr << std::string(e.getColumn() + line.length(), ' ') << "^" << std::endl;
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
    
    return EXIT_SUCCESS;
}
