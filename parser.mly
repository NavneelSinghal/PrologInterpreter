%{
    open Sig
    exception Eof
%}

%token <string> VARIABLE
%token <string> FC /* function or constant */
%token CONDITION COMMA LPAREN RPAREN EOL EOF

%start line

%type <Sig.clause> line

%%

line:
    | clause_line EOL           {$1}
    | EOF                       {(Node(("_end", 0), []), [])}
    ;

clause_line:
    | head                      {($1, [])} /*represented as a pair of head and body*/
    | head CONDITION body       {($1, $3)}
    ;

head:
    | FC                        {Node(($1, 0), [])} /*this is a fact without args*/
    | FC LPAREN terms RPAREN    {Node(($1, (List.length $3)), $3)} /*this is a clause with args*/
    ;

body:
    | head                      {[$1]}
    | head COMMA body           {$1 :: $3}
    ;

one_term:
    | FC                        {Node(($1, 0), [])} /*constant*/
    | FC LPAREN terms RPAREN    {Node(($1, (List.length $3)), $3)} /*function*/
    | VARIABLE                  {V($1)}
    ;

terms:
    | one_term                  {[$1]}
    | one_term COMMA terms      {$1 :: $3}
    ;
