{
    open Parser1
}

let permissible_chars = ['A'-'Z' 'a'-'z' '0'-'9' ''' '_']

rule token = parse
    | ['A'-'Z'] permissible_chars* as x {VARIABLE(x)}
    | ['a'-'z' '0'-'9'] permissible_chars* as x {FC(x)}
    | ":-"                              {CONDITION}
    | ','                               {COMMA}
    | '('                               {LPAREN}
    | ')'                               {RPAREN}
    | '.'                               {EOL}
    | [' ' '\n' '\t']                   {token lexbuf}
    | eof                               {EOF}
