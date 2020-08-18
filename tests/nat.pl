numeral(0).
numeral(succ(X)) :- numeral(X).
gt(succ(X), 0).
gt(succ(X), succ(Y)) :- gt(X, Y).
add(0, Y, Y).
add(succ(X), Y, succ(Z)) :- add(X, Y, Z).
