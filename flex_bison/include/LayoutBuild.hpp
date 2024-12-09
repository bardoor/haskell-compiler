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

/**
 * Стековая машина состояний LayoutBuilder
 */
class StackStateMachine {
public:
    explicit StackStateMachine(LayoutBuilder* owner);  

    LayoutBuilderState* currentState();
    void pop();
    void popAll();
    void push(std::unique_ptr<LayoutBuilderState> state);

private:
    std::stack<std::unique_ptr<LayoutBuilderState>> stateStack;
};

/**
 * Строитель лексем размещения (открывающие и закрывающие фигруные скобки, точки с запятыми)
 */
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

/**
 * Абстрактное состояние, в котором находится LayoutBuilder
 * 
 * Обязанность:
 *      Задавать поведение LayoutBuilder при встрече лексем
 */
class LayoutBuilderState {
public:
    explicit LayoutBuilderState(LayoutBuilder* owner);
    virtual void onEnter() = 0;
    virtual void addToken(Iterator<IndentedToken>& token) = 0;
    virtual void onExit() = 0;
    virtual ~LayoutBuilderState();

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
    explicit KeywordState(LayoutBuilder* owner);
    virtual void onEnter() override {};
    void addToken(Iterator<IndentedToken>& token) override;
    virtual void onExit() override {};
};

/**
 * Состояние, в котором находится LayoutBuilder 
 * 
 * Обязанность:
 *      Создать первоначальный контекст размещения
 */
class ExplicitLayoutState : public LayoutBuilderState {
public:
    explicit ExplicitLayoutState(LayoutBuilder* owner);
    virtual void onEnter() override {};
    void addToken(Iterator<IndentedToken>& token) override;
    virtual void onExit() override {};
};

/**
 * Состояние, в котором находится LayoutBuilder после встречи ключевого слова, 
 * за которым не следует '{' и до уменьшения индетации 
 * 
 * Обязанность:
 *      Расстановка лексем размещения в зависимости от индетации
 */
class ImplicitLayoutState : public LayoutBuilderState {
public:
    explicit ImplicitLayoutState(LayoutBuilder* owner);
    virtual void onEnter() override;
    void addToken(Iterator<IndentedToken>& token) override;
    virtual void onExit() override;

private:
    unsigned sectionIndent;
    bool isFirstToken = true;
};

/**
 * Состояние, в котором находится LayoutBuilder изначально
 * 
 * Обязанность:
 *      Создать первоначальный контекст размещения
 */
class InitBuilderState : public LayoutBuilderState {
public:
    explicit InitBuilderState(LayoutBuilder* owner);
    virtual void onEnter() override {};
    void addToken(Iterator<IndentedToken>& token) override;
    virtual void onExit() override {};
};
