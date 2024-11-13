#include <iostream>
#include <fstream>
#include <cstdio>
#include <cstring>
#include <cstdlib>

#include <BisonUtils.h>
#include <Parser.hpp>

extern int yylex();
extern FILE* yyin;
extern Module* root;

extern void yy_scan_string(const char* str);

int main(int argc, char* argv[]) {
    const char* default_file = "flex_bison/resources/code_examples/sample.hs";
    FILE* input_file = nullptr;

    // Определяем источник ввода: файл по умолчанию, файл из аргументов или строка
    if (argc == 1) {
        input_file = fopen(default_file, "r");
        if (!input_file) {
            perror("Error opening default input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } else if (argc == 2) {
        input_file = fopen(argv[1], "r");
        if (!input_file) {
            perror("Error opening input file");
            return EXIT_FAILURE;
        }
        yyin = input_file;
    } else if (argc == 3 && strcmp(argv[1], "-c") == 0) {
        // Используем yy_scan_string для анализа строки
        yy_scan_string(argv[2]);
    } else {
        std::cerr << "Usage: " << argv[0] << " [filename] or " << argv[0] << " -c \"input string\"" << std::endl;
        return EXIT_FAILURE;
    }

    yyparse();

    std::ofstream outfile("graph.dot");
    outfile << generateDot(root);
    outfile.close();

    if (input_file) {
        fclose(input_file);  // Закрываем файл, если он был открыт
    }
    return EXIT_SUCCESS;
}
