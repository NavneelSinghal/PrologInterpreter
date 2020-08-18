h(X).
g(X) :- h(X).
f(X) :- g(X), i(X).
i(a(X)).
i(b(X)) :- g(X).
