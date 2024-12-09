#pragma once

#include <string>
#include <exception>


class LexerError : public std::exception {
private:
	std::string message;

public:
	explicit LexerError(const std::string &msg) : message(msg) {}
	const char *what() const noexcept override {
		return message.c_str();
	}
};