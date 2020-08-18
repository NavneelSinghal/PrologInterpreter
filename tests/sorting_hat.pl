brave(harry).
loyal(harry).
loyal(cedric).
loyal(luna).
fair(harry).
fair(hermione).
patient(cedric).
clever(cedric).
clever(hermione).
curious(luna).
friend(harry,hermione).
friend(harry,ron).
enemy(harry,malfoy).
belongToGryffindor(X):-brave(X), loyal(X).
belongToGryffindor(X):-friend(harry,X).
belongToHufflepuff(X):-patient(X), loyal(X).
belongToRavenclaw(X):-curious(X).
belongToSlytherin(X):-enemy(harry,X).
