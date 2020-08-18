exception Impossible;;

type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree * int;;

let height t = match t with 
			|	Leaf -> 0
			|	Node (_, _, _, h) -> h;;

let make_node left data right = Node (left, data, right, 1 + max (height left) (height right));;

(*comp a b should return -1 if a < b, 0 if a = b and 1 otherwise*)

(*finds the data n in a tree t with the comparator function comp*)
let rec find t n comp = match t with 
			|	Leaf -> false
			|	Node (left, data, right, _)  -> 
                let res = comp n data in
				    if res < 0 then find left n comp
				    else if res = 0 then true
				    else find right n comp;;


let rec find_element t n comp = match t with
            |   Leaf -> raise Impossible
            |   Node (left, data, right, _) ->
                let res = comp n data in
                    if res < 0 then find_element left n comp
                    else if res = 0 then data
                    else find_element right n comp;;

(*right-rotates the tree*)
let rotate_right node = match node with 
			|	Node (Node (l1, d1, r1, _), d2, r2, _) ->
				make_node l1 d1 (make_node r1 d2 r2)
			|	_ -> raise Impossible;;

(*left-rotates the tree*)
let rotate_left node = match node with 
			|	Node (l2, d2, Node (l1, d1, r1, _), _) ->
				make_node (make_node l2 d2 l1) d1 r1
			|	_ -> raise Impossible;;

(*t is the tree, x is the data, comp is the comparator function*)
let rec insert t x comp = match t with
			|	Leaf -> Node (Leaf, x, Leaf, 1)
			|	Node (left, data, right, h) ->
                let res = (comp x data) in
				if(res = 0) then t
				else if (res < 0) then 
					let newnode = insert left x comp in
						match newnode with 
						|	Leaf -> raise Impossible
						|	Node (left1, data1, right1, height1) ->
							if height1 - (height right) <= 1 then
								make_node newnode data right
							else
								let left2 = if height left1 < height right1 then rotate_left newnode else newnode
								in rotate_right (make_node left2 data right)
				else
					let newnode = insert right x comp in
						match newnode with
						|	Leaf -> raise Impossible
						|	Node (left1, data1, right1, height1) ->
							if height1 - (height left) <= 1 then
								make_node left data newnode
							else
								let right2 = if height right1 < height left1 then rotate_right newnode else newnode
								in rotate_left (make_node left data right2);;
(*finds the root of the tree*)
let rec data_at_node t = match t with 
				|	Leaf -> raise Impossible
				|	Node (left, data, right, height) -> data;;

let list_to_tree l comp = List.fold_left (fun t x -> (insert t x comp)) Leaf l;;

let rec tree_to_list t = (*pre-order list of a tree*)
  match t with
    | Leaf -> []
    | Node (left, data, right, h) -> 
        (tree_to_list left) @ (data :: (tree_to_list right));;

let rec default_comp x y = if x < y then -1 else if x = y then 0 else 1;;

let range n = let rec range_ n_ acc = if n_ = 0 then acc else range_ (n_ - 1) (n_ :: acc) in range_ n [];;

(*prints the tree - only for strings*)
(*
let rec print_tree t = match t with 
					|	Leaf -> Printf.printf "Leaf"
					|	Node (Leaf, data, Leaf, _) -> (Printf.printf "%s -> Leaf, Leaf\n" data)
					|	Node (left, data, Leaf, _) -> (Printf.printf "%s -> %s, Leaf\n" data (data_at_node left); print_tree left)
					|	Node (Leaf, data, right, _) -> (Printf.printf "%s -> Leaf, %s\n" data (data_at_node right); print_tree right)
					|	Node (left, data, right, _) -> (Printf.printf "%s -> %s, %s\n" data (data_at_node left) (data_at_node right); print_tree left; print_tree right);;
					
let rec range n = if n = 0 then [] else n :: range (n-1);;

let t = Leaf;;

print_tree (insert t "Hello");;
print_tree (List.fold_left insert t (range 30));;

let rec checkbalance t = 
  match t with 
    | Leaf -> true
    | Node(left, data, right, h) -> 
      if ((height left) - (height right) <= 1 && (height left) - (height right) >= -1) then 
        (checkbalance left) && (checkbalance right) 
      else false;;

let rec pre_order_print t = 
  match t with 
    | Leaf -> Printf.printf ""
    | Node (left, data, right, h) -> (Printf.printf "%s " data); pre_order_print left; pre_order_print right;;


list_tree (List.fold_left insert t (range 30)) [];;

let comp i j = 
  if i = j then 0 
  else if i < j then -1 
  else 1;;

List.sort comp (list_tree (List.fold_left insert t (range 30)) []);;
*)
