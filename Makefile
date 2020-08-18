all:
	@ocamlc -c avltree.ml
	@ocamlc -c sig.ml
	@ocamlyacc parser.mly
	@ocamlc -c parser.mli
	@ocamlc -c parser.ml
	@ocamlyacc parser1.mly
	@ocamlc -c parser1.mli
	@ocamlc -c parser1.ml
	@ocamllex lexer.mll
	@ocamlc -c lexer.ml
	@ocamllex lexer1.mll
	@ocamlc -c lexer1.ml
	@ocamlc -c logpro.ml
	@ocamlc -o main avltree.cmo sig.cmo parser.cmo lexer.cmo parser1.cmo lexer1.cmo logpro.cmo
	@rm *.cmi
	@rm *.cmo
	@rm parser.ml
	@rm parser.mli
	@rm lexer.ml
	@rm parser1.ml
	@rm parser1.mli
	@rm lexer1.ml
test:
	./main tests/boolean.pl < tests/boolean_tests.pl
	./main tests/common_ancestor.pl < tests/common_ancestor_tests.pl
	./main tests/db1.pl < tests/db1_tests.pl
	./main tests/dbhazards.pl < tests/dbhazards_tests.pl
	./main tests/nat.pl < tests/nat_tests.pl
	./main tests/sorting_hat.pl < tests/sorting_hat_tests.pl
doc:
	@pandoc -V geometry:margin=1in README.md -o README.pdf
cleandoc:
	@rm README.pdf
clean:
	@rm main
