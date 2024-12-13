#pragma once

#include <string>
#include <exception>
#include <format>


class LexerError : public std::exception {
public:
	explicit LexerError(const std::string& msg) : message(msg) {}

	explicit LexerError(const std::string& msg, int line, int col) {
		this->line = line;
		this->col = col;
		message = std::format("error {}:{}: {}", line, col, msg);
	}

	const char *what() const noexcept override {
		return message.c_str();
	}

	int getLine() const noexcept {
		return line;
	}

	int getColumn() const noexcept {
		return col;
	}

private:
	std::string message;
	int line = -1;
	int col = -1;
};