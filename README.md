# haskell-compiler
![](https://github.com/bardoor/haskell-compiler/blob/main/haskell.gif)

## Как запустить?
### Для windows:
1. Скачать [msys2](https://www.msys2.org/)
2. Скачать [python](https://www.python.org/downloads/)
3. Далее в консоли msys2:
     ```bash
     pacman -S mingw-w64-x86_64-toolchain make bison flex
     ```
4. Добавить в PATH путь к mingw64\bin в папке msys2, по умолчанию - ``` C:\msys64\mingw64\bin ```
5. Добавить в PATH путь к usr\bin в папке msys2, по умолчанию - ``` C:\msys64\usr\bin ``` 
6. Открываем (перезапускаем) свой любимый терминал:
    ```bash
    git clone https://github.com/bardoor/haskell-compiler.git
    cd haskell-compiler
    make
    ```
### Для Linux:
1. Всё тоже самое только без msys2...
