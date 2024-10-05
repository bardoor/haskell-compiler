for_stmt : FOR'('type ID '=' expr ';' exprE ';' exprE ')' stmt
         | FOR '(' exprE ';' exprE ';' exprE')' stmt
         ;

exprE : expr
      | /* empty */
      ;

exprList : expr
         | exprList ',' expr 
         ;

exprListE : exprList
          | /* empty */
          ;

%right UMINUS
expr : ID
     | literal
     | expr '+' expr
     | expr '-' expr
     | '-' expr %prec UMINUS
     | expr '==' expr
     | expr '=' expr
     | '(' expr ')'
     | expr '[' expr ']'
     | expr '?' expr ':' expr
     | expr '.' ID
     | ID '(' exprListE ')'
     ;

/* Правильное решение */
type : INTK /* int keyword */
     | CHARK
     | ID
     | type '*'
     ;

funcHeader : type ID '(' paramListE ')' stmt
           | VOIDK ID '(' paramListE ')' stmt

/* Неправильное решение */
type : INTK /* int keyword */
     | CHARK
     | VOIDK
     | ID
     | type '*'
     ;

nonVoidType : INTK
            | CHARK
            | ID
            | type '*'
            ;

varDecl : nonVoidType ID
        ;

funcHeader : type ID '(' paramListE ')' stmt
           ;

param : nonVoidType ID
      ;

paramList : paramList ',' param
          | param
          ;

paramListE : paramList
           | /* empty */
           ;