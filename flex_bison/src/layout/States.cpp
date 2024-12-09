#include "LayoutBuild.hpp"


LayoutBuilderState::LayoutBuilderState(LayoutBuilder* owner) : owner(owner) {}

LayoutBuilderState::~LayoutBuilderState() {}


KeywordState::KeywordState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void KeywordState::addToken(Iterator<IndentedToken>& token) {
    if (!token.hasNext()) {
        throw LexerError("Unexpected end of file");
    }
    
    owner->getTokens().push_back(*token);
    if ((token + 1)->type == OCURLY) {
        owner->changeState(std::make_unique<ExplicitLayoutState>(owner));
        token += 2;
    }
    else {
        owner->changeState(std::make_unique<ImplicitLayoutState>(owner));
        ++token;
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


ImplicitLayoutState::ImplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void ImplicitLayoutState::onEnter() {
    owner->getTokens().emplace_back(VOCURLY, "virtual open curly", 0);
}

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
        owner->toPrevState();
    }
    else if (token->offset == sectionIndent) {
        owner->getTokens().emplace_back(SEMICOL, "semicolon", 0);
        owner->getTokens().push_back(*token);
        token++;
    } else {
        owner->getTokens().push_back(*token);
        token++;
    }
}

void ImplicitLayoutState::onExit() {
    owner->getTokens().emplace_back(VCCURLY, "virtual closing curly", 0);
}


ExplicitLayoutState::ExplicitLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void ExplicitLayoutState::addToken(Iterator<IndentedToken>& token) {}
