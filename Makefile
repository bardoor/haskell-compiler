CXX = g++
CXXFLAGS = -std=c++20 -Iflex_bison/include -Wall -g

OBJ_DIR = build
BIN_DIR = bin

SRC = $(wildcard flex_bison/src/*.cpp) $(wildcard flex_bison/resources/*.cpp)
OBJ = $(patsubst flex_bison/src/%.cpp, $(OBJ_DIR)/%.o, $(SRC))

TARGET = $(BIN_DIR)/main.exe

all: generate_bison generate_flexer $(TARGET)

generate_flexer:
	flex --outfile=flex_bison/src/haskell.flex.cpp flex_bison/resources/haskell.flex

generate_bison:
	bison -Wcounterexamples -d -o flex_bison/src/Parser.cpp flex_bison/resources/parser.y
	@mv flex_bison/src/Parser.hpp flex_bison/include/Parser.hpp

$(TARGET): $(OBJ)
	$(CXX) -o $@ $^

$(OBJ_DIR)/%.o: flex_bison/src/%.cpp
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
