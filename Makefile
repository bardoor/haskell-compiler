CXX = g++
CXXFLAGS = -std=c++20 -Iparser/include -g

OBJ_DIR = build
BIN_DIR = bin

SRC = $(wildcard parser/src/*.cpp) $(wildcard parser/src/**/*.cpp)
OBJ = $(patsubst parser/src/%.cpp, $(OBJ_DIR)/%.o, $(SRC))

TARGET = $(BIN_DIR)/haskellc.exe

all: clean generate_bison generate_flexer $(TARGET)

generate_flexer:
	flex --outfile=parser/src/Flexer.cpp parser/resources/hslexer.flex
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c parser/src/Flexer.cpp -o $(OBJ_DIR)/Flexer.o

generate_bison:
	bison -d -o parser/src/Parser.cpp parser/resources/hsparser.y
	@mv parser/src/Parser.hpp parser/include/Parser.hpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c parser/src/Parser.cpp -o $(OBJ_DIR)/Parser.o

generate_bison_debug:
	bison -Wcounterexamples --graph -d -o parser/src/Parser.cpp parser/resources/hsparser.y
	@mv parser/src/Parser.hpp parser/include/Parser.hpp

test_parser: 
	pytest parser/tests/test_all.py 

$(TARGET): $(OBJ) $(OBJ_DIR)/Flexer.o $(OBJ_DIR)/Parser.o
	$(CXX) -o $@ $^

$(OBJ_DIR)/%.o: parser/src/%.cpp
	@mkdir -p $(dir $@) 
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: all
	$(TARGET)

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
	rm -f parser/src/Flexer.cpp parser/src/Parser.cpp
	rm -f parser/include/Parser.hpp
