#pragma once

#include <vector>
#include <memory>
#include <stack>
#include <stdexcept>
#include <functional>
#include <algorithm>

#include <Parser.hpp>
#include <Token.hpp>

class LayoutBuilderState;

class LayoutBuilder {
public:
    LayoutBuilder();

    std::vector<Token> withLayout(const std::vector<Token>& tokens);

    void reduceIf(std::function<bool(int,int)> condition);
    void pushIndent(int indent);
    void pushCurrentIndent();
    void addToIndent(int indent);
    void newLine();
    int popIndent();
    int topIndent();

    void chageState(LayoutBuilderState* newState);

    std::vector<Token>& getTokens();

    static const int TAB_SIZE = 4;
private:
    std::vector<Token> tokens;
    std::unique_ptr<LayoutBuilderState> state;
    std::stack<int> indentStack;
    int currentIndent;
};

class LayoutBuilderState {
public:
    LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {}
    virtual void addToken(std::vector<Token>::iterator& token) = 0;
    virtual ~LayoutBuilderState() {}    

protected:
    std::unique_ptr<LayoutBuilder> owner;
};



/**
 * Состояние в котором билдер находится в индетации перед первой лексемой в строке
 * 
 * Обязанности:
 *  1. Прибавлять индентацию к текущему инденту LayoutBuilder в зависимости от типа токена
 *  2. Переводить LayoutBuilder в состояние FirstLexemState при встрече с непробельным токеном
 * 
 */
class BeforeLexemState : public LayoutBuilderState {
public:
    BeforeLexemState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

    void addToken(std::vector<Token>::iterator& token) override {
        switch (token->id){
            case SPACE:
                owner->addToIndent(1);
                break;
            case TAB:
                owner->addToIndent(LayoutBuilder::TAB_SIZE);
                break;
            case NEWLINE:
                owner->newLine();
                break;
            default:
                // Не сдвигаем итератор, чтобы FirstLexemState получило текущий (непробельный) токен
                owner->chageState(new FirstLexemState(owner.get()));
                return;
        }
        // Сдвигаем итератор после пробельной лексемы
        ++token;
    }
};


LayoutBuilder::LayoutBuilder() 
    : state(std::make_unique<BeforeLexemState>(this)) {}

std::vector<Token> LayoutBuilder::withLayout(const std::vector<Token>& tokens) {
    auto it = this->tokens.begin();
    while (it != this->tokens.end()) {
        state->addToken(it);
    }
    return this->tokens;
}

void LayoutBuilder::pushIndent(int indent) {
    indentStack.push(indent);
}

int LayoutBuilder::popIndent() {
    int val = indentStack.top();
    indentStack.pop();
    return val;
}

int LayoutBuilder::topIndent() {
    return indentStack.top();
}

std::vector<Token>& LayoutBuilder::getTokens() {
    return tokens;
}

void LayoutBuilder::pushCurrentIndent() {
    indentStack.push(currentIndent);
}

void LayoutBuilder::addToIndent(int indent) {
    currentIndent += indent;
}

void LayoutBuilder::newLine() {
    currentIndent = 0;
}

void LayoutBuilder::chageState(LayoutBuilderState* newState) {
    state = std::unique_ptr<LayoutBuilderState>(newState);
}
