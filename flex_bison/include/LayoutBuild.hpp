#pragma once

#include <vector>
#include <memory>
#include <stack>
#include <stdexcept>
#include <functional>
#include <ranges>

#include <Parser.hpp>
#include <Token.hpp>

namespace ranges = std::ranges;


class LayoutBuilderState;

class LayoutBuilder {
public:
    LayoutBuilder();

    std::vector<Token> withLayout(const std::vector<Token>& tokens);

    void pushIndent(int indent);
    void pushCurrentIndent();
    void addToIndent(int indent);
    void newLine();
    int popIndent();
    int topIndent();

    void chageState(LayoutBuilderState* newState);

    std::vector<Token>& getTokens();

    static constexpr int TAB_SIZE = 4;
    static constexpr std::array<int, 4> keywords = {WHEREKW, DOKW, OFKW, LETKW};

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
 * Состояние в котором билдер находится после первой лексемы и до самого конца (пока не встретит перенос строки)
 * 
 * Обязанности:
 *  1. Добавлять в вектор встреченные токены кроме пробельных
 *  2. Перебросить LayoutBuilder в состояние BeforeLexemState если встречено ключевое слово размещения
 * 
 */
class MiddleLineState : public LayoutBuilderState {
public:
    MiddleLineState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}
    void addToken(std::vector<Token>::iterator& token) override;
};


/**
 * Состояние в котором билдер находится в момент встречи первой лексемы в строке
 * 
 * Обязанности:
 *  1. Зафиксировать индетацию первой лексемы
 *  2. Вставить токен ';' если индентация лексемы равна индентации перед предыдущей лексемой
 *  3. Вставить токен { если лексема - первая после where, do, of или let
 *  4. Вставить токе } если индетация лексемы меньше индетации перед предыдущей лексемой
 * 
 */
class FirstLexemState : public LayoutBuilderState {
public:
    FirstLexemState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

    void addToken(std::vector<Token>::iterator& token) override {
        Token prevToken = *(token - 1);
        auto& tokens = owner->getTokens();

        owner->pushCurrentIndent();

        if (ranges::any_of(owner->keywords, [prevToken](int t){ return t == prevToken.id; })) {
            tokens.emplace_back(VOCURLY);
            owner->chageState(new MiddleLineState(owner.get()));
        }

        int topIndent = owner->popIndent();
        int prevIndent = owner->topIndent();
        
        if (topIndent == prevIndent) {
            tokens.emplace_back(SEMICOL);
        }
        else if (topIndent < prevIndent) {
            tokens.emplace_back(VCCURLY);
        }
        
        tokens.push_back(*token);
        ++token;
    }
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

void MiddleLineState::addToken(std::vector<Token>::iterator& token) {
    owner->getTokens().push_back(*token);

    // Если токен - ключевое слово, переходим к FirstLexemState
    if (ranges::any_of(owner->keywords, [token](int t){ return t == token->id; })) {
        owner->chageState(new FirstLexemState(owner.get()));
    }
    else if (token->id == SPACE) {
        owner->addToIndent(1);
    }
    else if (token->id == TAB) {
        owner->addToIndent(LayoutBuilder::TAB_SIZE);
    }
    else if (token->id == NEWLINE) {
        owner->chageState(new BeforeLexemState(owner.get()));
    }

    ++token;
}

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
