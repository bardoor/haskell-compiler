CXX = g++
CXXFLAGS = -std=c++20 -Iflex_bison/include -g

OBJ_DIR = build
BIN_DIR = bin

SRC = $(wildcard flex_bison/src/*.cpp) $(wildcard flex_bison/resources/*.cpp)
OBJ = $(patsubst flex_bison/src/%.cpp, $(OBJ_DIR)/%.o, $(SRC))

TARGET = $(BIN_DIR)/haskellc.exe

all: generate_bison generate_flexer $(TARGET)

generate_flexer:
	flex --outfile=flex_bison/src/haskell.flex.cpp flex_bison/resources/hslexer.flex

generate_bison:
	bison -d -o flex_bison/src/Parser.cpp flex_bison/resources/hsparser.y
	@mv flex_bison/src/Parser.hpp flex_bison/include/Parser.hpp

generate_bison_debug:
	bison -Wcounterexamples -graph -d -o flex_bison/src/Parser.cpp flex_bison/resources/hsparser.y
	@mv flex_bison/src/Parser.hpp flex_bison/include/Parser.hpp

test_parser: 
	pytest flex_bison/tests/test_all.py

$(TARGET): $(OBJ)
	$(CXX) -o $@ $^

$(OBJ_DIR)/%.o: flex_bison/src/%.cpp
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
