#include <stack>
#include <queue>
#include <string>

enum class Lexem {
    OPEN_BRACE, CLOSING_BRACE,
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
    void newLine() {
        currentOffset = 0;
    }

    void addLexem(std::string lexem) {
        if (rememberNextOffset) {
            offsetStack.push(currentOffset);
            rememberNextOffset = false;
        }

        currentOffset += lexem.length();

        if (lexem == "where" || lexem == "do" || lexem == "let" || lexem == "of") {
            lexemsToEmit.push(Lexem::OPEN_BRACE);
            rememberNextOffset = true;
        }
    }

    Lexem emitLexem() {
        Lexem emited = Lexem::NONE;

        if (!lexemsToEmit.empty()) {
            emited = lexemsToEmit.front();
        }

        return emited;
    }
};