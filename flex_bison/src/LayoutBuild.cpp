#include "LayoutBuild.hpp"
#include "LexerError.hpp"
#include "Token.hpp"


LayoutBuilder::LayoutBuilder() : stateMachine(this), keywords({ WHEREKW, LETKW, INKW, OFKW }) {}

std::vector<IndentedToken> LayoutBuilder::withLayout(std::vector<IndentedToken> rawTokens) {
    Iterator<IndentedToken> token(rawTokens);

    // До предпоследнего токена, т.к. последний - EOF
    while (token.hasNext()) {
        stateMachine.currentState()->addToken(token);
    }

    return tokens;
}

void LayoutBuilder::changeState(std::unique_ptr<LayoutBuilderState> state) {
    stateMachine.push(std::move(state));
}

void LayoutBuilder::toPrevState() {
    stateMachine.pop();
}

std::vector<IndentedToken>& LayoutBuilder::getTokens() {
    return tokens;
}


StackStateMachine::StackStateMachine(LayoutBuilder* owner) {
    stateStack.push(std::make_unique<InitBuilderState>(owner));
}

LayoutBuilderState* StackStateMachine::currentState() {
    return stateStack.top().get(); 
}

void StackStateMachine::pop() {
    if (!stateStack.empty()) {
        stateStack.pop();  
    }
}

void StackStateMachine::push(std::unique_ptr<LayoutBuilderState> state) {
    stateStack.push(std::move(state));  
}


LayoutBuilderState::LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {}

LayoutBuilderState::~LayoutBuilderState() {}


KeywordState::KeywordState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

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


ExplicitLayoutState::ExplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void ExplicitLayoutState::addToken(Iterator<IndentedToken>& token) {
}


ImplicitLayoutState::ImplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void ImplicitLayoutState::addToken(Iterator<IndentedToken>& token) {
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

    if (token->offset < sectionIndent) {
        owner->getTokens().emplace_back(VCCURLY, 0);
        owner->toPrevState();
    }
    else if (token->offset == sectionIndent) {
        owner->getTokens().emplace_back(SEMICOL, 0);
        owner->getTokens().push_back(*token);
        token++;
    } else {
        owner->getTokens().push_back(*token);
        token++;
    }
}


InitBuilderState::InitBuilderState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void InitBuilderState::addToken(Iterator<IndentedToken>& token) {
    if (token->type != MODULEKW) {
        owner->getTokens().emplace_back(VOCURLY, 0);
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

    owner->changeState(std::make_unique<KeywordState>(owner));
}
