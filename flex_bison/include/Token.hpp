#pragma once

#include <string>

/**
 * Токен, который содержит индентификатор, строковое семантическое значение (при наличии) и отступ от начала строки
 */
struct IndentedToken {
    IndentedToken() 
        : type(-1), value(""), offset(-1) {}

    IndentedToken(int type, int offset)
        : type(type), value(""), offset(offset) {}

    IndentedToken(int type, const std::string& value, int offset)
        : type(type), value(value), offset(offset) {}

    std::string toString() const {
        return "type: " + std::to_string(type) + ", value: " + value + ", offset: " + std::to_string(offset);
    }

    int type;
    std::string value;
    int offset;
};