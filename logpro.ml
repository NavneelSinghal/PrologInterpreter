open Sig

(*database*)

let _u = Printf.printf "Database:\n\n"
let _u = flush stdout

let get_database filename = 
    let file = open_in filename 
    in
    let lexbuf = Lexing.from_channel file 
    in 
    let rec work acc = 
        match (Parser.line Lexer.token lexbuf) with
        | (Node(("_end", 0), []), []) -> acc
        | x -> (print_clause x; (work (x :: acc)))
    in 
    (List.rev (work []))


let database = prepend_vars_ (get_database Sys.argv.(1))

let _u = flush stdout
let _u = Printf.printf "\nQueries:\n\n"

(*let __v = List.map print_clause database
*)

(*repl loop*)

let _ = 
    let lexbuf = Lexing.from_channel stdin
    in
    while true do
        Printf.printf "?- "; flush stdout;
        let goal = Parser1.line Lexer1.token lexbuf 
        in
        match goal with 
        | [Node(("exit", 0), [])] -> (Printf.printf "Exiting safely\n\n"; exit 0)
        | y -> (solve_goal_multiple y database)
    done
