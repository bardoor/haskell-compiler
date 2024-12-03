#include "LayoutBuild.hpp"

// #define DEBUG_STATES

#ifdef DEBUG_STATES
    #define LOG_STATE(msg) std::cout << msg << std::endl;
#else
    #define LOG_STATE(msg)
#endif

const char* staticMap(char c) {
    switch (c) {
        case '\a': return "\\a";
        case '\b': return "\\b";
        case '\t': return "\\t";
        case '\n': return "\\n";
        case '\v': return "\\v";
        case '\f': return "\\f";
        case '\r': return "\\r";

        case '\"': return "\\\"";
        case '\'': return "\\\'";
        case '\?': return "\\\?";
        case '\\': return "\\\\";
    }
    return nullptr;
}

std::string escape_cpp(const std::string& input) {
    std::stringstream ss;
    for (char c : input) {
        const char* str = staticMap(c);
        if (str) { 
            ss << str;
        } else if (!isprint(static_cast<unsigned char>(c))) {
            ss << "\\u" << std::hex << std::setfill('0') << std::setw(4) << (static_cast<unsigned int>(static_cast<unsigned char>(c)));
        } else {
            ss << c;
        }
    }
    return ss.str();
}

LayoutBuilderState::LayoutBuilderState(LayoutBuilder* stateOwner) : owner(stateOwner) {}

LayoutBuilderState::~LayoutBuilderState() {}

void LayoutBuilderState::addSpace(const char lexem) {
    if (lexem == ' ') {
        owner->addOffset(1);
    }
    else if (lexem == '\t') {
        owner->addOffset(TAB_SIZE);
    }
    else if (lexem == '\n') {
        owner->resetOffset();
    }
}

void LayoutBuilderState::eof() {
    while (!owner->stackEmpty()) {
        owner->popOffset();
        owner->pushLexem(Lexem::CLOSING_BRACE);
    }
}

NewLineState::NewLineState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}
NewLineState::NewLineState(LayoutBuilder* owner, const std::string& lexem) 
    : LayoutBuilderState(owner) {
        needAddLexem = true;
    }

void NewLineState::addLexem(const std::string& lexem) {
    needAddLexem = false;
    LOG_STATE("-- NewLineState -- lexem: " << escape_cpp(lexem));

    if (std::isspace(lexem[0])) {
        addSpace(lexem[0]);
    }
    else {
        // Переход к состоянию LeadingLexemState
        owner->changeState(std::make_unique<LeadingLexemState>(owner, lexem));
    }
}


ZeroLayoutState::ZeroLayoutState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

void ZeroLayoutState::addLexem(const std::string& lexem) {
    needAddLexem = false;

    LOG_STATE("-- ZeroLayoutState -- lexem: " << escape_cpp(lexem));

    // Окончание нулевого контекста размещения
    if (lexem == "}") {
        if (owner->topOffsetIsZero()) {
            owner->popOffset();
        }
        else {
            throw std::runtime_error("Explicit closing brace after implicit opening brace");
        }
    }

    // Переход к состоянию новой строки, если нулевого контекста больше нет 
    if (!owner->topOffsetIsZero()) {
        owner->changeState(std::make_unique<NewLineState>(owner));
    }
}

StartLayoutState::StartLayoutState(LayoutBuilder* owner, bool bracketIsExplicit) 
    : LayoutBuilderState(owner) { bracketExplicit = bracketIsExplicit; }

StartLayoutState::StartLayoutState(LayoutBuilder* owner, bool bracketIsExplicit, const std::string& lexem) 
    : LayoutBuilderState(owner) {
    bracketExplicit = bracketIsExplicit;
    needAddLexem = true;
}

void StartLayoutState::addLexem(const std::string& lexem) {
    needAddLexem = false;

    LOG_STATE("-- START LAYOUT -- lexem: " << escape_cpp(lexem));

    if (lexem.length() == 1 && std::isspace(lexem[0])) {
        if (lexem[0] == '\n') {
            owner->newLine();
        }
        else {
            owner->addOffset(1);
        }
        return;
    }

    if (lexem == "{") {
        // Следующая лексема идет в состояние нулевого размещения
        if (bracketExplicit){
            owner->pushOffsetZero();
            owner->changeState(std::make_unique<ZeroLayoutState>(owner));
        }
        // Пропускаем неявную скобку
        else {
            return;
        }
    }
    else {
        // Переход к состоянию MiddlePositionState с текущим смещением
        LOG_STATE("-- START LAYOUT -- pushed offset on " << lexem);
        owner->pushCurrentOffset();
        owner->changeState(std::make_unique<MiddlePositionState>(owner, lexem));
    }
}

LeadingLexemState::LeadingLexemState(LayoutBuilder* owner, const std::string& lexem) 
    : LayoutBuilderState(owner) {
    needAddLexem = true;
}

void LeadingLexemState::addLexem(const std::string& lexem) {
    needAddLexem = false;

   LOG_STATE("-- LEADING LEXEM -- lexem: " << escape_cpp(lexem));

    if (lexem == " " || lexem == "\t" || lexem == "\n") {
        throw std::runtime_error("Unresolved space character in LeadingLexemState: " + escape_cpp(lexem));
    }
    

    if (lexem == "where" || lexem == "do" || lexem == "let" || lexem == "of") {
        LOG_STATE("-- LEADING LEXEM -- emit open brace");

        owner->addOffset(static_cast<int>(lexem.length()));
        owner->pushLexem(Lexem::OPEN_BRACE);

        owner->changeState(std::make_unique<StartLayoutState>(owner, false));
        return;
    }

    while (owner->offsetDifference() == -1) {
        LOG_STATE("-- LEADING LEXEM -- emit closing brace");

        owner->popOffset();
        owner->pushLexem(Lexem::CLOSING_BRACE);
        if (owner->offsetDifference()) {
            std::cerr << "Error: incorrect indentation!" << std::endl;
        }
        owner->changeState(std::make_unique<MiddlePositionState>(owner, lexem));
        return;
    }

    if (owner->offsetDifference() == 0) {
        LOG_STATE("-- LEADING LEXEM -- emit semicolon");

        owner->pushLexem(Lexem::SEMICOLON);
    }

    LOG_STATE("-- LEADING LEXEM -- GOING TO MIDDLE POSITION")
    owner->addOffset(lexem.length());
    owner->changeState(std::make_unique<MiddlePositionState>(owner));
}

MiddlePositionState::MiddlePositionState(LayoutBuilder* owner) : LayoutBuilderState(owner) {}

MiddlePositionState::MiddlePositionState(LayoutBuilder* owner, const std::string& lexem) 
    : LayoutBuilderState(owner) {
    needAddLexem = true;
}

void MiddlePositionState::addLexem(const std::string& lexem) {
    needAddLexem = false;
    
    LOG_STATE("-- MiddlePosState -- lexem: " << escape_cpp(lexem));

    if (lexem == "where" || lexem == "do" || lexem == "let" || lexem == "of") {
        owner->changeState(std::make_unique<NewLineState>(owner, lexem));
    }
    else {
        owner->addOffset(static_cast<int>(lexem.length()));
    }
}

void MiddlePositionState::addSpace(const char lexem) {
    if (lexem == ' ') {
        owner->addOffset(1);
    }
    else if (lexem == '\t') {
        owner->addOffset(TAB_SIZE);
    }
    else if (lexem == '\n') {
        owner->resetOffset();
        owner->changeState(std::make_unique<NewLineState>(owner, std::string(1, lexem)));
    }
}

LayoutBuilder::LayoutBuilder() {
    // Создаём начальное состояние NewLineState
    state = std::make_unique<NewLineState>(this);
}

void LayoutBuilder::newLine() {
    currentOffset = 0;
}

void LayoutBuilder::addSpace(const char lexem) {
    state->addSpace(lexem);
}

void LayoutBuilder::addLexem(const std::string& lexem) {
    do {
        state->addLexem(lexem);
    } while (state->needToAddLexem());
}

void LayoutBuilder::eof() {
    state->eof();
}

int LayoutBuilder::offsetDifference() {
    if (offsetStack.empty()) return -2; // Проверка на пустоту стэка
    if (offsetStack.top() == static_cast<int>(currentOffset)) {
        return 0;
    }
    else if (offsetStack.top() < static_cast<int>(currentOffset)) {
        return 1;
    }
    else {
        LOG_STATE("++ OFFSET DIFFERENCE ++ stack: " << offsetStack.top() << " current: " << currentOffset);
        return -1;
    }
}

bool LayoutBuilder::topOffsetIsZero() const {
    if (offsetStack.empty()) {
        return false; 
    }    
    return offsetStack.top() == 0;
}

void LayoutBuilder::pushOffsetZero() {
    offsetStack.push(0);
}

void LayoutBuilder::pushCurrentOffset() {
    LOG_STATE("++ LAYOUT BUILDER ++ pushing " << currentOffset);
    offsetStack.push(static_cast<int>(currentOffset));
}

bool LayoutBuilder::stackEmpty() {
    return offsetStack.empty();
}

void LayoutBuilder::popOffset() {
    if (!offsetStack.empty()) {
        offsetStack.pop();
    }
    else {
        throw std::runtime_error("Offset stack is empty!");
    }
}

void LayoutBuilder::pushLexem(Lexem lexem) {
    lexemsToEmit.push(lexem);
}

void LayoutBuilder::addOffset(int value) {
    currentOffset += value;
}

void LayoutBuilder::resetOffset() {
    currentOffset = 0;
}

void LayoutBuilder::changeState(std::unique_ptr<LayoutBuilderState> newState) {
    state = std::move(newState);
}

bool LayoutBuilder::canEmit() {
    return !lexemsToEmit.empty();
}

Lexem LayoutBuilder::emitLexem() {
    if (!lexemsToEmit.empty()) {
        Lexem emitted = lexemsToEmit.front();
        lexemsToEmit.pop();
        return emitted;
    }
    return Lexem::NONE;
}
