#pragma once

#include <stack>
#include <vector>
#include <memory>
#include <unordered_set>

#include "LexerError.hpp"
#include "Token.hpp"
#include "Parser.hpp"

class LayoutBuilderState;

class LayoutBuilder {
public:
    LayoutBuilder();

    std::vector<IndentedToken> withLayout(std::vector<IndentedToken> tokens);

    void changeState(LayoutBuilderState* state) { 
        this->state = std::unique_ptr<LayoutBuilderState>(state);
    }

    std::vector<IndentedToken>& getTokens() {
        return tokens;
    }

    int pushIndent(int value) {
        indentStack.push(value);
    }

    void popIndent() {
        indentStack.pop();
    }

    int topIndent() {
        return indentStack.top();
    }

    const std::unordered_set<int> keywords = { WHEREKW, LETKW, INKW, OFKW };
private:
    std::vector<IndentedToken> tokens;
    std::stack<int> indentStack;
    std::unique_ptr<LayoutBuilderState> state;
};


class LayoutBuilderState {
public:
    LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {};

    virtual void addToken(std::vector<IndentedToken>::iterator& token, std::vector<IndentedToken>::iterator& end) = 0;

    virtual ~LayoutBuilderState() {};

protected:
    LayoutBuilder* owner;
};


class KeywordState : public LayoutBuilderState {};

class ExplicitLayoutState : public LayoutBuilderState {
public:
    ExplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};

    void addToken(std::vector<IndentedToken>::iterator& token, std::vector<IndentedToken>::iterator& end) override {
        if ((token + 1) == end) {
            throw LexerError("Unexpected end of file");
        }

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

    void addToken(std::vector<IndentedToken>::iterator& token, std::vector<IndentedToken>::iterator& end) override {
        if (isFirstToken) {
            owner->pushIndent(token->offset);
        }

        if (owner->keywords.contains(token->type)) {
            owner->changeState(new KeywordState(owner));
            return;
        }

        if (owner->topIndent() < token->offset) {
            owner->getTokens().emplace_back(VCCURLY, 0);
            owner->popIndent();

            if (owner->topIndent() >= 0) {
                owner->changeState(new ImplicitLayoutState(owner));
            }
            else {
                owner->changeState(new ExplicitLayoutState(owner));
            }
        }
        else if (owner->topIndent() == token->offset) {
            owner->getTokens().emplace_back(SEMICOL, 0);
            owner->getTokens().push_back(*token);
        }
    }

private:
    bool isFirstToken = true;
};


/**
 * Состояние, в котором находится LayoutBuilder при встрече ключевого слова размешения (let, in, of, where)
 * 
 * Обязанность: 
 *      Перевести LayoutBuilder в состояние явного или неявно размещения в зависимости от наличия скобок
 */
class KeywordState : public LayoutBuilderState {
public:
    KeywordState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};
    void addToken(std::vector<IndentedToken>::iterator& token, std::vector<IndentedToken>::iterator& end) override {
        if ((token + 1) == end) {
            throw LexerError("Unexpected end of file");
        }

        if ((token + 1)->type == OCURLY) {
            owner->changeState(new ExplicitLayoutState(owner));
            token += 2;
        }
        else {
            owner->changeState(new ImplicitLayoutState(owner));
            ++token;
        }
    }  
};


class InitBuilderState : public LayoutBuilderState {
public:
    InitBuilderState(LayoutBuilder* owner) : LayoutBuilderState(owner) {};
    void addToken(std::vector<IndentedToken>::iterator& token, std::vector<IndentedToken>::iterator& end) override {
        if (token->type != MODULEKW) {
            owner->getTokens().emplace_back(VOCURLY, 0);
            owner->changeState(new ImplicitLayoutState(owner));
            return;
        }

        std::vector<IndentedToken>::iterator& curToken = token;
        while (curToken->type != WHEREKW && curToken != end) {
            ++curToken;
        }

        if (curToken == end) {
            throw LexerError("Unexpected end of file");
        }

        owner->changeState(new KeywordState(owner));
    }
};