open List
open Avltree

(*#use "avltree.ml";;
*)
exception Not_found
exception NOT_UNIFIABLE

type variable = string;; (*name*)
type symbol = string * int;; (*name, arity*) (*TODO: check if this is okay*)
type term = V of variable | Node of symbol * (term list);;
type substitution = (variable * term) tree;;
type clause = term * (term list);;

let global_state = ref 0;;


(*-----------------sorted list functions--------------------*)

let rec list_diff l1 l2 comp = (*finds l1 \ l2 using comparator function comp*) 
    match (l1, l2) with
    | (_, []) -> l1
    | ([], _) -> []
    | (x :: xs, y :: ys) -> 
            let res = comp x y in
            if res = 0 then (list_diff xs ys comp) (*if x and y match, we can remove it*)
            else if res < 0 then x :: (list_diff xs l2 comp) (*if x < y then x can't come in l2, so x must be in the set difference*)
            else list_diff l1 ys comp;; (*if x > y then y can never match any element in l1, so we can simply find l1 \ ys*)

let rec list_union l1 l2 comp = (*finds l1 U l2 using comp as comparator*)
    match (l1, l2) with 
    | ([], _) -> l2
    | (_, []) -> l1
    | (x :: xs, y :: ys) -> 
            let res = comp x y in
            if res = 0 then x :: (list_union xs ys comp)
            else if res < 0 then x :: (list_union xs l2 comp)
            else y :: (list_union l1 ys comp);;


(*-----------comparator functions for symbols (weak and strong)------------*)

let string_comp x y = if x < y then -1 else if x = y then 0 else 1;;

let symbol_comp_weak x y = 
    match (x, y) with 
    | ((s, _), (t, _)) -> string_comp s t;;
(*Note that this function checks only for duplicate names*)

let symbol_comp x y = 
    match (x, y) with 
    | ((s, a), (t, b)) -> 
            let w = string_comp s t in 
                if w = 0 then if a < b then -1 else if a = b then 0 else 1
                else w;;
(*this strictly checks for equality*)



(*--------------------------signatures and terms--------------------------*)

(*To check if a signature is valid - this function checks if duplicate symbol names exist, and arities are non-negative (also assumes that the same symbol with the same arity can't come twice)*)
let check_sig (signature : symbol list) : bool = 
    let rec check_help (signature_ : symbol list) (found : symbol tree): bool = 
        match signature_ with 
        | [] -> true
        | (sym, ari) :: xs -> 
                if ((not (find found (sym, ari) symbol_comp_weak)) && (ari >= 0)) (*we need to ensure that the symbol names occur once, so we treat multiple instances even with different arity to be the same symbol*) 
                    then check_help xs (insert found (sym, ari) symbol_comp_weak)
                else false
    in
    check_help signature Leaf;;

(*In the case that it is a variable, we need to check if its name clashes with a symbol name, else if it is a symbol, we check if the symbol is there in the signature or not, and the arity matches the number of terms in the corresponding list of the node, and each of the terms in the list must be well-formed*)
let wfterm (preterm : term) (signature : symbol list) = 
    let rec wfterm_ pre_ sig_ =     
        match pre_ with
        
        | V (v) -> not (find sig_ (v, 0) symbol_comp_weak) 
                (*here we check if the variable name clashes with any symbol, so we apply only a string check*)
        
        | Node ((symname, symarity), l) -> 
                (find sig_ (symname, symarity) symbol_comp) && 
                ((List.length l) = symarity) && 
                (List.fold_left (fun x y -> x && y) true (List.rev_map (fun x -> wfterm_ x sig_) l))
                (*however, here we need to check if the (symbol, arity) pair is in the tree or not, i.e., both the symbol name and arity matches or not*)
    in 
    wfterm_ preterm (list_to_tree signature symbol_comp_weak) (*either of the functions could work, since we only need to make a tree of a given valid signature*)
;;

(*To find the height of the preterm*)
let rec ht (preterm : term) = 
    match preterm with
    | V (v) -> 0
    | Node ((sym, ari), l) -> 1 + List.fold_left max 0 (List.rev_map ht l);;

(*To find the size of the preterm*)
let rec size (preterm : term) =
    match preterm with 
    | V (v) -> 1
    | Node ((sym, ari), l) -> 1 + List.fold_left (fun x y -> x + y) 0 (List.rev_map size l);;

(*To find the set of variables in a preterm in sorted order - we can inductively show that the order is sorted*)
let rec vars (preterm : term) =
    match preterm with
    | V (v) -> [v]
    | Node ((sym, ari), l) -> List.fold_left (fun l1 l2 -> list_union l1 l2 string_comp) [] (List.rev_map vars l);;



(*-----------------------substitution helper functions--------------------------*)

let subst_comp ((v1, t1) : (variable * term)) ((v2, t2) : (variable * term)) = 
    string_comp v1 v2;; (*Compares only names*)

(*applies the substitution s1 to term t*)
let rec apply_subst (s1 : substitution) (t : term) = 
    match t with 
    | V(v) -> 
        if(find s1 (v, (V v)) subst_comp) then (*If we have found the variable name in the substitution*) 
            match (find_element s1 (v, (V v)) subst_comp) with
                (_, ret) -> ret (*Return the corresponding term*)
        else V(v) (*Else we can't do anything about it*)
    | Node ((sym, ari), l) -> Node ((sym, ari), (List.rev (List.rev_map (apply_subst s1) l)));;

(*removes redundancies in a list of variable to term mappings by removing those elements which are of the form (v, V v)*)
let remove_redundancies (l : (variable * term) list) : (variable * term) list = 
    let rec help s acc = 
        match s with
        | [] -> acc
        | (v, V w) :: xs -> if v = w then help xs acc else help xs ((List.hd s) :: acc)
        | (v, _) :: xs -> help xs ((List.hd s) :: acc)
    in List.rev (help l []);;

(*finds a composition of the two substitutions s1 and s2*)
let subst_composition (s1 : substitution) (s2 : substitution) : substitution = (*s1 applied, then s2 applied - this is equivalent to 'sprouting' of those variables which are in s1 and union with the elements which are in s2 but not in s1. We assume that both s1 and s2 are valid, and there is no variable whose substitutions have been defined more than once *)
    let (sl1, sl2) = ((tree_to_list s1), (tree_to_list s2))
    in
    list_to_tree (remove_redundancies (list_union (List.rev (List.rev_map (fun (x, t) -> (x, (apply_subst s2 t))) sl1)) (list_diff sl2 sl1 subst_comp) subst_comp)) subst_comp;;

let occurs (v : variable) (t : term) = List.fold_left (fun x y -> x || (y = v)) false (vars t);;

let rec mgu (t1 : term) (t2 : term) : substitution = 
    match (t1, t2) with
    | ((V v1), (V v2)) -> if v1 = v2 then Leaf else (insert Leaf (v1, (V v2)) subst_comp)
    | ((V v), Node(sym, l)) -> if not(List.fold_left (fun x y -> x || (occurs v y)) false l) then insert Leaf (v, Node (sym, l)) subst_comp else raise NOT_UNIFIABLE
    | (Node(sym, l), (V v)) -> if not(List.fold_left (fun x y -> x || (occurs v y)) false l) then insert Leaf (v, Node (sym, l)) subst_comp else raise NOT_UNIFIABLE
    | (Node(sym1, l1), Node(sym2, l2)) -> 
            if not(sym1 = sym2) then raise NOT_UNIFIABLE
            else (List.fold_left2 (fun f t1 t2 -> (subst_composition f (mgu (apply_subst f t1) (apply_subst f t2)))) Leaf l1 l2);;

(*printing functions*)

let print_var v = Printf.printf "%s" v;;

let rec print_term_ t = 
    match t with
    | V v -> print_var v
    | Node ((sname, arity), l) ->
            if(arity = 0) then Printf.printf "%s" sname
            else
                (
                Printf.printf "%s(" sname;
                let rec print_term_list l = 
                    match l with
                    | [] -> Printf.printf ""
                    | [x] -> print_term_ x
                    | x :: xs -> print_term_ x; Printf.printf ", "; print_term_list xs
                in
                print_term_list l;
                Printf.printf ")"
                )
;;

let print_term t = print_term_ t; Printf.printf "\n";;

let rec print_term_list tl = 
    match tl with
    | [] -> Printf.printf ".\n"
    | [x] -> print_term_ x; Printf.printf ".\n"
    | x :: xs -> print_term_ x; Printf.printf ", "; print_term_list xs
;;

let print_clause (c, cl) = 
    if(List.length cl = 0) then (print_term_ c; Printf.printf ".\n") else (print_term_ c; Printf.printf " :- "; print_term_list cl)
;;

let print_one_var_subs (v, t) = 
    print_var v; Printf.printf " -> "; print_term t
;;

let rec print_substitution s = 
    match s with
    | Leaf -> ()
    | Node (left, data, right, _) -> print_substitution left; print_one_var_subs data; print_substitution right
;;  

let check_cap_alpha c = 
    let ascii = int_of_char c in 
    (ascii <= 90) && (ascii >= 65)
;;

let get_rev_prefix s = (*gives prefix and the varname of s*)
    let len = String.length s
    in
    let rec help i acc = 
        if i >= len || (check_cap_alpha s.[i]) then (acc, String.sub s i (len - i))
        else help (i+1) (s.[i] :: acc)
    in
    let rec list_to_string l = 
        match l with (x, str) -> (String.concat "" ((List.rev_map (String.make 1) x)), str)
    in
    list_to_string (help 0 [])
;;

let rec prefixes_of_string_list l = 
    tree_to_list (List.fold_left (fun y x -> match (get_rev_prefix x) with (pre, varname) -> if find y pre default_comp then y else insert y pre default_comp) Leaf l)
;;

let index_in_list a b = 
    let rec help i l =
        match l with 
        | [] -> i
        | x :: xs -> if x = a then i else help (i+1) xs
    in
    help 0 b
;;

let rec replace_in_term t r = 
    match t with 
    | V v -> 
            let (pre, suf) = get_rev_prefix v 
            in
            V ((String.make (1+(index_in_list pre r)) '_') ^ suf)
    | Node (f, ts) -> Node (f, List.map (fun x -> replace_in_term x r) ts)

let rec replace_in_subst s r = 
    match s with 
    | [] -> []
    | (v, t) :: xs -> (v, (replace_in_term t r)) :: (replace_in_subst xs r);;

let rec embellish_substitution s = 
    let w = tree_to_list s 
    in
    let r = List.fold_left (fun x y -> match y with (name, t) -> list_union x (vars t) default_comp) [] w (*this is now a list of all var names in ocaml*)
    in
    let prefix_list = prefixes_of_string_list r
    in
    list_to_tree (replace_in_subst (tree_to_list s) prefix_list) default_comp
;;

let rec print_substitution_list_ l i = 
    match l with
    | [] -> Printf.printf ""
    | x :: xs -> Printf.printf "%d.\n" i; print_substitution (embellish_substitution x); Printf.printf ""; print_substitution_list_ xs (i + 1)
;;

let print_substitution_list l =
    if(List.length l = 0) then Printf.printf "False.\n\n" else
    (print_substitution_list_ l 1; Printf.printf "All solutions done.\n\n")
;;

(*prolog starts*)

let rec prepend_vars_term (t : term) : term = 
    match t with
    | V v -> (V ("_" ^ string_of_int(!global_state) ^ v))
    | Node(x, l) -> Node(x, (List.map prepend_vars_term l))
;;

let rec prepend_vars_ (clause_list : clause list) : (clause list) = 
    match clause_list with 
    | [] -> []
    | (x, l) :: cs -> ((prepend_vars_term x), (List.map prepend_vars_term l)) :: (prepend_vars_ cs)
;;

let rec restrict_substitution (l : variable list) (s : substitution) : substitution = (*this restricts the substitution to variables in l only - suppose this situation arises - substitution has X1 -> X where X1 is not in t, then we need to make sure that this situation doesn't happen*)
    let (v, sl) = ((list_to_tree l default_comp), (tree_to_list s)) in
    list_to_tree (List.filter (fun (varname, varterm) -> (find v varname default_comp) || false) sl) default_comp
;;

let check_depth_le (x : string) (d : int) = (*note that this now works for depth = 1 only, which is nice*)
    if (String.length x <= d) then true 
    else if (String.sub x 0 (d+1)) = (String.make (d+1) '_') then false else true;;

let rec filter_substitution (d : int) (s : substitution) : (substitution) = 
    let w = (tree_to_list s)
    in 
    let rec work l acc = 
        match l with
        | [] -> acc
        | (x, t) :: xs -> 
                if(check_depth_le x d) then work xs ((x, t) :: acc)
                else work xs acc
    in
    list_to_tree (work w []) subst_comp

(*actually need to remove those variables whose first depth + 1 digits are _*)
let rec solve_goal (d : int) (goal : term) (cur_clause_list : clause list) (tot_clause_list : clause list) : (substitution list) = (*v is the list of variables we will restrict the substitution to have, at any given depth d this will contain vars with at most d _'s in the beginning, we need to set v to (vars goal) when we call this function somewhere*)
    match cur_clause_list with
    | [] -> []
    | c :: cs ->
            (*
                Printf.printf "Goal here: "; print_term goal;
                Printf.printf "Clause here: "; print_clause c
            *)
            match c with 
            | (x, pred_list) ->
                    try
                        (*Printf.printf "Finding mgu\n";*)
                        let s = (mgu goal x)
                        in
                        (
                        incr global_state;
                        let new_tot_clause_list = prepend_vars_ tot_clause_list
                        in
                        ((List.rev_map (filter_substitution (d)) (List.fold_left (fun subst_list_ term_ -> (List.fold_left (fun x subst_ -> ((fun t s -> (List.rev_map (subst_composition s) (solve_goal (d+1) (apply_subst s t) new_tot_clause_list new_tot_clause_list))) term_ subst_) @ x ) [] subst_list_)) [s] pred_list))) @ (solve_goal (d) goal cs tot_clause_list))
                        (*
                         * explanation:
                         * what we do is as follows 
                         * for every term, we have a list of possible substitutions (as in the mgu case)
                         * now we for each term, we apply each substitution in the list to it (application is the inside-most function)
                         * then for each such formed term, we solve using the function recursively
                         * then we get a new list of substitutions
                         * this gives us a new substitution list, and we carry on this way for the next term and so on
                         * *)
                    with
                    e -> (*Printf.printf "Unsuccessful with this\n";*) (solve_goal (d) goal cs tot_clause_list)
;;

let maptounit u = ();;

let solve_goal_list goal database = 
    let l = ((solve_goal 0 goal database database))
    in
    (*if (List.length l > 0 && List.hd l = Leaf) then Printf.printf "True.\n"
    else*)
    print_substitution_list l
;;

let rec solve_goal_multiple_ goal database = 
    let s = Leaf
    in
    let tot_clause_list = database 
    in
    let new_tot_clause_list = prepend_vars_ tot_clause_list
    in
    let pred_list = goal 
    in
    ((List.rev_map (filter_substitution (0)) (List.fold_left (fun subst_list_ term_ -> (List.fold_left (fun x subst_ -> ((fun t s -> (List.rev_map (subst_composition s) (solve_goal (1) (apply_subst s t) new_tot_clause_list new_tot_clause_list))) term_ subst_) @ x ) [] subst_list_)) [s] pred_list)))

let rec solve_goal_multiple goal database = 
    (
    Printf.printf "Your query: ";
    print_term_list goal;
    Printf.printf "\n";
    let l = solve_goal_multiple_ goal database in
    print_substitution_list l
    )
;;

let rec solve_multiple_goals l database = 
    match l with 
    | [] -> ()
    | x :: xs -> solve_goal_multiple x database; solve_multiple_goals xs database
;;
