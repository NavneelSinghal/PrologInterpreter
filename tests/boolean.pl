and(0, 0, 0).
and(1, 0, 0).
and(0, 1, 0).
and(1, 1, 1).
or(0, 0, 0).
or(1, 0, 1).
or(0, 1, 1).
or(1, 1, 1).
not(0, 1).
not(1, 0).
xor(A, B, C) :- not(B, D), not(A, E), and(A, D, F), and(B, E, G), or(F, G, C).
xnor(A, B, C) :- xor(A, B, D), not(C, D).
