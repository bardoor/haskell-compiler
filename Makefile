CXX = g++
CXXFLAGS = -std=c++20 -Iflex_bison/include -g

OBJ_DIR = build
BIN_DIR = bin

SRC = $(wildcard flex_bison/src/*.cpp) $(wildcard flex_bison/resources/*.cpp)
OBJ = $(patsubst flex_bison/src/%.cpp, $(OBJ_DIR)/%.o, $(SRC)) $(OBJ_DIR)/haskell.flex.o $(OBJ_DIR)/Parser.o

TARGET = $(BIN_DIR)/haskellc.exe

all: clean generate_bison generate_flexer $(TARGET)

generate_flexer:
	flex --outfile=flex_bison/src/haskell.flex.cpp flex_bison/resources/hslexer.flex
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c flex_bison/src/haskell.flex.cpp -o $(OBJ_DIR)/haskell.flex.o

generate_bison:
	bison -d -o flex_bison/src/Parser.cpp flex_bison/resources/hsparser.y
	@mv flex_bison/src/Parser.hpp flex_bison/include/Parser.hpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c flex_bison/src/Parser.cpp -o $(OBJ_DIR)/Parser.o

generate_bison_debug:
	bison -Wcounterexamples --graph -d -o flex_bison/src/Parser.cpp flex_bison/resources/hsparser.y
	@mv flex_bison/src/Parser.hpp flex_bison/include/Parser.hpp

test_parser: 
	pytest flex_bison/tests/test_all.py

$(TARGET): $(OBJ)
	$(CXX) -o $@ $^

$(OBJ_DIR)/%.o: flex_bison/src/%.cpp
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: all
	$(TARGET)

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
	rm -f flex_bison/src/haskell.flex.cpp flex_bison/src/Parser.cpp
	rm -f flex_bison/include/Parser.hpp
