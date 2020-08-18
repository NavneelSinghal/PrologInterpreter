parent(1, 2).
parent(1, 3).
parent(2, 9).
parent(2, 7).
parent(9, 10).
parent(10, 11).
parent(10, 12).
parent(2, 14).
parent(7, 8).
parent(7, 5).
parent(5, 4).
parent(5, 6).
parent(5, 13).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
ca(X, Y, X) :- ancestor(X, Y).
ca(Y, X, X) :- ancestor(X, Y).
ca(X, Y, Z) :- ancestor(Z, X), ancestor(Z, Y).
exit.
