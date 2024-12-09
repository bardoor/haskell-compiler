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
    explicit StackStateMachine(LayoutBuilder* owner);  

    LayoutBuilderState* currentState();
    void pop();
    void push(std::unique_ptr<LayoutBuilderState> state);

private:
    std::stack<std::unique_ptr<LayoutBuilderState>> stateStack;
};

class LayoutBuilder {
public:
    LayoutBuilder(); 

    std::vector<IndentedToken> withLayout(std::vector<IndentedToken> rawTokens);

    void changeState(std::unique_ptr<LayoutBuilderState> state);
    void toPrevState();

    std::vector<IndentedToken>& getTokens();
    
    const std::unordered_set<int> keywords;

private:
    std::vector<IndentedToken> tokens;
    StackStateMachine stateMachine;
};

class LayoutBuilderState {
public:
    explicit LayoutBuilderState(LayoutBuilder* owner);
    virtual void addToken(Iterator<IndentedToken>& token) = 0;
    virtual ~LayoutBuilderState();

protected:
    LayoutBuilder* owner;
};

class KeywordState : public LayoutBuilderState {
public:
    explicit KeywordState(LayoutBuilder* owner);
    void addToken(Iterator<IndentedToken>& token) override;
};

class ExplicitLayoutState : public LayoutBuilderState {
public:
    explicit ExplicitLayoutState(LayoutBuilder* owner);
    void addToken(Iterator<IndentedToken>& token) override;
};

class ImplicitLayoutState : public LayoutBuilderState {
public:
    explicit ImplicitLayoutState(LayoutBuilder* owner);
    void addToken(Iterator<IndentedToken>& token) override;

private:
    unsigned sectionIndent;
    bool isFirstToken = true;
};

class InitBuilderState : public LayoutBuilderState {
public:
    explicit InitBuilderState(LayoutBuilder* owner);
    void addToken(Iterator<IndentedToken>& token) override;
};
