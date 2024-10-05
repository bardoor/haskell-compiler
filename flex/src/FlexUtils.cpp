#include "FlexUtils.h"

std::string replaceComma(const std::string& str) {
    std::string result = str;
    size_t start_pos = 0;

    while ((start_pos = result.find('.', start_pos)) != std::string::npos) {
        result.replace(start_pos, 1, ","); 
        start_pos++;  
    }

    return result; 
}

unsigned occurencesCount(std::string str, std::string substr) {
    unsigned occurences = 0;
    size_t pos = 0;

    while ((pos = str.find(substr, pos)) != std::string::npos) {
        pos += substr.length();
        occurences++;
    }

    return occurences;
}

LayoutBuilder::LayoutBuilder() : currentOffset(0), rememberNextOffset(false) {}

void LayoutBuilder::newLine() {
    currentOffset = 0;
}

void LayoutBuilder::addSpace(unsigned len) {
    currentOffset += len;
}

void LayoutBuilder::addLexem(std::string lexem) {
    // Запоминаем величину отступа, если лексема - первая в блоке where, do, let, of
    if (rememberNextOffset) {
        offsetStack.push(currentOffset);
        rememberNextOffset = false;
    }

    currentOffset += lexem.length();

    // Испускаем открывающую скобку если лексема - where, do, let или of
    // Запоминаем отступ следующей лексемы
    if (lexem == "where" || lexem == "do" || lexem == "let" || lexem == "of") {
        lexemsToEmit.push(Lexem::OPEN_BRACE);
        rememberNextOffset = true;
    }

    // Испускаем закрывающую скобку если 
}

void LayoutBuilder::incOffset() {
    currentOffset++;
}

void LayoutBuilder::addOffset(std::string lexem) {
    currentOffset += lexem.length();
}

void LayoutBuilder::offSide() {
    lexemsToEmit.push(Lexem::OPEN_BRACE);
}

void LayoutBuilder::rememberNextIndent() {
    rememberNextOffset = true;
}

unsigned LayoutBuilder::getIndent() {
    return currentOffset;
}

Lexem LayoutBuilder::emitLexem() {
    if (lexemsToEmit.empty()) {
        return Lexem::NONE;
    }

    Lexem nextLexem = lexemsToEmit.front();
    lexemsToEmit.pop();
    return nextLexem;
}

