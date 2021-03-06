#lang racket

(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre)
         parser-tools/yacc)

(require (except-in eopl #%module-begin))

(define lexer_compiler
  (lexer
   ["+" (token-plus)]
   ["-" (token-minus)]
   ["*" (token-multiply)]
   ["/" (token-division)]
   ["=" (token-assign)]
   ["==" (token-equal)]
   [">" (token-greater)]
   ["<" (token-less)]
   ["!=" (token-not-eq)]
   [";" (token-semicolon)]
   [":" (token-colon)]
   ["," (token-comma)]
   ["[" (token-lbracket)]
   ["]" (token-rbracket)]
   ["(" (token-lpar)]
   [")" (token-rpar)]
   ["{" (token-lcurly)]
   ["}" (token-rcurly)]
   ["return" (token-return)]
   ["while" (token-while)]
   ["do" (token-dowhile)]
   ["end" (token-end)]
   ["if" (token-if)]
   ["then" (token-then)]
   ["else" (token-else)]
   ["null" (token-null null)]
   ["print" (token-print)]
   ["switch" (token-switch)]
   ["case" (token-case)]
   ["default" (token-default)]
   ["begin" (token-begin)]
   [(:or "true" "false") (token-bool (if (equal? lexeme "true") #t #f))]
   [(:+ (:or (char-range #\a #\z) (char-range #\A #\Z))) (token-var lexeme)]
   [(:or (:+ (char-range #\0 #\9)) (:: (:+ (char-range #\0 #\9)) #\. (:+ (char-range #\0 #\9)))) (token-num (string->number lexeme))]
   [(:: "\"" (complement (:: any-string "\"" any-string)) "\"") (token-string (substring lexeme 1 (- (string-length lexeme) 1)))]
   [whitespace (lexer_compiler input-port)]
   [(eof) (token-eof)]
   [(:+ (:or "@" "!" "#" "%" "^" "&" "~" "{" "}")) (eopl:error (string-append lexeme " is unknown!"))]
  
   ))

(define-tokens a (num string bool var null))
(define-empty-tokens b (eof plus minus multiply division equal assign not-eq greater less semicolon comma lbracket rbracket lpar rpar lcurly rcurly return while dowhile end if then else print switch case default begin colon))

(define (error-thrower name value)
  (if (equal? value #f)
      (let ((sym (cond
                   [(equal? name 'eof) "end of file"]
                   [(equal? name 'plus) "+"]
                   [(equal? name 'minus) "-"]
                   [(equal? name 'multiply) "*"]
                   [(equal? name 'division) "/"]
                   [(equal? name 'assign) "="]
                   [(equal? name 'equal) "=="]
                   [(equal? name 'not-eq) "!="]
                   [(equal? name 'greater) ">"]
                   [(equal? name 'less) "<"]
                   [(equal? name 'lpar) "("]
                   [(equal? name 'rpar) ")"]
                   [(equal? name 'lbracket) "["]
                   [(equal? name 'rbracket) "]"]
                   [(equal? name 'lcurly) "{"]
                   [(equal? name 'rcurly) "}"]
                   [(equal? name 'colon) ":"]
                   [(equal? name 'comma) ","]
                   [(equal? name 'semicolon) ";"]
                   [(equal? name 'return) "return"]
                   [(equal? name 'while) "while"]
                   [(equal? name 'dowhile) "do"]
                   [(equal? name 'end) "end"]
                   [(equal? name 'if) "if"]
                   [(equal? name 'then) "then"]
                   [(equal? name 'else) "else"]
                   [(equal? name 'switch) "switch"]
                   [(equal? name 'begin) "begin"]
                   [(equal? name 'case) "case"]
                   [(equal? name 'default) "default"]
                   [(equal? name 'print) "print"]
                   )))
                 
                  

        (eopl:error (string-append "syntax error near " sym)))
      (cond
        [(number? value) (eopl:error (string-append "syntax error near " (number->string value)))]
        [(equal? name 'VAR) (eopl:error (string-append value " is not defined as a syntax token"))]
        [(equal? name 'NULL) (eopl:error "syntax error near null")]
        [(string? value) (eopl:error (string-append "syntax error near " value))]
        [(boolean? value) (if value (eopl:error (string-append "syntax error near " "true")) (eopl:error (string-append "syntax error near " "false")))]
        )
  ))

(define parser_compiler
  (parser
   (start command)
            (end eof)
            (tokens a b)
            (error (lambda (token-ok? token-name token-value)
                     (displayln (error-thrower token-name token-value))

                    ))
            (grammar

             [command ((keyword) (list 'keyword $1)) ((keyword semicolon command) (list 'command $1 $3))]
             
             [keyword
            ((if-statement) (list 'if_statement $1))
            ((while-statement) (list 'while_statement $1))
            ((assignment-statement) (list 'assignment_statement $1))
            ((return-statement) (list 'return_statement $1))
            ((print-statement) (list 'print_statement $1))
            ((switch-statement) (list 'switch_statement $1))
            ]
             
             [if-statement ((if exp then command else command end) (list 'if $2 $4 $6))]

             [while-statement ((while exp dowhile command end) (list 'while $2 $4))]
          
           
             [assignment-statement ((var assign exp) (list 'assign $1 $3))]
           
             [return-statement ((return exp) (list 'return $2))]

             [print-statement ((print exp) (list 'print $2))]

             [switch-statement ((switch exp begin cases default command end) (list 'switch $2 $4 $6))]
           
           [exp
            ((aexp) (list 'aexp $1))
            ((aexp greater aexp) (list 'greater? $1 $3))
            ((aexp less aexp) (list 'less? $1 $3))
            ((aexp equal aexp) (list 'equals? $1 $3))
            ((aexp not-eq aexp) (list 'not-equals? $1 $3))
            ]
           
           [aexp
            ((bexp) (list 'bexp $1))
            ((bexp minus aexp) (list 'subtract $1 $3))
            ((bexp plus aexp) (list 'add $1 $3))
            ]
           
           [bexp
            ((cexp) (list 'cexp $1))
            ((cexp multiply bexp) (list 'mul $1 $3))
            ((cexp division bexp) (list 'div $1 $3))
            ]
      
            [cexp
            ((minus cexp) (list 'minus $2))
            ((lpar exp rpar) (list 'par-exp $2))
            ((num) (list 'number $1))
            ((null) (list 'null $1))
            ((bool) (list 'bool $1))
            ((string) (list 'string $1))
            ((var) (list 'var $1))
            ((list) (list 'list $1))
            ((var listMember) (list 'element-of-list $1 $2))
            ]
            
            [list
             ((lbracket listValues rbracket) (list 'list-values $2))
             ((lbracket rbracket) (list 'empty-list))
             ]
            
            [listValues
             ((exp) (list 'list-val $1))
             ((exp comma listValues) (list 'list-vals $1 $3))
             ]

            [listMember
             ((lbracket exp rbracket) (list 'list-member $2))
             ((lbracket exp rbracket listMember) (list 'list-members $2 $4))
             ]

            [cases
             ((case exp colon command) (list 'single-case $2 $4))
             ((case exp colon command cases) (list 'multi-case $2 $4 $5))
             ]
             )))


(define lex-this (lambda (lexer input) (lambda () (lexer input))))
(define lexing (lex-this lexer_compiler (open-input-string "a = 3; b = [2, 3, 4]; return a + b; if a == b then a = 1; b = 0 else a = b[5] end")))

;(let ((parser-res (parser_compiler lexing))) parser-res)
(provide (all-defined-out))