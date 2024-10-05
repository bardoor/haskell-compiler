#ifndef LAYOUTBUILDER_H
#define LAYOUTBUILDER_H

#include <stack>
#include <queue>
#include <string>

std::string replaceComma(const std::string& str);
unsigned occurencesCount(std::string str, std::string substr);

enum class Lexem {
    OPEN_BRACE, 
    CLOSING_BRACE,
    SEMICOLON,
    NONE
};

class LayoutBuilder {
private:
    std::stack<int> offsetStack;
    std::queue<Lexem> lexemsToEmit;
    unsigned currentOffset = 0;
    bool rememberNextOffset;

public:
    LayoutBuilder();

    void offSide();
    void newLine();
    void addSpace(unsigned len);
    void addLexem(std::string lexem);
    void addOffset(std::string lexem);
    void rememberNextIndent();
    unsigned getIndent();
    void incOffset();
    Lexem emitLexem();
};

#endif // LAYOUTBUILDER_H
