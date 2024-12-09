#pragma once

#include <stack>
#include <vector>
#include <memory>
#include <unordered_set>

#include "Iterator.hpp"
#include "LexerError.hpp"
#include "Token.hpp"
#include "Parser.hpp"

class LayoutBuilderState;
class StackStateMachine;
class LayoutBuilder;

class StackStateMachine {
public:
    StackStateMachine(LayoutBuilder* owner);

    LayoutBuilderState* currentState() {
        return stateStack.top().get();
    }

    void pop() {
        stateStack.pop();
    }

    void push(std::unique_ptr<LayoutBuilderState> state) {
        stateStack.push(std::move(state));
    }

private:
    std::stack<std::unique_ptr<LayoutBuilderState>> stateStack;
};

class LayoutBuilder {
public:
    LayoutBuilder();

    std::vector<IndentedToken> withLayout(std::vector<IndentedToken> tokens);

    void changeState(std::unique_ptr<LayoutBuilderState> state) { 
        stateMachine.push(std::move(state));
    }

    void toPrevState() {
        stateMachine.pop();
    }

    std::vector<IndentedToken>& getTokens() {
        return tokens;
    }

    const std::unordered_set<int> keywords = { WHEREKW, LETKW, INKW, OFKW };
private:
    std::vector<IndentedToken> tokens;
    StackStateMachine stateMachine;
};


class LayoutBuilderState {
public:
    LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {};

    virtual void addToken(Iterator<IndentedToken>& token) = 0;

    virtual ~LayoutBuilderState() {};

protected:
    LayoutBuilder* owner;
};

/**
 * Состояние, в котором находится LayoutBuilder при встрече ключевого слова размешения (let, in, of, where)
 * 
 * Обязанность: 
 *      Перевести LayoutBuilder в состояние явного или неявно размещения в зависимости от наличия скобок
 */
class KeywordState : public LayoutBuilderState {
public:
    KeywordState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}
    void addToken(Iterator<IndentedToken>& token) override;
};


class ExplicitLayoutState : public LayoutBuilderState {
public:
    ExplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};

    void addToken(Iterator<IndentedToken>& token) override {
        if (owner->keywords.contains(token->type)) {
            if ((token + 1)->type == OCURLY) {
                
            }
        }
    }  
};


/**
 * Состояние, в котором находится LayoutBuilder от момента встречи первой лексемы после ключевого слова размещения
 *                                            и до момента встречи ключевого слова размещения 
 * 
 * Обязанность:
 *      Расстановка лексем размещения в зависимости от индетации
 */
class ImplicitLayoutState : public LayoutBuilderState {
public:
    ImplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};

    void addToken(Iterator<IndentedToken>& token) override {
        if (isFirstToken) {
            isFirstToken = false;
            sectionIndent = token->offset;
            owner->getTokens().push_back(*token);
            token++;
            return;
        }

        if (owner->keywords.contains(token->type)) {
            owner->changeState(std::make_unique<KeywordState>(owner));
            return;
        }

        // Если отступ токена меньше отступа текущей секции, переходим в предыдущее состояние
        // При это не сдвигая токен, чтоб предыдущее состояние смогло этот токен съесть
        // Если отступы одинаковые - добавляем перед токеном точку с запятой, сдвигаем его
        if (token->offset < sectionIndent) {
            owner->getTokens().emplace_back(VCCURLY, 0);
            owner->toPrevState();
        }
        else if (token->offset == sectionIndent) {
            owner->getTokens().emplace_back(SEMICOL, 0);
            owner->getTokens().push_back(*token);
            token++;
        }
    }

private:
    unsigned sectionIndent;
    bool isFirstToken = true;
};


class InitBuilderState : public LayoutBuilderState {
public:
    InitBuilderState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};
    void addToken(Iterator<IndentedToken>& token) override {
        if (token->type != MODULEKW) {
            owner->getTokens().emplace_back(VOCURLY, 0);
            owner->changeState(std::make_unique<ImplicitLayoutState>(owner));
            return;
        }

        while (token->type != WHEREKW && token.hasNext()) {
            token++;
        }

        if (token->type != WHEREKW) {
            throw LexerError("Expected 'where' before module definition");
        }

        owner->changeState(std::make_unique<KeywordState>(owner));
    }
};

LayoutBuilder::LayoutBuilder() : stateMachine(this)  {}

StackStateMachine::StackStateMachine(LayoutBuilder* owner) {
    stateStack.push(std::make_unique<InitBuilderState>(owner));
}

void KeywordState::addToken(Iterator<IndentedToken>& token) {
    if (!token.hasNext()) {
        throw LexerError("Unexpected end of file");
    }
    if ((token + 1)->type == OCURLY) {
        owner->changeState(std::make_unique<ExplicitLayoutState>(owner));
        token += 2;
    }
    else {
        owner->changeState(std::make_unique<ImplicitLayoutState>(owner));
        ++token;
    }
} 
