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
        : type(-1), repr(""), column(-1), line(-1) {}

    IndentedToken(int type, int column)
        : type(type), repr(""), column(column), line(-1) {}

    IndentedToken(int type, const std::string& repr, int column)
        : type(type), repr(repr), column(column), line(-1) {}

    IndentedToken(int type, const std::string& repr, int column, int line)
        : type(type), repr(repr), column(column), line(line) {}

    std::string toString() const {
        return "type: " + std::to_string(type) + ", repr: " + repr + ", column: " + std::to_string(column);
    }

    int type;
    std::string repr;
    int column;
    int line;
};
