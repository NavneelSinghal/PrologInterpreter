%{
    open Sig
    exception Eof
%}

%token <string> VARIABLE
%token <string> FC /* function or constant */
%token CONDITION COMMA LPAREN RPAREN EOL EOF

%start line

%type <Sig.term list> line

%%

line:
    | terms EOL                 {$1}
    | EOF                       {[Node(("_end", 0), [])]}
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
