#pragma once

#include <string>

/**
 * Токен, который содержит: 
 *      1. Индентификатор
 *      2. Строковое семантическое значение (при наличии)
 *      3. Отступ от начала строки
 */
struct IndentedToken {
    IndentedToken() 
        : type(-1), repr(""), offset(-1) {}

    IndentedToken(int type, int offset)
        : type(type), repr(""), offset(offset) {}

    IndentedToken(int type, const std::string& repr, int offset)
        : type(type), repr(repr), offset(offset) {}

    std::string toString() const {
        return "type: " + std::to_string(type) + ", repr: " + repr + ", offset: " + std::to_string(offset);
    }

    int type;
    std::string repr;
    int offset;
};
