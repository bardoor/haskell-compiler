# haskell-compiler


## Как собрать?
```bash
echo "// empty" >> flex/src/haskell.flex.cpp
```
Debug:
```bash
mkdir debug
cd debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
```

Release:
```bash
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
```


В VSC: 
```
Ctrl(Cmd) + Shift + P ->
    CMake: Select Active Folder ->
        выбрать корень репозитория
``` 

