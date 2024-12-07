#pragma once

#include <string>

class Token {
public:
    Token(int id, std::string value) : id(id), value(value) {}
    Token(int id) : id(id), value("") {}

    int id;
    std::string value;
};
