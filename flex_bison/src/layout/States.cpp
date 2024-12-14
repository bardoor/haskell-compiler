#include "LayoutBuild.hpp"


void switchLayoutState(LayoutBuilder* owner, Iterator<IndentedToken>& token) {
    if (!owner->keywords.contains(token->type)) {
        throw LexerError("Expected keyword where, let, of or do!");
    }

    owner->getTokens().push_back(*token);

    token++;
    if (token->type == OCURLY) {
        owner->changeState(std::make_unique<ExplicitLayoutState>(owner));
    } else {
        owner->changeState(std::make_unique<ImplicitLayoutState>(owner));
    }
}


LayoutBuilderState::LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {}

LayoutBuilderState::~LayoutBuilderState() {}


InitBuilderState::InitBuilderState(LayoutBuilder* owner)
    : LayoutBuilderState(owner) {}

void InitBuilderState::addToken(Iterator<IndentedToken>& token) {
    if (token->type != MODULEKW) {
        owner->changeState(std::make_unique<ImplicitLayoutState>(owner));
        return;
    }

    while (token->type != WHEREKW && token.hasNext()) {
        owner->getTokens().push_back(*token);
        token++;
    }

    if (token->type != WHEREKW) {
        throw LexerError("Expected 'where' before module definition");
    }

    switchLayoutState(owner, token);
}

ImplicitLayoutState::ImplicitLayoutState(LayoutBuilder* owner)
    : LayoutBuilderState(owner) {}

void ImplicitLayoutState::onEnter() {
    owner->getTokens().emplace_back(VOCURLY, "{virtual\\", 0);
}

void ImplicitLayoutState::addToken(Iterator<IndentedToken>& token) {
    if (isFirstToken) {
        isFirstToken = false;
        sectionIndent = token->column;
        owner->getTokens().push_back(*token);
        token++;
        return;
    }

    if (owner->keywords.contains(token->type)) {
        switchLayoutState(owner, token);
        return;
    }

    if (token->column < sectionIndent) {
        owner->toPrevState();
    } else if (token->column == sectionIndent) {
        owner->getTokens().emplace_back(SEMICOL, ";", 0);
        owner->getTokens().push_back(*token);
        token++;
    } else {
        owner->getTokens().push_back(*token);
        token++;
    }
}

void ImplicitLayoutState::onExit() {
    owner->getTokens().emplace_back(VCCURLY, "/virtual}", 0);
}

ExplicitLayoutState::ExplicitLayoutState(LayoutBuilder* owner)
    : LayoutBuilderState(owner) {}

void ExplicitLayoutState::addToken(Iterator<IndentedToken>& token) {
    if (owner->keywords.contains(token->type)) {
        switchLayoutState(owner, token);
        return;
    } 
    
    // Если встречена закрывающая фигурная скобка - просим LayoutBuilder вернуться в предыдущее состояние
    if (token->type == CCURLY) {
        auto layoutBuilder = owner;
        owner->onAddLexem = [layoutBuilder]() { layoutBuilder->toPrevState(); };
    }

    owner->getTokens().push_back(*token);
    token++;
}
