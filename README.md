#Assignment 6
[comment]: <> (run make doc to generate a pdf of this file)

##Assignment specifications:

In this assignment, you will write a simplified version of a Logic Programming interpreter in OCaml.
You will first define an ML data type to represent the structure of a legitimate LogPro program.
    
* A program is a set (list) of clauses. 
* A clause can either be a fact or a rule. A fact has a head but no body.  A rule has a head and a body.  
* The head is a single atomic formula.  A body is a sequence of atomic formulas.
* An atomic formula is a k-ary predicate symbol followed by k terms.
* A term is either a variable, a constant, or a k-ary function symbol with k sub-terms.
* A goal is a set (list) of atomic formulas.

You need to take your implementation of unification to use as the parameter-passing mechanism. (Note: by pretending the predicate symbol is a function symbol, you can perform resolution of goals and program clauses).
You also need to develop a back-tracking strategy to explore the resolution search space.   You need to be able to replace a goal by subgoals, as found by applying a unifier to the body of a program clause whose head unified with the chosen subgoal.

##How to run the code:
Running make creates an executable called main. To run this, suppose x is the name of the database file for the logpro program. Then we need to run ./main x (i.e. pass x as a command line argument to main). The database gets displayed, and an interpreter shows up, which takes goals and finds the corresponding solutions to the goals, in a format similar to that of prolog (some examples have been given in the tests directory). To signal the end of the program, we need to pass a goal called exit.
Either we can use the interpreter, or pass the program file p as ./main x < p instead (remember to have exit. at the end of p). This runs the file as if all the instructions were run one by one on the interpreter. 
To run on the test cases in the tests directory, simply running make test should give the results of the run.

##Test cases:
There are 5 test cases that are put up as examples in the tests directory. The descriptions are as follows:

1. boolean.pl: This test case gives a simple implementation of a boolean calculator that can find and, or, not, xor, xnor. Sample test cases are in boolean\_tests.pl.
2. common\_ancestor.pl: This test case considers a rooted tree and finds the common ancestors of two nodes etc. Sample test cases are in common\_ancestor\_tests.pl.
3. db1.pl: This test case is a very simple test case. Sample test cases are in db1\_tests.pl.
4. nat.pl: This test case implements the data type nat (as done in class) and the relations add and greater than. It turns out that we can do some elementary mathematics (inequality/equation solving in particular) with this, and examples are given in nat\_tests.pl, where the first test case checks the validity of a numeral, the second test case solves the inequality 2Y < 5, and the third test case solves the system X < 9, X = 2W, X = 3Z.
5. sorting\_hat.pl: This test case implements a decision making mechanism for sorting students into houses in the Harry Potter universe. Sorting results can be found by doing instructions as in sorting\_hat\_tests.pl.
6. dbhazards.pl: This test case has a test case that can possibly have an issue with implementations which don't mark the table variables with the branch they take. However since my implementation always marks the variables, this case works. The tests are as in dbhazards\_tests.pl.

##Implementation details:

1. sig.ml:
This has been inherited from the previous assignment submission. However a few printing functions (including those which clean up variable names in the substitutions) have been added, apart from the logpro support. Functions used in solving for goals are as follows:
    i. prepend\_vars\_term: This prepends every variable in a term with an \_ and the number of times we have renamed the table each time we go to a new recursion depth.
    ii. prepend\_vars\_: This prepends every variable in a clause with an \_ and the number of times we have renamed the table. (this function is necessary because we need to keep a track of the recursion depth and ensure we don't have scope issues due to clashes of variable names. note that scope issues don't arise because the numbers separated by \_ show the dfs path that we take in the graph that is formed by the edges being transfer of control between functions and the vertices being the list of all clauses, and this makes the graph a tree with n children of each node, where n is the number of clauses in our table)
    iii. restrict\_substitution: Although this function hasn't been used anywhere, we can use this function to restrict a substitution to only the variables of a certain term.
    iv. check\_depth\_le: As it will turn out, the substring before a variable name is in the form \_$n_1$\_$n_2$\_$n_3$...\_$n_k$ where $n_i$'s are numbers. This function acts as a filter to remove variables with depth > d if d = 0 and do nothing otherwise.
    v. filter\_substitution: This function does a filter as described above.
    vi. solve\_goal: This function is at the heart of the whole code. The explanation is as given in the comment in the code.
    vii. solve\_goal\_list: This function solves a single goal (and is a wrapper function for the previous function).
    viii. solve\_goal\_multiple\_: This function solves a list of goals and returns a substitution
    ix. solve\_goal\_multiple: This function prints the aforementioned substitution list.
    x. solve\_multiple\_goals: This function solves multiple lists of goals together.

2. logpro.ml:
This is the top-level code that takes in input and calls the parser. Firstly we find the database and then we put the user into an infinite loop which works as the interpreter.

3. lexer.mll, parser.mly:
These are the lexer and the parser associated with creating the database.

4. lexer1.mll, parser1.mly:
These are those associated with solving the queries.
