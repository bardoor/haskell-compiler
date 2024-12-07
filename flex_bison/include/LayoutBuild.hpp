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
