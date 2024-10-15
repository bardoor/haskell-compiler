// FlexUtils.h
#pragma once

#include <stack>
#include <queue>
#include <string>
#include <memory>
#include <stdexcept>

enum class Lexem {
    OPEN_BRACE, 
    CLOSING_BRACE,
    SEMICOLON,
    NONE
};

class LayoutBuilder;

class LayoutBuilderState {
protected:
    LayoutBuilder* owner;
    const unsigned TAB_SIZE = 4;
    bool needAddLexem = false;

public:
    LayoutBuilderState(LayoutBuilder* stateOwner);
    virtual void addLexem(const std::string& lexem) = 0;
    bool needToAddLexem() { return needAddLexem; }
    virtual ~LayoutBuilderState();
};

class NewLineState : public LayoutBuilderState {
public:
    NewLineState(LayoutBuilder* owner);
    NewLineState(LayoutBuilder* owner, const std::string& lexem);
    virtual void addLexem(const std::string& lexem) override;
};

class ZeroLayoutState : public LayoutBuilderState {
public:
    ZeroLayoutState(LayoutBuilder* owner);
    virtual void addLexem(const std::string& lexem) override;
};

class StartLayoutState : public LayoutBuilderState {
private:
    bool bracketExplicit = false;

public:
    StartLayoutState(LayoutBuilder* owner, bool bracketIsExplicit);
    StartLayoutState(LayoutBuilder* owner, bool bracketIsExplicit, const std::string& lexem);
    virtual void addLexem(const std::string& lexem) override;
};

class LeadingLexemState : public LayoutBuilderState {
public:
    LeadingLexemState(LayoutBuilder* owner, const std::string& lexem);
    virtual void addLexem(const std::string& lexem) override;
};

class MiddlePositionState : public LayoutBuilderState {
public:
    MiddlePositionState(LayoutBuilder* owner);
    MiddlePositionState(LayoutBuilder* owner, const std::string& lexem);
    virtual void addLexem(const std::string& lexem) override;
};

class LayoutBuilder {
private:
    std::stack<int> offsetStack;
    std::queue<Lexem> lexemsToEmit;
    std::unique_ptr<LayoutBuilderState> state;
    unsigned currentOffset = 0;
    bool rememberNextOffset;
    bool n;

public:
    LayoutBuilder();
    void newLine();
    void addLexem(const std::string& lexem);

    /** 
     * Функция получения логической разности индентации
     * @return 0 если последняя индентация в стеке совпадает с текущей, 
     *         1 если текущая индентация больше, 
     *        -1 если текущая индентация меньше
    */
    int offsetDifference();
    
    bool topOffsetIsZero() const;
    bool canEmit();

    void pushOffsetZero();
    void pushCurrentOffset();
    void popOffset();
    void pushLexem(Lexem lexem);
    void addOffset(int value);
    void resetOffset();
    void changeState(std::unique_ptr<LayoutBuilderState> newState);
    Lexem emitLexem();
};
