#include "LayoutBuild.hpp"

StackStateMachine::StackStateMachine(LayoutBuilder* owner) {
    stateStack.push(std::make_unique<InitBuilderState>(owner));
}

LayoutBuilderState* StackStateMachine::currentState() {
    return stateStack.top().get(); 
}

void StackStateMachine::pop() {
    if (!stateStack.empty()) {
        currentState()->onExit();
        stateStack.pop();
    }
}

void StackStateMachine::popAll() {
    while (!stateStack.empty()) {
        currentState()->onExit();
        stateStack.pop();
    }
}

void StackStateMachine::push(std::unique_ptr<LayoutBuilderState> state) {
    state->onEnter();
    stateStack.push(std::move(state));  
}
