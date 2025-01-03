#include "LayoutBuild.hpp"

LayoutBuilder::LayoutBuilder() : stateMachine(this), keywords({ WHEREKW, LETKW, INKW, OFKW, DOKW }), stopWords({ELSEKW}) {}

std::vector<IndentedToken> LayoutBuilder::withLayout(std::vector<IndentedToken> rawTokens) {
    Iterator<IndentedToken> token(rawTokens);

    // До предпоследнего токена, т.к. последний - EOF
    while (token.hasNext()) {
        onAddLexem();
        stateMachine.currentState()->addToken(token);
        onAddLexem = [] {};
    }
    stateMachine.popAll();

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
